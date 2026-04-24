import 'package:uuid/uuid.dart';
import '../entities/partnership_entity.dart';
import '../../data/models/partnership_model.dart';
import '../../data/datasources/partnerships_firestore_datasource.dart';

class SendPartnershipInviteUseCase {
  final PartnershipsFirestoreDatasource _datasource;

  SendPartnershipInviteUseCase(this._datasource);

  Future<void> call({
    required String senderNgoId,
    required String targetNgoId,
    required List<String> sharedSkills,
  }) async {
    final id = const Uuid().v4();
    final model = PartnershipModel(
      id: id,
      ngoA: senderNgoId,
      ngoB: targetNgoId,
      status: PartnershipStatus.pending,
      sharedSkills: sharedSkills,
      consentDate: DateTime.now(),
    );
    await _datasource.createPartnership(model);
  }
}
