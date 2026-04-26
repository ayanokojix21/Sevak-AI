import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralised environment configuration for SevakAI.
/// All API keys and model identifiers are defined here — no magic strings elsewhere.
class EnvConfig {
  EnvConfig._();

  static String get geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  static String get groqApiKey => dotenv.env['GROQ_API_KEY'] ?? '';
  static String get cloudinaryCloudName => dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
  static String get cloudinaryApiKey => dotenv.env['CLOUDINARY_API_KEY'] ?? '';
  static String get cloudinaryApiSecret => dotenv.env['CLOUDINARY_API_SECRET'] ?? '';

  static const String groqBaseUrl = 'https://api.groq.com/openai/v1';

  /// Best reasoning model — used for volunteer matching & impact stories.
  static const String groqReasoningModel = 'openai/gpt-oss-120b';

  /// Fastest model — used for Co-Pilot chat where latency matters most.
  static const String groqFastModel = 'llama-3.1-8b-instant';

  /// Vision-capable model — used for image + text emergency triage.
  static const String groqVisionModel = 'meta-llama/llama-4-scout-17b-16e-instruct';

  /// Audio transcription model.
  static const String groqWhisperModel = 'whisper-large-v3';

  /// Stable, proven model on the free tier — used only when Groq fails.
  static const String geminiModel = 'gemini-2.5-flash';

  static String get googleServerClientId => 
      dotenv.env['GOOGLE_SERVER_CLIENT_ID'] ?? '29483186959-kkfe05gcogr1s638h81ponal5du3gt7i.apps.googleusercontent.com';

  static String get nominatimUserAgent =>
      dotenv.env['NOMINATIM_USER_AGENT'] ?? 'SevakAI/1.0 (sevakai@gmail.com)';

  static void validate() {
    assert(groqApiKey.isNotEmpty, 'GROQ_API_KEY is not set.');
    assert(geminiApiKey.isNotEmpty, 'GEMINI_API_KEY is not set.');
    assert(cloudinaryCloudName.isNotEmpty, 'CLOUDINARY_CLOUD_NAME is not set.');
    assert(cloudinaryApiKey.isNotEmpty, 'CLOUDINARY_API_KEY is not set.');
    assert(cloudinaryApiSecret.isNotEmpty, 'CLOUDINARY_API_SECRET is not set.');
  }
}
