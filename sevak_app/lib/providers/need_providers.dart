import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/needs/data/datasources/cloudinary_datasource.dart';
import '../features/needs/domain/entities/need_entity.dart';
import '../features/needs/data/datasources/gemini_datasource.dart';
import '../features/needs/data/datasources/needs_firestore_datasource.dart';
import '../features/needs/data/datasources/nominatim_datasource.dart';
import '../features/needs/data/repositories/need_repository_impl.dart';
import '../features/needs/domain/repositories/need_repository.dart';
import '../features/needs/domain/usecases/submit_need_usecase.dart';
import '../features/needs/presentation/controllers/need_controller.dart';

// --- Data Sources ---
final cloudinaryProvider = Provider((ref) => CloudinaryDatasource());
final geminiProvider = Provider((ref) => GeminiDatasource());
final nominatimProvider = Provider((ref) => NominatimDatasource());
final needsFirestoreProvider = Provider((ref) => NeedsFirestoreDatasource());

// --- Repositories ---
final needRepositoryProvider = Provider<NeedRepository>((ref) {
  return NeedRepositoryImpl(
    cloudinary: ref.watch(cloudinaryProvider),
    gemini: ref.watch(geminiProvider),
    nominatim: ref.watch(nominatimProvider),
    firestore: ref.watch(needsFirestoreProvider),
  );
});

// --- Use Cases ---
final submitNeedUseCaseProvider = Provider((ref) {
  return SubmitNeedUseCase(ref.watch(needRepositoryProvider));
});

// --- Controllers ---
final needControllerProvider = StateNotifierProvider<NeedController, AsyncValue<NeedEntity?>>((ref) {
  return NeedController(ref.watch(submitNeedUseCaseProvider));
});
