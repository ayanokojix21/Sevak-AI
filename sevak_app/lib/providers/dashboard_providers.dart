import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/dashboard/data/datasources/dashboard_firestore_datasource.dart';
import '../features/dashboard/data/repositories/dashboard_repository_impl.dart';
import '../features/dashboard/domain/repositories/dashboard_repository.dart';
import '../features/dashboard/presentation/controllers/dashboard_controller.dart';
import '../features/needs/domain/entities/need_entity.dart';

// ── Data Source ───────────────────────────────────────────────────────────────
final dashboardFirestoreDatasourceProvider = Provider((ref) {
  return DashboardFirestoreDatasource();
});

// ── Repository ───────────────────────────────────────────────────────────────
final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepositoryImpl(
    datasource: ref.watch(dashboardFirestoreDatasourceProvider),
  );
});

// ── Controller ───────────────────────────────────────────────────────────────
final dashboardControllerProvider =
    StateNotifierProvider<DashboardController, AsyncValue<void>>((ref) {
  return DashboardController(ref.watch(dashboardRepositoryProvider));
});

// ── Streams ──────────────────────────────────────────────────────────────────

/// Streams ALL needs across the platform (global view).
final allNeedsStreamProvider = StreamProvider<List<NeedEntity>>((ref) {
  return ref.watch(dashboardRepositoryProvider).streamAllNeeds();
});

/// Streams needs for a specific NGO (filtered view).
/// Usage: ref.watch(ngoNeedsStreamProvider('ngo_id'))
final ngoNeedsStreamProvider =
    StreamProvider.family<List<NeedEntity>, String>((ref, ngoId) {
  return ref.watch(dashboardRepositoryProvider).streamNgoNeeds(ngoId);
});
