import 'dart:io';
import '../entities/need_entity.dart';
import '../repositories/need_repository.dart';

/// Orchestrates the full "submit a need" flow.
///
/// Currently a thin pass-through, but kept as a distinct use case for two reasons:
/// 1. Architectural consistency — every domain operation has its own use case.
/// 2. Future validation / orchestration (e.g. image size guard, rate limiting,
///    offline queuing) can be added here without touching the controller.
class SubmitNeedUseCase {
  final NeedRepository repository;

  SubmitNeedUseCase(this.repository);

  Future<NeedEntity> call({
    required String rawText,
    File? imageFile,
    required String ngoId,
    List<int>? audioBytes,
    double? lat,
    double? lng,
  }) async {
    return await repository.submitNeed(
      rawText: rawText,
      imageFile: imageFile,
      ngoId: ngoId,
      audioBytes: audioBytes,
      lat: lat,
      lng: lng,
    );
  }
}
