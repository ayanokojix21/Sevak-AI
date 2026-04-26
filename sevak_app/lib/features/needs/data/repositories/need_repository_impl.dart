import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/utils/image_compressor.dart';
import '../../domain/entities/need_entity.dart';
import '../../domain/repositories/need_repository.dart';
import '../datasources/cloudinary_datasource.dart';
import '../datasources/ai_datasource.dart';
import '../datasources/needs_firestore_datasource.dart';
import '../datasources/nominatim_datasource.dart';
import '../models/need_model.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../matching/data/datasources/matching_ai_datasource.dart';
import '../../../matching/domain/usecases/match_volunteer_usecase.dart';

class NeedRepositoryImpl implements NeedRepository {
  final CloudinaryDatasource _cloudinary;
  final AiDatasource _ai;
  final NominatimDatasource _nominatim;
  final NeedsFirestoreDatasource _firestore;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  NeedRepositoryImpl({
    required CloudinaryDatasource cloudinary,
    required AiDatasource ai,
    required NominatimDatasource nominatim,
    required NeedsFirestoreDatasource firestore,
  })  : _cloudinary = cloudinary,
        _ai = ai,
        _nominatim = nominatim,
        _firestore = firestore;

  @override
  Future<NeedEntity> submitNeed({
    required String rawText,
    File? imageFile,
    required String ngoId,
    List<int>? audioBytes,
    double? lat,
    double? lng,
  }) async {
    // 1. Compress image ONCE — reuse bytes for both upload and AI
    List<int>? compressedBytes;
    if (imageFile != null) {
      compressedBytes = await ImageCompressor.compress(imageFile);
    }

    // 2 & 3. Parallelize Cloudinary upload + AI analysis
    final uploadFuture = compressedBytes != null
        ? _cloudinary.uploadImage(compressedBytes, 'need_${const Uuid().v4()}.jpg')
        : Future.value('');

    final aiFuture = audioBytes != null
        ? _ai.analyzeMultimodalEmergency(
            audioBytes: audioBytes,
            imageBytes: compressedBytes,
            textContext: rawText,
          )
        : _ai.analyzeNeed(rawText, compressedBytes);

    final results = await Future.wait([uploadFuture, aiFuture]);
    final imageUrl = results[0] as String;
    final aiData = results[1] as Map<String, dynamic>;

    // Fallback rawText if user submitted via one-tap voice with no text
    String finalText = rawText.trim();
    if (finalText.isEmpty && aiData['transcription'] != null) {
      finalText = aiData['transcription'] as String;
    }

    // 4. Geocoding — GPS takes priority, then AI-extracted location
    double finalLat = lat ?? 0.0;
    double finalLng = lng ?? 0.0;
    String locationText = aiData['location'] as String? ?? 'Unknown';

    try {
      if (finalLat != 0.0 && finalLng != 0.0) {
        if (locationText.toLowerCase() == 'unknown' || locationText.length < 5) {
          locationText = await _nominatim.reverseGeocode(finalLat, finalLng);
        }
      } else if (locationText.isNotEmpty && locationText.toLowerCase() != 'unknown') {
        final coords = await _nominatim.geocode(locationText);
        finalLat = coords['lat'] ?? 0.0;
        finalLng = coords['lng'] ?? 0.0;
      }
    } catch (e) {
      // Geocoding is best-effort — submission continues without it
    }

    // 5. Construct and persist
    final needModel = NeedModel(
      id: const Uuid().v4(),
      rawText: finalText,
      imageUrl: imageUrl,
      location: locationText,
      lat: finalLat,
      lng: finalLng,
      needType: aiData['needType'] as String? ?? 'OTHER',
      urgencyScore: (aiData['urgencyScore'] as num?)?.toInt() ?? 0,
      urgencyReason: aiData['urgencyReason'] as String? ?? '',
      peopleAffected: (aiData['peopleAffected'] as num?)?.toInt() ?? 0,
      status: 'SCORED',
      submittedBy: _auth.currentUser?.uid ?? 'anonymous',
      ngoId: ngoId,
      createdAt: DateTime.now(),
    );

    await _firestore.saveNeed(needModel);

    // 6. Always trigger auto-assignment — no urgency threshold
    debugPrint('[AutoAssign] Triggering match for need ${needModel.id}, urgency=${needModel.urgencyScore}, ngo=${needModel.ngoId}');
    try {
      final matchUseCase = MatchVolunteerUseCase(MatchingAiDatasource());
      final assignedUid = await matchUseCase(needModel);
      debugPrint('[AutoAssign] SUCCESS: Assigned volunteer $assignedUid to need ${needModel.id}');
    } catch (e) {
      // If matching fails (e.g. no volunteers available), it safely remains 'SCORED'
      debugPrint('[AutoAssign] FAILED for need ${needModel.id}: $e');
    }

    return needModel;
  }

  @override
  Stream<List<NeedEntity>> getNeedsStream({String? ngoId, String? status}) {
    return _firestore.streamNeeds(ngoId: ngoId, status: status);
  }
}
