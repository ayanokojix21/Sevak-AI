class EnvConfig {
  EnvConfig._();

  static const String geminiApiKey =
      String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

  static const String geminiModel = 'gemini-1.5-flash';

  static const String cloudinaryCloudName =
      String.fromEnvironment('CLOUDINARY_CLOUD_NAME', defaultValue: '');

  static const String cloudinaryUploadPreset =
      String.fromEnvironment('CLOUDINARY_UPLOAD_PRESET', defaultValue: '');

  static void validate() {
    assert(
      geminiApiKey.isNotEmpty,
      'GEMINI_API_KEY is not set. Run with: flutter run --dart-define=GEMINI_API_KEY=your_key',
    );
    assert(
      cloudinaryCloudName.isNotEmpty,
      'CLOUDINARY_CLOUD_NAME is not set.',
    );
    assert(
      cloudinaryUploadPreset.isNotEmpty,
      'CLOUDINARY_UPLOAD_PRESET is not set.',
    );
  }
}
