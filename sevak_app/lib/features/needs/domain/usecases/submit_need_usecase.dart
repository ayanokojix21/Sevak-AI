import 'dart:io';
import '../entities/need_entity.dart';
import '../repositories/need_repository.dart';

class SubmitNeedUseCase {
  final NeedRepository repository;

  SubmitNeedUseCase(this.repository);

  Future<NeedEntity> call({
    required String rawText,
    required File imageFile,
    required String ngoId,
    double? lat,
    double? lng,
  }) async {
    return await repository.submitNeed(
      rawText: rawText,
      imageFile: imageFile,
      ngoId: ngoId,
      lat: lat,
      lng: lng,
    );
  }
}
