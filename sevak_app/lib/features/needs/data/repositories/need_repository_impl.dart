import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

import 'package:sevak_app/core/utils/image_compressor.dart';
import '../../domain/entities/need_entity.dart';
import '../../domain/repositories/need_repository.dart';
import '../datasources/cloudinary_datasource.dart';
import '../datasources/gemini_datasource.dart';
import '../datasources/needs_firestore_datasource.dart';
import '../datasources/nominatim_datasource.dart';
import '../models/need_model.dart';

class NeedRepositoryImpl implements NeedRepository {
  final CloudinaryDatasource _cloudinary;
  final GeminiDatasource _gemini;
  final NominatimDatasource _nominatim;
  final NeedsFirestoreDatasource _firestore;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  NeedRepositoryImpl({
    required CloudinaryDatasource cloudinary,
    required GeminiDatasource gemini,
    required NominatimDatasource nominatim,
    required NeedsFirestoreDatasource firestore,
  })  : _cloudinary = cloudinary,
        _gemini = gemini,
        _nominatim = nominatim,
        _firestore = firestore;

  @override
  Future<NeedEntity> submitNeed({
    required String rawText,
    required File imageFile,
    required String ngoId,
    double? lat,
    double? lng,
  }) async {
    // 1. Compress Image in Isolate
    final compressedBytes = await ImageCompressor.compress(imageFile);

    // 2. Upload to Cloudinary
    final filename = 'need_\${const Uuid().v4()}.jpg';
    final imageUrl = await _cloudinary.uploadImage(compressedBytes, filename);

    // 3. Gemini Extraction
    final aiData = await _gemini.analyzeNeed(rawText, compressedBytes);
    // 4. Geocoding
    double finalLat = lat ?? 0.0;
    double finalLng = lng ?? 0.0;
    String locationText = aiData['location'] as String? ?? 'Unknown';

    try {
      if (finalLat != 0.0 && finalLng != 0.0) {
        // We have GPS coordinates from the device! Let's try to reverse geocode to get a human-readable address if Gemini's is poor.
        if (locationText.toLowerCase() == 'unknown' || locationText.length < 5) {
          locationText = await _nominatim.reverseGeocode(finalLat, finalLng);
        }
      } else if (locationText != 'Unknown' && locationText.isNotEmpty) {
        // We don't have device GPS, so we forward-geocode the text Gemini found.
        final coords = await _nominatim.geocode(locationText);
        finalLat = coords['lat'] ?? 0.0;
        finalLng = coords['lng'] ?? 0.0;
      }
    } catch (e) {
      // Fallback: If geocoding fails, we just keep whatever we have.
    }

    // 5. Construct Model
    final needModel = NeedModel(
      id: const Uuid().v4(),
      rawText: rawText,
      imageUrl: imageUrl,
      location: locationText,
      lat: finalLat,
      lng: finalLng,
      needType: aiData['needType'] as String? ?? 'OTHER',
      urgencyScore: (aiData['urgencyScore'] as num?)?.toInt() ?? 0,
      urgencyReason: aiData['urgencyReason'] as String? ?? '',
      peopleAffected: (aiData['peopleAffected'] as num?)?.toInt() ?? 0,
      status: 'SCORED', // Immediately scored since we used Gemini
      submittedBy: _auth.currentUser?.uid ?? 'anonymous',
      ngoId: ngoId,
      createdAt: DateTime.now(),
    );

    // 6. Save to Firestore
    return await _firestore.saveNeed(needModel);
  }

  @override
  Stream<List<NeedEntity>> getNeedsStream({String? ngoId, String? status}) {
    return _firestore.streamNeeds(ngoId: ngoId, status: status);
  }
}
