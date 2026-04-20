import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../needs/domain/entities/need_entity.dart';
import '../../domain/entities/ngo_entity.dart';
import '../../domain/repositories/dashboard_repository.dart';

/// Tracks which need is currently selected in the detail panel.
final selectedNeedProvider = StateProvider<NeedEntity?>((ref) => null);

/// Toggles between showing ALL needs (global) vs. only the coordinator's NGO needs.
final showGlobalNeedsProvider = StateProvider<bool>((ref) => true);

/// Holds the coordinator's NGO entity (fetched on dashboard load).
final coordinatorNgoProvider = StateProvider<NgoEntity?>((ref) => null);

/// Controller for all Coordinator Dashboard actions.
class DashboardController extends StateNotifier<AsyncValue<void>> {
  final DashboardRepository _repository;

  DashboardController(this._repository) : super(const AsyncValue.data(null));

  /// Claims an unclaimed need for the coordinator's NGO.
  Future<void> claimNeed({
    required String needId,
    required String ngoId,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.claimNeedForNgo(needId: needId, ngoId: ngoId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Fetches the NGO associated with the current coordinator.
  Future<NgoEntity?> loadCoordinatorNgo(String uid) async {
    try {
      return await _repository.getNgoByCoordinatorUid(uid);
    } catch (_) {
      return null;
    }
  }

  /// Fetches the name of an NGO by its ID.
  Future<String> getNgoName(String ngoId) async {
    return await _repository.getNgoName(ngoId);
  }

  /// Updates a need's status.
  Future<void> updateStatus({
    required String needId,
    required String newStatus,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateNeedStatus(
        needId: needId,
        newStatus: newStatus,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
