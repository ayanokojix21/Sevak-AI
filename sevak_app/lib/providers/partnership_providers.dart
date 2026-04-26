import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/partnerships/data/datasources/partnerships_firestore_datasource.dart';
import '../features/partnerships/data/models/partnership_model.dart';
import '../features/partnerships/domain/usecases/send_partnership_invite_usecase.dart';
import '../features/partnerships/domain/usecases/accept_partnership_usecase.dart';

final partnershipsDatasourceProvider = Provider<PartnershipsFirestoreDatasource>((ref) {
  return PartnershipsFirestoreDatasource();
});

final sendPartnershipInviteUseCaseProvider = Provider<SendPartnershipInviteUseCase>((ref) {
  return SendPartnershipInviteUseCase(ref.watch(partnershipsDatasourceProvider));
});

final acceptPartnershipUseCaseProvider = Provider<AcceptPartnershipUseCase>((ref) {
  return AcceptPartnershipUseCase(ref.watch(partnershipsDatasourceProvider));
});

/// Real-time stream of all partnerships involving a given NGO (pending + active).
final partnershipsStreamProvider =
    StreamProvider.family<List<PartnershipModel>, String>((ref, ngoId) {
  return ref.watch(partnershipsDatasourceProvider).watchPartnershipsForNgo(ngoId);
});
