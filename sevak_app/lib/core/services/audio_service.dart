import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

/// Manages audio recording lifecycle for voice reports.
///
/// Design decisions:
/// - Uses `record` package (backed by OS MediaRecorder) for M4A/AAC output
///   which Groq Whisper accepts natively.
/// - Temp files are deleted after bytes are read to avoid filling device storage.
/// - Provider is `keepAlive: true` so the recorder state survives hot-reload.
class AudioService {
  final _recorder = AudioRecorder();
  String? _currentPath;

  /// Requests microphone permission and starts a new recording.
  /// Returns `false` if permission is denied or recorder is already active.
  Future<bool> startRecording() async {
    try {
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        debugPrint('[AudioService] Mic permission denied.');
        return false;
      }

      if (await _recorder.isRecording()) {
        debugPrint('[AudioService] Already recording, ignoring start.');
        return false;
      }

      String path = '';
      if (!kIsWeb) {
        final dir = await getTemporaryDirectory();
        path = '${dir.path}/sevak_audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      }
      _currentPath = path;

      const config = RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 64000,  // 64 kbps is sufficient for speech; halves file size vs 128 kbps
        sampleRate: 16000, // 16 kHz is the native rate Whisper was trained on
        numChannels: 1,    // Mono — speech is mono; halves file size again
      );

      await _recorder.start(config, path: _currentPath!);
      debugPrint('[AudioService] Recording started → $_currentPath');
      return true;
    } catch (e) {
      debugPrint('[AudioService] Start error: $e');
      return false;
    }
  }

  /// Stops the current recording.
  /// Returns the path to the audio file (or blob URL on web), or null on error.
  Future<String?> stopRecording() async {
    try {
      final path = await _recorder.stop();
      debugPrint('[AudioService] Recording stopped → $path');
      return path;
    } catch (e) {
      debugPrint('[AudioService] Stop error: $e');
      return null;
    }
  }

  /// Reads audio bytes from [path] then deletes the temp file.
  Future<List<int>?> getAudioBytesAndCleanup(String path) async {
    try {
      if (kIsWeb) {
        // On web, the path is a blob URL. We fetch it via HTTP.
        final response = await http.get(Uri.parse(path));
        return response.bodyBytes;
      } else {
        // Native platforms use File
        final file = File(path);
        if (!await file.exists()) {
          debugPrint('[AudioService] File not found: $path');
          return null;
        }
        final bytes = await file.readAsBytes();
        debugPrint('[AudioService] Read ${bytes.length} bytes from $path');
        // Delete temp file to free device storage
        await file.delete();
        debugPrint('[AudioService] Temp file deleted: $path');
        return bytes;
      }
    } catch (e) {
      debugPrint('[AudioService] Read/cleanup error: $e');
      return null;
    }
  }

  /// Legacy alias — kept for backward compat with pages not yet migrated.
  @Deprecated('Use getAudioBytesAndCleanup to also delete the temp file.')
  Future<List<int>?> getAudioBytes(String path) => getAudioBytesAndCleanup(path);

  Future<void> dispose() async {
    await _recorder.dispose();
    // Clean up any leftover temp file from an interrupted session
    if (!kIsWeb && _currentPath != null && _currentPath!.isNotEmpty) {
      final f = File(_currentPath!);
      if (await f.exists()) await f.delete();
    }
  }
}

/// Ref-counted provider — kept alive so recording state survives widget rebuilds.
final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService();
  ref.onDispose(service.dispose);
  return service;
});

