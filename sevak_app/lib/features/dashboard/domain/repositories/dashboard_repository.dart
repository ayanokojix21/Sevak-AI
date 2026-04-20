import '../../../needs/domain/entities/need_entity.dart';
import '../entities/ngo_entity.dart';

/// Holds real-time aggregate statistics for the dashboard.
class DashboardStats {
  final int activeNeeds;
  final int resolvedNeeds;
  final int assignedNeeds;
  final int totalNeeds;

  const DashboardStats({
    required this.activeNeeds,
    required this.resolvedNeeds,
    required this.assignedNeeds,
    required this.totalNeeds,
  });

  factory DashboardStats.empty() => const DashboardStats(
        activeNeeds: 0,
        resolvedNeeds: 0,
        assignedNeeds: 0,
        totalNeeds: 0,
      );
}

/// Interface for Coordinator Dashboard data operations.
/// Follows Dependency Inversion (SOLID) — presentation depends on this
/// abstraction, not on the Firestore implementation.
abstract class DashboardRepository {
  /// Streams ALL needs in the system (global visibility for coordinators).
  /// Coordinators can see every need regardless of which NGO claimed it.
  Stream<List<NeedEntity>> streamAllNeeds();

  /// Streams needs claimed by a specific NGO.
  Stream<List<NeedEntity>> streamNgoNeeds(String ngoId);

  /// Claims an unclaimed need for the coordinator's NGO.
  /// Sets the `ngoId` field on the need document.
  Future<void> claimNeedForNgo({
    required String needId,
    required String ngoId,
  });

  /// Fetches NGO details by the coordinator's UID.
  Future<NgoEntity?> getNgoByCoordinatorUid(String uid);

  /// Fetches NGO name by NGO ID (for display in detail panel).
  Future<String> getNgoName(String ngoId);

  /// Updates a need's status (e.g. SCORED → ASSIGNED → COMPLETED).
  Future<void> updateNeedStatus({
    required String needId,
    required String newStatus,
  });
}
