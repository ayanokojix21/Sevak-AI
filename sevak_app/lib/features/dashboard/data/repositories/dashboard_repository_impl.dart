import '../../../needs/domain/entities/need_entity.dart';
import '../../domain/entities/ngo_entity.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/dashboard_firestore_datasource.dart';

/// Concrete implementation of [DashboardRepository].
class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardFirestoreDatasource _datasource;

  DashboardRepositoryImpl({required DashboardFirestoreDatasource datasource})
      : _datasource = datasource;

  @override
  Stream<List<NeedEntity>> streamAllNeeds() {
    return _datasource.streamAllNeeds();
  }

  @override
  Stream<List<NeedEntity>> streamNgoNeeds(String ngoId) {
    return _datasource.streamNgoNeeds(ngoId);
  }

  @override
  Future<void> claimNeedForNgo({
    required String needId,
    required String ngoId,
  }) async {
    await _datasource.claimNeedForNgo(needId: needId, ngoId: ngoId);
  }

  @override
  Future<NgoEntity?> getNgoByCoordinatorUid(String uid) async {
    return await _datasource.getNgoByCoordinatorUid(uid);
  }

  @override
  Future<String> getNgoName(String ngoId) async {
    return await _datasource.getNgoName(ngoId);
  }

  @override
  Future<void> updateNeedStatus({
    required String needId,
    required String newStatus,
  }) async {
    await _datasource.updateNeedStatus(needId: needId, newStatus: newStatus);
  }
}
