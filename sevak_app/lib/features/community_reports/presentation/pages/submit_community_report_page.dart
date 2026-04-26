import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/services/audio_service.dart';
import '../../../../providers/need_providers.dart';
import '../../domain/usecases/submit_community_report_usecase.dart';

class SubmitCommunityReportPage extends ConsumerStatefulWidget {
  const SubmitCommunityReportPage({super.key});

  @override
  ConsumerState<SubmitCommunityReportPage> createState() => _SubmitCommunityReportPageState();
}

class _SubmitCommunityReportPageState extends ConsumerState<SubmitCommunityReportPage> {
  final _textController = TextEditingController();
  File? _image;
  List<int>? _audioBytes;
  bool _isLoading = false;
  bool _isRecording = false;
  bool _isProcessingVoice = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _toggleRecording() async {
    final audioService = ref.read(audioServiceProvider);
    if (_isRecording) {
      final path = await audioService.stopRecording();
      setState(() {
        _isRecording = false;
        _isProcessingVoice = true;
      });

      if (path != null) {
        try {
          final bytes = await audioService.getAudioBytesAndCleanup(path);
          if (bytes != null) {
            _audioBytes = bytes;
            final ai = ref.read(aiDatasourceProvider);
            debugPrint('Sending ${bytes.length} bytes to AI for transcription...');
            final aiData = await ai.analyzeVoiceNeed(bytes);
            
            if (mounted) {
              setState(() {
                _textController.text = aiData['transcription'] as String? ?? '';
              });
              SnackbarUtils.showSuccess(context, 'AI Dispatcher: Transcript ready ✅');
            }
          }
        } catch (e) {
          debugPrint('Voice analysis failed: $e');
          if (mounted) {
            SnackbarUtils.showError(context, 'AI Dispatcher is busy. Please type the description manually.');
            setState(() {
              _textController.text = 'Voice report (AI Analysis failed)';
            });
          }
        } finally {
          if (mounted) setState(() => _isProcessingVoice = false);
        }
      }
    } else {
      final success = await audioService.startRecording();
      if (success) {
        setState(() => _isRecording = true);
      } else {
        if (mounted) SnackbarUtils.showError(context, 'Microphone permission denied');
      }
    }
  }

  Future<void> _submit() async {
    if (_textController.text.isEmpty && _audioBytes == null) {
      SnackbarUtils.showError(context, 'Please provide text or use voice');
      return;
    }
    setState(() => _isLoading = true);

    double? lat;
    double? lng;

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        debugPrint('Location permission denied');
      } else {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
        );
        lat = position.latitude;
        lng = position.longitude;
      }
    } catch (e) {
      debugPrint('Location error: $e');
    }

    try {
      await ref.read(submitCommunityReportUseCaseProvider).call(
        rawText: _textController.text,
        imageFile: _image,
        audioBytes: _audioBytes,
        lat: lat,
        lng: lng,
      );
      if (mounted) {
        SnackbarUtils.showSuccess(context, 'Report submitted successfully');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, e.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        title: const Text('AI Emergency Dispatch'),
        backgroundColor: AppColors.bgBase,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  const Text(
                    'Quick Voice Report',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Speak in your local language. AI will transcribe and extract details.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: _isProcessingVoice ? null : _toggleRecording,
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: _isRecording ? AppColors.error : AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (_isRecording ? AppColors.error : AppColors.primary).withAlpha(100),
                            blurRadius: 15,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: _isProcessingVoice
                        ? const Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                          )
                        : Icon(
                            _isRecording ? Icons.stop : Icons.mic,
                            color: Colors.white,
                            size: 32,
                          ),
                    ).animate(
                      onPlay: (controller) => _isRecording ? controller.repeat() : controller.stop(),
                    ).scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.1, 1.1),
                      duration: 600.ms,
                      curve: Curves.easeInOut,
                    ).then().scale(
                      begin: const Offset(1.1, 1.1),
                      end: const Offset(1, 1),
                    ),
                  ),
                  if (_isRecording) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'AI is listening...',
                      style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
                    ).animate(onPlay: (c) => c.repeat()).fadeIn().then().fadeOut(),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text('Manual Description', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: 'Describe the emergency...',
                fillColor: AppColors.bgSurface,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 20),
            
            const Text('Photo of Scene', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (_image != null) 
              Stack(
                alignment: Alignment.topRight,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(_image!, height: 180, width: double.infinity, fit: BoxFit.cover),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _image = null),
                    icon: const CircleAvatar(
                      backgroundColor: Colors.black54,
                      child: Icon(Icons.close, color: Colors.white, size: 16),
                    ),
                  ),
                ],
              )
            else
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.add_a_photo_outlined),
                label: const Text('Capture Emergency Photo'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 100),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: const BorderSide(color: AppColors.primary, width: 2, style: BorderStyle.solid),
                ),
              ),
            
            const SizedBox(height: 40),
            SizedBox(
              height: 56,
              child: FilledButton(
                onPressed: _isLoading || _isRecording || _isProcessingVoice ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.error,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text('SUBMIT EMERGENCY', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
