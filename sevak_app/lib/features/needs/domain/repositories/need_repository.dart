import 'dart:io';
import '../entities/need_entity.dart';

abstract class NeedRepository {
  /// Processes a raw submission through the AI pipeline (Cloudinary -> Gemini -> Nominatim -> Firestore)
  Future<NeedEntity> submitNeed({
    required String rawText,
    required File imageFile,
    required String ngoId,
    double? lat,
    double? lng,
  });

  /// Streams needs, optionally filtered by NGO ID or status
  Stream<List<NeedEntity>> getNeedsStream({String? ngoId, String? status});
}
