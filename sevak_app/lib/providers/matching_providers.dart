import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/matching/data/datasources/matching_ai_datasource.dart';
import '../features/matching/domain/usecases/match_volunteer_usecase.dart';
import '../features/needs/domain/entities/need_entity.dart';

final matchingAiDatasourceProvider = Provider<MatchingAiDatasource>((ref) {
  return MatchingAiDatasource();
});

final matchVolunteerUseCaseProvider = Provider<MatchVolunteerUseCase>((ref) {
  return MatchVolunteerUseCase(ref.watch(matchingAiDatasourceProvider));
});

final matchingControllerProvider =
    StateNotifierProvider<MatchingController, AsyncValue<String?>>((ref) {
  return MatchingController(ref.watch(matchVolunteerUseCaseProvider));
});

class MatchingController extends StateNotifier<AsyncValue<String?>> {
  final MatchVolunteerUseCase _useCase;

  MatchingController(this._useCase) : super(const AsyncValue.data(null));

  Future<void> matchForNeed(NeedEntity need) async {
    state = const AsyncValue.loading();
    try {
      final matchedUid = await _useCase.call(need);
      state = AsyncValue.data(matchedUid);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void reset() => state = const AsyncValue.data(null);
}
