import 'dart:io';

import '../entities/need_entity.dart';
import '../repositories/need_repository.dart';

class SubmitNeedUseCase {
  final NeedRepository _repository;

  SubmitNeedUseCase(this._repository);

  Future<NeedEntity> call({
    required String rawText,
    File? imageFile,
    required String ngoId,
    List<int>? audioBytes,
    double? lat,
    double? lng,
  }) {
    return _repository.submitNeed(
      rawText: rawText,
      imageFile: imageFile,
      ngoId: ngoId,
      audioBytes: audioBytes,
      lat: lat,
      lng: lng,
    );
  }
}
