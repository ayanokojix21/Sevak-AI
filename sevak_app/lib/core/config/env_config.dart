import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  EnvConfig._();

  static String get geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  // Updated to the latest Gemini 2.5 Flash model
  static const String geminiModel = 'gemini-2.5-flash';

  static String get cloudinaryCloudName => dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';

  static String get cloudinaryApiKey => dotenv.env['CLOUDINARY_API_KEY'] ?? '';

  static String get cloudinaryApiSecret => dotenv.env['CLOUDINARY_API_SECRET'] ?? '';

  static void validate() {
    assert(
      geminiApiKey.isNotEmpty,
      'GEMINI_API_KEY is not set.',
    );
    assert(
      cloudinaryCloudName.isNotEmpty,
      'CLOUDINARY_CLOUD_NAME is not set.',
    );
    assert(
      cloudinaryApiKey.isNotEmpty,
      'CLOUDINARY_API_KEY is not set.',
    );
    assert(
      cloudinaryApiSecret.isNotEmpty,
      'CLOUDINARY_API_SECRET is not set.',
    );
  }
}
