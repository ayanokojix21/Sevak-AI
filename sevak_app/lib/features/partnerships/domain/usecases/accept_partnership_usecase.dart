import '../../data/datasources/partnerships_firestore_datasource.dart';

class AcceptPartnershipUseCase {
  final PartnershipsFirestoreDatasource _datasource;

  AcceptPartnershipUseCase(this._datasource);

  Future<void> call(String partnershipId) async {
    await _datasource.updatePartnershipStatus(partnershipId, 'active');
  }
}
