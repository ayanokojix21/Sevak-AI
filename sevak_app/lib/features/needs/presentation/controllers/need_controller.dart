import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/need_entity.dart';
import '../../domain/usecases/submit_need_usecase.dart';

class NeedController extends StateNotifier<AsyncValue<NeedEntity?>> {
  final SubmitNeedUseCase _submitNeedUseCase;

  NeedController(this._submitNeedUseCase) : super(const AsyncData(null));

  Future<void> submitNeed(
    String text,
    Uint8List? imageBytes,
    String ngoId, {
    List<int>? audioBytes,
    double? lat,
    double? lng,
  }) async {
    state = const AsyncLoading();
    try {
      final result = await _submitNeedUseCase(
        rawText: text,
        imageBytes: imageBytes,
        ngoId: ngoId,
        audioBytes: audioBytes,
        lat: lat,
        lng: lng,
      );
      state = AsyncData(result);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  void reset() {
    state = const AsyncData(null);
  }
}
