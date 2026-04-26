import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../needs/domain/entities/need_entity.dart';
import '../../../community_reports/data/datasources/community_reports_datasource.dart';
import '../../../needs/data/models/need_model.dart';
import '../../domain/entities/ngo_entity.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../providers/matching_providers.dart';



/// Controller for all Coordinator Dashboard actions.
class DashboardController extends StateNotifier<AsyncValue<void>> {
  final DashboardRepository _repository;
  final Ref _ref;

  DashboardController(this._repository, this._ref) : super(const AsyncValue.data(null));

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

  /// Approves a community report and moves it to the main needs collection.
  Future<void> approveCommunityReport(NeedEntity reportAsNeed) async {
    state = const AsyncValue.loading();
    try {
      // 1. Mark report as approved
      final reportsDs = _ref.read(communityReportsDatasourceProvider);
      await reportsDs.approveReport(reportAsNeed.id);
      
      // 2. Add to Needs collection
      final newNeed = NeedModel(
        id: reportAsNeed.id,
        rawText: reportAsNeed.rawText,
        imageUrl: reportAsNeed.imageUrl,
        location: reportAsNeed.location,
        lat: reportAsNeed.lat,
        lng: reportAsNeed.lng,
        needType: reportAsNeed.needType,
        urgencyScore: reportAsNeed.urgencyScore,
        urgencyReason: reportAsNeed.urgencyReason,
        peopleAffected: reportAsNeed.peopleAffected,
        status: 'SCORED', // It's approved and scored, ready for volunteers
        submittedBy: reportAsNeed.submittedBy,
        ngoId: reportAsNeed.ngoId,
        createdAt: reportAsNeed.createdAt,
      );
      
      await FirebaseFirestore.instance
          .collection(AppConstants.needsCollection)
          .doc(newNeed.id)
          .set(newNeed.toJson());

      // 3. Always trigger auto-assignment after coordinator approval
      debugPrint('[DashboardController] Triggering auto-match: urgency=${newNeed.urgencyScore}, ngo=${newNeed.ngoId}, lat=${newNeed.lat}, lng=${newNeed.lng}');
      try {
        final matchUseCase = _ref.read(matchVolunteerUseCaseProvider);
        final assignedUid = await matchUseCase.call(newNeed);
        debugPrint('[DashboardController] Auto-match SUCCESS: volunteer=$assignedUid');
      } catch (e) {
        // If matching fails (e.g. no volunteers available), it safely remains 'SCORED'
        debugPrint('[DashboardController] Auto-match FAILED: $e');
      }

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
