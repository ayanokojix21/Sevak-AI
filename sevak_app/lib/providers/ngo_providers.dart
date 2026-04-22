import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sevak_app/features/ngos/data/datasources/ngos_firestore_datasource.dart';
import 'package:sevak_app/features/ngos/domain/entities/ngo_entity.dart';

final ngosDatasourceProvider = Provider<NgosFirestoreDatasource>((ref) {
  return NgosFirestoreDatasource();
});

final pendingNgosProvider = StreamProvider<List<NgoEntity>>((ref) {
  return ref.watch(ngosDatasourceProvider).streamPendingNgos();
});

final activeNgosProvider = StreamProvider<List<NgoEntity>>((ref) {
  return ref.watch(ngosDatasourceProvider).streamActiveNgos();
});
