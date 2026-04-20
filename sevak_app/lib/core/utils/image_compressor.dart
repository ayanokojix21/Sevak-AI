import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../constants/app_constants.dart';

/// Compresses images before uploading to Cloudinary.
/// Runs in a separate Isolate to prevent UI jank on low-end devices.
class ImageCompressor {
  ImageCompressor._();

  /// Compresses [imageFile] to under [AppConstants.imageTargetSizeKb] KB.
  /// Returns the compressed bytes.
  static Future<List<int>> compress(File imageFile) async {
    int quality = 90;
    List<int>? result;

    // First pass: resize to max 1080px and compress
    // FlutterImageCompress runs natively on a background thread, no Isolate needed.
    result = await FlutterImageCompress.compressWithFile(
      imageFile.path,
      minWidth: AppConstants.imageMaxWidthPx,
      minHeight: AppConstants.imageMaxWidthPx, // Prevent 0 height crash
      quality: quality,
      format: CompressFormat.jpeg,
    );

    // Iterative quality reduction until file is under target size
    const targetBytes = AppConstants.imageTargetSizeKb * 1024;
    while (result != null && result.length > targetBytes && quality > 10) {
      quality -= 10;
      result = await FlutterImageCompress.compressWithFile(
        imageFile.path,
        minWidth: AppConstants.imageMaxWidthPx,
        minHeight: AppConstants.imageMaxWidthPx,
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
