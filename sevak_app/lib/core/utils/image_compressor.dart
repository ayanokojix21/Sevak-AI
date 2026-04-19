import 'dart:io';
import 'dart:isolate';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../constants/app_constants.dart';

/// Compresses images before uploading to Cloudinary.
/// Runs in a separate Isolate to prevent UI jank on low-end devices.
class ImageCompressor {
  ImageCompressor._();

  /// Compresses [imageFile] to under [AppConstants.imageTargetSizeKb] KB.
  /// Runs in a background Isolate. Returns the compressed bytes.
  static Future<List<int>> compress(File imageFile) async {
    return Isolate.run(() => _compressInBackground(imageFile.path));
  }

  /// Private: Runs inside the Isolate.
  static Future<List<int>> _compressInBackground(String filePath) async {
    int quality = 90;
    List<int>? result;

    // First pass: resize width to max 1080px and compress
    result = await FlutterImageCompress.compressWithFile(
      filePath,
      minWidth: AppConstants.imageMaxWidthPx,
      minHeight: 0, // Auto height to maintain aspect ratio
      quality: quality,
      format: CompressFormat.jpeg,
    );

    // Iterative quality reduction until file is under target size
    const targetBytes = AppConstants.imageTargetSizeKb * 1024;
    while (result != null && result.length > targetBytes && quality > 10) {
      quality -= 10;
      result = await FlutterImageCompress.compressWithFile(
        filePath,
        minWidth: AppConstants.imageMaxWidthPx,
        minHeight: 0,
        quality: quality,
        format: CompressFormat.jpeg,
      );
    }

    if (result == null) {
      throw Exception('Image compression returned null result.');
    }

    return result;
  }
}
