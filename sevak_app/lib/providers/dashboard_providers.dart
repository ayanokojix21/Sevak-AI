import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/dashboard/data/datasources/dashboard_firestore_datasource.dart';
import '../features/dashboard/data/repositories/dashboard_repository_impl.dart';
import '../features/dashboard/domain/repositories/dashboard_repository.dart';
import '../features/dashboard/presentation/controllers/dashboard_controller.dart';
import '../features/dashboard/domain/entities/ngo_entity.dart';
import '../features/needs/domain/entities/need_entity.dart';
import 'community_report_providers.dart';

final dashboardFirestoreDatasourceProvider = Provider((ref) {
  return DashboardFirestoreDatasource();
});

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepositoryImpl(
    datasource: ref.watch(dashboardFirestoreDatasourceProvider),
  );
});

final selectedNeedProvider = StateProvider<NeedEntity?>((ref) => null);
final showGlobalNeedsProvider = StateProvider<bool>((ref) => true);
final coordinatorNgoProvider = StateProvider<NgoEntity?>((ref) => null);

final dashboardControllerProvider =
    StateNotifierProvider<DashboardController, AsyncValue<void>>((ref) {
  return DashboardController(ref.watch(dashboardRepositoryProvider), ref);
});


/// Streams ALL needs across the platform, ordered newest first.
final allNeedsRawStreamProvider = StreamProvider<List<NeedEntity>>((ref) {
  return ref.watch(dashboardRepositoryProvider).streamAllNeeds();
});

/// Global view: merges real needs + all pending community reports.
/// Used by the Super-Admin / Coordinator "Global" toggle.
final allNeedsStreamProvider = Provider<AsyncValue<List<NeedEntity>>>((ref) {
  final needsAsync = ref.watch(allNeedsRawStreamProvider);
  final reportsAsync = ref.watch(globalPendingCommunityReportsProvider);

  if (needsAsync.isLoading || reportsAsync.isLoading) {
    return const AsyncValue.loading();
  }
  if (needsAsync.hasError) {
    return AsyncValue.error(needsAsync.error!, needsAsync.stackTrace!);
  }
  if (reportsAsync.hasError) {
    return AsyncValue.error(reportsAsync.error!, reportsAsync.stackTrace!);
  }

  final needs = needsAsync.value ?? [];
  final reports = reportsAsync.value ?? [];

  final reportNeeds = reports.map((r) => NeedEntity(
        id: r.id,
        rawText: r.rawText,
        imageUrl: r.imageUrl,
        location: r.location,
        lat: r.lat,
        lng: r.lng,
        needType: r.needType,
        urgencyScore: r.urgencyScore,
        urgencyReason: r.urgencyReason,
        peopleAffected: r.peopleAffected,
        status: 'PENDING_APPROVAL',
        submittedBy: r.submittedBy,
        ngoId: r.targetNgoId,
        createdAt: r.createdAt,
      )).toList();

  final combined = [...needs, ...reportNeeds];
  combined.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return AsyncValue.data(combined);
});


/// Streams needs for a specific NGO.
final ngoNeedsStreamProvider =
    StreamProvider.family<List<NeedEntity>, String>((ref, ngoId) {
  return ref.watch(dashboardRepositoryProvider).streamNgoNeeds(ngoId);
});

/// Merged NGO view: needs + pending reports routed to that NGO.
final mergedNgoNeedsProvider =
    Provider.family<AsyncValue<List<NeedEntity>>, String>((ref, ngoId) {
  final needsAsync = ref.watch(ngoNeedsStreamProvider(ngoId));
  final reportsAsync = ref.watch(pendingCommunityReportsProvider(ngoId));

  if (needsAsync.isLoading || reportsAsync.isLoading) {
    return const AsyncValue.loading();
  }
  if (needsAsync.hasError) {
    return AsyncValue.error(needsAsync.error!, needsAsync.stackTrace!);
  }
  if (reportsAsync.hasError) {
    return AsyncValue.error(reportsAsync.error!, reportsAsync.stackTrace!);
  }

  final needs = needsAsync.value ?? [];
  final reports = reportsAsync.value ?? [];

  final reportNeeds = reports.map((r) => NeedEntity(
        id: r.id,
        rawText: r.rawText,
        imageUrl: r.imageUrl,
        location: r.location,
        lat: r.lat,
        lng: r.lng,
        needType: r.needType,
        urgencyScore: r.urgencyScore,
        urgencyReason: r.urgencyReason,
        peopleAffected: r.peopleAffected,
        status: 'PENDING_APPROVAL',
        submittedBy: r.submittedBy,
        ngoId: r.targetNgoId,
        createdAt: r.createdAt,
      )).toList();

  final combined = [...needs, ...reportNeeds];
  combined.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return AsyncValue.data(combined);
});
