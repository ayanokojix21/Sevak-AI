import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/distance_calculator.dart';
import '../../../../core/utils/image_compressor.dart';
import '../../../../providers/need_providers.dart';
import '../../../matching/data/datasources/matching_ai_datasource.dart';
import '../../../matching/domain/usecases/match_volunteer_usecase.dart';
import '../../../needs/data/models/need_model.dart';
import '../../data/datasources/community_reports_datasource.dart';
import '../../data/models/community_report_model.dart';

final submitCommunityReportUseCaseProvider = Provider<SubmitCommunityReportUseCase>((ref) {
  return SubmitCommunityReportUseCase(
    ref.read(cloudinaryProvider),
    ref.read(aiDatasourceProvider),
    ref.read(nominatimProvider),
    ref.read(communityReportsDatasourceProvider),
  );
});

class SubmitCommunityReportUseCase {
  final CloudinaryDatasource _cloudinary;
  final AiDatasource _ai;
  final NominatimDatasource _nominatim;
  final CommunityReportsDatasource _reportsDatasource;
  // Use a single static reference — do NOT instantiate per-request
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  SubmitCommunityReportUseCase(
    this._cloudinary,
    this._ai,
    this._nominatim,
    this._reportsDatasource,
  );

  Future<void> call({
    required String rawText,
    Uint8List? imageBytes,
    List<int>? audioBytes,
    double? lat,
    double? lng,
  }) async {
    try {
      // 1. Compress image once — reuse for both Cloudinary and AI
      List<int>? compressedBytes;
      if (imageBytes != null) {
        compressedBytes = await ImageCompressor.compress(imageBytes);
      }

      // 2 & 3. Parallelize: Upload to Cloudinary + Run AI simultaneously
      final uploadFuture = compressedBytes != null
          ? _uploadImageSafe(compressedBytes)
          : Future.value('');
          
      final aiFuture = _runAiAnalysis(
        rawText: rawText,
        compressedBytes: compressedBytes,
        audioBytes: audioBytes,
      );

      final results = await Future.wait([uploadFuture, aiFuture]);
      final imageUrl = results[0] as String;
      final aiData = results[1] as Map<String, dynamic>;

      // 4. Geocoding — skip if both GPS coords and AI location are empty
      final geo = await _resolveLocation(
        gpsLat: lat,
        gpsLng: lng,
        aiLocation: aiData['location'] as String? ?? '',
      );

      // 5. Find nearest active NGO using correct field names (hqLat / hqLng)
      final nearestNgoId = await _findNearestNgoId(geo.lat, geo.lng);

      // 6. Resolve final text
      String finalText = rawText.trim();
      if (finalText.isEmpty && aiData['transcription'] != null) {
        finalText = aiData['transcription'] as String;
      }

      final needId = const Uuid().v4();
      final urgencyScore = int.tryParse(aiData['urgencyScore']?.toString() ?? '0') ?? 0;

      // 7. Save the report record for history tracking
      final reportModel = CommunityReportModel(
        id: needId,
        rawText: finalText,
        imageUrl: imageUrl,
        location: geo.address,
        lat: geo.lat,
        lng: geo.lng,
        needType: aiData['needType'] as String? ?? 'OTHER',
        urgencyScore: urgencyScore,
        urgencyReason: aiData['urgencyReason'] as String? ?? '',
        peopleAffected: int.tryParse(aiData['peopleAffected']?.toString() ?? '0') ?? 0,
        status: 'APPROVED', // Auto-approved — no manual review needed
        submittedBy: _auth.currentUser?.uid ?? 'anonymous',
        targetNgoId: nearestNgoId,
        createdAt: DateTime.now(),
        scaleAssessment: aiData['scaleAssessment'] != null
            ? ScaleAssessment.fromJson(aiData['scaleAssessment'] as Map<String, dynamic>)
            : ScaleAssessment.empty,
      );

      await _reportsDatasource.submitReport(reportModel);
      debugPrint('[Report] Saved with id=$needId, ngo=$nearestNgoId');

      // 8. Directly add to Needs collection and trigger AI volunteer matching
      final needModel = NeedModel(
        id: needId,
        rawText: finalText,
        imageUrl: imageUrl,
        location: geo.address,
        lat: geo.lat,
        lng: geo.lng,
        needType: aiData['needType'] as String? ?? 'OTHER',
        urgencyScore: urgencyScore,
        urgencyReason: aiData['urgencyReason'] as String? ?? '',
        peopleAffected: int.tryParse(aiData['peopleAffected']?.toString() ?? '0') ?? 0,
        status: 'SCORED',
        submittedBy: _auth.currentUser?.uid ?? 'anonymous',
        ngoId: nearestNgoId,
        createdAt: DateTime.now(),
      );

      await _db
          .collection(AppConstants.needsCollection)
          .doc(needId)
          .set(needModel.toJson());

      // 9. Auto-assign a volunteer immediately — no human approval needed
      debugPrint('[Report] Triggering auto-match for need=$needId, urgency=$urgencyScore, ngo=$nearestNgoId');
      try {
        final matchUseCase = MatchVolunteerUseCase(MatchingAiDatasource());
        final assignedUid = await matchUseCase.call(needModel);
        debugPrint('[Report] Auto-match SUCCESS: volunteer=$assignedUid');
      } catch (e) {
        // Matching may fail if no volunteers available — need stays SCORED for later
        debugPrint('[Report] Auto-match FAILED (will retry later): $e');
      }
    } catch (e) {
      debugPrint('[Report] Critical Error: $e');
      rethrow;
    }
  }



