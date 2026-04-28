import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/needs/data/datasources/cloudinary_datasource.dart';
import '../features/needs/domain/entities/need_entity.dart';
import '../features/needs/data/datasources/ai_datasource.dart';
import '../features/needs/data/datasources/needs_firestore_datasource.dart';
import '../features/needs/data/datasources/nominatim_datasource.dart';
import '../features/needs/data/repositories/need_repository_impl.dart';
import '../features/needs/domain/repositories/need_repository.dart';
import '../features/needs/domain/usecases/submit_need_usecase.dart';
import '../features/needs/presentation/controllers/need_controller.dart';
import 'auth_providers.dart';

export '../features/needs/data/datasources/cloudinary_datasource.dart';
export '../features/needs/data/datasources/ai_datasource.dart';
export '../features/needs/data/datasources/needs_firestore_datasource.dart';
export '../features/needs/data/datasources/nominatim_datasource.dart';
export '../features/needs/domain/entities/need_entity.dart';

// --- Data Sources ---
final cloudinaryProvider = Provider((ref) => CloudinaryDatasource());
final aiDatasourceProvider = Provider((ref) => AiDatasource());
final nominatimProvider = Provider((ref) => NominatimDatasource());
final needsFirestoreProvider = Provider((ref) => NeedsFirestoreDatasource());

// --- Repositories ---
final needRepositoryProvider = Provider<NeedRepository>((ref) {
  return NeedRepositoryImpl(
    cloudinary: ref.watch(cloudinaryProvider),
    ai: ref.watch(aiDatasourceProvider),
    firestore: ref.watch(needsFirestoreProvider),
    nominatim: ref.watch(nominatimProvider),
  );
});

// --- Use Cases ---
final submitNeedUseCaseProvider = Provider((ref) => SubmitNeedUseCase(ref.watch(needRepositoryProvider)));

// --- Controllers ---
final needControllerProvider = StateNotifierProvider<NeedController, AsyncValue<NeedEntity?>>((ref) {
  return NeedController(ref.watch(submitNeedUseCaseProvider));
});

// --- User's Own Needs ---
final mySubmittedNeedsProvider = StreamProvider<List<NeedEntity>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);
  return ref.watch(needsFirestoreProvider).streamNeedsByUser(user.uid);
});
