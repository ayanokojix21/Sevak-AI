import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../providers/need_providers.dart';
import '../../../../providers/auth_providers.dart';

import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/services/audio_service.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SubmitNeedPage extends ConsumerStatefulWidget {
  /// When true (redirected from NeedConfirmationPage after a high-urgency
  /// text-only submission), the UI enforces that a photo must be selected
  /// before the form can be submitted.
  final bool isPhotoRequired;

  const SubmitNeedPage({super.key, this.isPhotoRequired = false});

  @override
  ConsumerState<SubmitNeedPage> createState() => _SubmitNeedPageState();
}

class _SubmitNeedPageState extends ConsumerState<SubmitNeedPage> {
  final _textController = TextEditingController();
  File? _selectedImage;
  final _picker = ImagePicker();
  List<int>? _audioBytes;
  bool _isRecording = false;
  bool _isProcessingVoice = false;
  bool _isLoadingSubmission = false;

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
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
          if (mounted) SnackbarUtils.showError(context, 'AI Dispatcher is busy. Please type manually.');
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
    if (_textController.text.trim().isEmpty && _audioBytes == null) {
      SnackbarUtils.showError(context, 'Please provide a description or use voice');
      return;
    }

    // Enforce photo for high-urgency re-submissions
    if (widget.isPhotoRequired && _selectedImage == null) {
      SnackbarUtils.showError(context, 'A photo is required for this high-urgency need');
      return;
    }

    setState(() => _isLoadingSubmission = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    double? lat;
    double? lng;

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        if (mounted) SnackbarUtils.showError(context, 'Location permission is required for accurate matching.');
      } else if (permission == LocationPermission.deniedForever) {
        if (mounted) SnackbarUtils.showError(context, 'Location permissions are permanently denied. Please enable in Settings.');
      } else {
        final serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          if (mounted) SnackbarUtils.showError(context, 'Please enable GPS/Location services on your device.');
        } else {
          final accuracy = await Geolocator.getLocationAccuracy();
          if (accuracy == LocationAccuracyStatus.reduced) {
            if (mounted) SnackbarUtils.showError(context, 'Please grant "Precise" location access for accurate matching.');
          }

          final position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.best,
            ),
          );
          lat = position.latitude;
          lng = position.longitude;
          debugPrint('Successfully fetched location: $lat, $lng');
        }
      }
    } catch (e) {
      debugPrint('Could not fetch location: $e');
    }

    if (mounted) Navigator.pop(context);

    final volunteerAsync = ref.read(volunteerProfileProvider);
    final primaryNgoId = volunteerAsync.value?.primaryNgoId ?? '';

    ref.read(needControllerProvider.notifier).submitNeed(
          _textController.text.trim(),
          _selectedImage,
          primaryNgoId,
          audioBytes: _audioBytes,
          lat: lat,
          lng: lng,
        );

    if (mounted) context.push('/ai-processing');
    setState(() => _isLoadingSubmission = false);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photoMissing = widget.isPhotoRequired && _selectedImage == null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report a Need'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Photo-required warning banner ───────────────────────────────
            if (widget.isPhotoRequired)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.error.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.error.withAlpha(150)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.camera_alt, color: AppColors.error, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'This high-urgency need requires a photo before it can be published.',
                        style: TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // ── Photo picker ────────────────────────────────────────────────
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(26),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    // Red border when photo is required but not yet selected
                    color: photoMissing
                        ? AppColors.error
                        : Colors.grey.withAlpha(76),
                    width: photoMissing ? 2 : 1,
                  ),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(_selectedImage!, fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.camera_alt,
                            size: 48,
                            color: photoMissing ? AppColors.error : Colors.grey,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            photoMissing
                                ? 'Tap to take a photo (required)'
                                : 'Tap to take a photo',
                            style: TextStyle(
                              color: photoMissing ? AppColors.error : Colors.grey,
                              fontWeight: photoMissing ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Voice recorder ──────────────────────────────────────────────
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
                    'Speak in your local language. AI will transcribe details.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _isProcessingVoice ? null : _toggleRecording,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: _isRecording ? AppColors.error : AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (_isRecording ? AppColors.error : AppColors.primary).withAlpha(100),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: _isProcessingVoice
                          ? const Padding(
                              padding: EdgeInsets.all(15),
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Icon(
                              _isRecording ? Icons.stop : Icons.mic,
                              color: Colors.white,
                              size: 28,
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
                    const SizedBox(height: 8),
                    const Text(
                      'AI is listening...',
                      style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 12),
                    ).animate(onPlay: (c) => c.repeat()).fadeIn().then().fadeOut(),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Text description ────────────────────────────────────────────
            TextField(
              controller: _textController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Describe the situation (e.g., "Family of 4 needs food near the temple...")',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // ── Submit button ───────────────────────────────────────────────
            ElevatedButton(
              // Disabled while recording, processing voice, loading, or photo missing
              onPressed: _isRecording || _isProcessingVoice || _isLoadingSubmission || photoMissing
                  ? null
                  : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isLoadingSubmission
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      photoMissing ? 'Add Photo to Continue' : 'Analyze with SevakAI',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
