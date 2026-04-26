import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/dashboard/domain/entities/ngo_entity.dart';
import '../features/ngos/data/datasources/ngos_firestore_datasource.dart';
import '../features/ngos/data/datasources/join_request_datasource.dart';
import '../features/ngos/domain/entities/join_request_entity.dart';

final ngosDatasourceProvider = Provider<NgosFirestoreDatasource>((ref) {
  return NgosFirestoreDatasource();
});

final pendingNgosProvider = StreamProvider<List<NgoEntity>>((ref) {
  return ref.watch(ngosDatasourceProvider).streamPendingNgos();
});

final activeNgosProvider = StreamProvider<List<NgoEntity>>((ref) {
  return ref.watch(ngosDatasourceProvider).streamActiveNgos();
});

final allNgosProvider = StreamProvider<List<NgoEntity>>((ref) {
  return ref.watch(ngosDatasourceProvider).streamAllNgos();
});


/// Pending join requests for a specific NGO (used by NGO Admin).
final pendingJoinRequestsProvider =
    StreamProvider.family<List<JoinRequest>, String>((ref, ngoId) {
  return ref.watch(joinRequestDatasourceProvider).streamPendingRequests(ngoId);
});

/// All join requests by a specific user (used by "My Requests" UI).
final myJoinRequestsProvider =
    StreamProvider.family<List<JoinRequest>, String>((ref, userId) {
  return ref.watch(joinRequestDatasourceProvider).streamMyRequests(userId);
});