  /// Uploads image; returns empty string on failure (non-fatal).
  Future<String> _uploadImageSafe(List<int> bytes) async {
    try {
      final filename = 'report_${const Uuid().v4()}.jpg';
      return await _cloudinary.uploadImage(bytes, filename);
    } catch (e) {
      debugPrint('[Cloudinary] Upload failed (non-fatal): $e');
      return '';
    }
  }

  /// Runs AI analysis; returns empty map on failure (non-fatal).
  Future<Map<String, dynamic>> _runAiAnalysis({
    required String rawText,
    List<int>? compressedBytes,
    List<int>? audioBytes,
  }) async {
    try {
      if (audioBytes != null) {
        debugPrint('[AI] Using Multimodal Analysis (Audio + Image)...');
        return await _ai.analyzeMultimodalEmergency(
          audioBytes: audioBytes,
          imageBytes: compressedBytes,
          textContext: rawText,
        );
      } else {
        return await _ai.analyzeNeed(rawText, compressedBytes);
      }
    } catch (e) {
      debugPrint('[AI] Analysis failed (non-fatal): $e');
      return {};
    }
  }

  /// Resolves final lat/lng + human-readable address.
  Future<_GeoResult> _resolveLocation({
    required double? gpsLat,
    required double? gpsLng,
    required String aiLocation,
  }) async {
    double finalLat = gpsLat ?? 0.0;
    double finalLng = gpsLng ?? 0.0;
    String address = aiLocation.isNotEmpty ? aiLocation : 'Unknown';

    try {
      if (finalLat != 0.0 && finalLng != 0.0) {
        // We have GPS → try to get a readable address if AI's is poor
        if (address.toLowerCase() == 'unknown' || address.length < 5) {
          address = await _nominatim.reverseGeocode(finalLat, finalLng);
        }
      } else if (address.isNotEmpty && address.toLowerCase() != 'unknown') {
        // No GPS → forward-geocode the AI's location string
        final coords = await _nominatim.geocode(address);
        finalLat = coords['lat'] ?? 0.0;
        finalLng = coords['lng'] ?? 0.0;
      }
    } catch (e) {
      debugPrint('[Geocoding] Error (non-fatal): $e');
    }

    return _GeoResult(lat: finalLat, lng: finalLng, address: address);
  }

  /// Finds the nearest active NGO. Uses `hqLat`/`hqLng` — the correct field
  /// names from the NGO model's toJson().
  Future<String> _findNearestNgoId(double lat, double lng) async {
    if (lat == 0.0 && lng == 0.0) {
      debugPrint('[NGO Lookup] No GPS coords — skipping NGO assignment.');
      return '';
    }

    try {
      final snap = await _db
          .collection(AppConstants.ngosCollection)
          .where('status', isEqualTo: 'active')
          .get();

      String nearestId = '';
      double minDistance = double.infinity;

      for (final doc in snap.docs) {
        final data = doc.data();
        // FIX: NGO model uses hqLat/hqLng, not lat/lng
        final ngoLat = (data['hqLat'] as num?)?.toDouble() ?? 0.0;
        final ngoLng = (data['hqLng'] as num?)?.toDouble() ?? 0.0;

        if (ngoLat == 0.0 && ngoLng == 0.0) continue;

        final dist = DistanceCalculator.distanceInKm(lat, lng, ngoLat, ngoLng);
        if (dist < minDistance) {
          minDistance = dist;
          nearestId = doc.id;
        }
      }

      if (nearestId.isEmpty) {
        debugPrint('[NGO Lookup] No active NGO with coordinates found.');
      } else {
        debugPrint('[NGO Lookup] Assigned to ngo=$nearestId (${minDistance.toStringAsFixed(1)} km away)');
      }
      return nearestId;
    } catch (e) {
      debugPrint('[NGO Lookup] Error: $e');
      return '';
    }
  }
}

class _GeoResult {
  final double lat;
  final double lng;
  final String address;
  const _GeoResult({required this.lat, required this.lng, required this.address});
}
