import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/distance_calculator.dart';
import '../../../auth/domain/entities/volunteer.dart';
import '../../../needs/domain/entities/need_entity.dart';
import '../../../partnerships/data/models/cross_ngo_task_model.dart';
import '../../../partnerships/domain/entities/cross_ngo_task_entity.dart';
import '../../data/datasources/matching_gemini_datasource.dart';

class MatchVolunteerUseCase {
  final MatchingGeminiDatasource _gemini;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  MatchVolunteerUseCase(this._gemini);

  /// Main entry point. Tries single-NGO first, escalates to cross-NGO.
  Future<String> call(NeedEntity need) async {
    // ── Step 1: Single-NGO matching ──────────────────────────────────────────
    final ownVolunteers = await _fetchAvailableVolunteers(
      ngoId: need.ngoId,
      needLat: need.lat,
      needLng: need.lng,
      radiusKm: AppConstants.maxMatchingRadiusKm,
      requireCrossNgoConsent: false,
    );

    if (ownVolunteers.isNotEmpty) {
      return _runGeminiMatch(need, ownVolunteers, crossNgo: false);
    }

    // Expand to 50 km and retry within own NGO
    final ownExpanded = await _fetchAvailableVolunteers(
      ngoId: need.ngoId,
      needLat: need.lat,
      needLng: need.lng,
      radiusKm: AppConstants.expandedMatchingRadiusKm,
      requireCrossNgoConsent: false,
    );

    if (ownExpanded.isNotEmpty) {
      return _runGeminiMatch(need, ownExpanded, crossNgo: false);
    }

    // ── Step 2: Cross-NGO escalation ──────────────────────────────────────────
    debugPrint('[Matching] No own-NGO volunteers. Escalating cross-NGO...');
    final partnerVolunteers = await _fetchCrossNgoVolunteers(need);

    if (partnerVolunteers.isEmpty) {
      throw Exception('No volunteers available — even from partner NGOs. Try again later.');
    }

    return _runGeminiMatch(need, partnerVolunteers, crossNgo: true);
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> _fetchAvailableVolunteers({
    required String ngoId,
    required double needLat,
    required double needLng,
    required double radiusKm,
    required bool requireCrossNgoConsent,
  }) async {
    Query query = _db
        .collection(AppConstants.volunteersCollection)
        .where('isAvailable', isEqualTo: true)
        .where('primaryNgoId', isEqualTo: ngoId);

    final snap = await query.get();
    final cutoff = DateTime.now().subtract(AppConstants.staleLocationThreshold);

    final results = <Map<String, dynamic>>[];
    for (final doc in snap.docs) {
      final data = doc.data() as Map<String, dynamic>;

      // Skip stale locations
      final updatedAt = (data['locationUpdatedAt'] as Timestamp?)?.toDate();
      if (updatedAt != null && updatedAt.isBefore(cutoff)) continue;

      final volLat = (data['lat'] as num?)?.toDouble() ?? 0.0;
      final volLng = (data['lng'] as num?)?.toDouble() ?? 0.0;
      final distanceKm = DistanceCalculator.distanceInKm(needLat, needLng, volLat, volLng);

      if (distanceKm > radiusKm) continue;
      if (requireCrossNgoConsent) {
        final memberships = (data['ngoMemberships'] as List<dynamic>?) ?? [];
        final hasCrossConsent = memberships.any((m) {
          final map = m as Map<String, dynamic>;
          return map['crossNgoConsent'] == true && map['status'] == 'active';
        });
        if (!hasCrossConsent) continue;
      }

      results.add({
        'uid': doc.id,
        'name': data['name'] ?? '',
        'skills': data['skills'] ?? [],
        'distanceKm': distanceKm.toStringAsFixed(1),
        'activeTasks': data['activeTasks'] ?? 0,
        'ngoId': ngoId,
      });
    }
    return results;
  }

  Future<List<Map<String, dynamic>>> _fetchCrossNgoVolunteers(NeedEntity need) async {
    // Query active partnerships where this NGO is ngoA or ngoB
    final partnershipSnap = await _db
        .collection(AppConstants.partnershipsCollection)
        .where('status', isEqualTo: 'active')
        .get();

    final partnerNgoIds = <String>[];
    for (final doc in partnershipSnap.docs) {
      final data = doc.data();
      final ngoA = data['ngoA'] as String? ?? '';
      final ngoB = data['ngoB'] as String? ?? '';
      final sharedSkills = List<String>.from(data['sharedSkills'] as List? ?? []);

      // Only include if the partnership covers this need type
      if (!sharedSkills.contains(need.needType) && !sharedSkills.contains('OTHER')) continue;

      if (ngoA == need.ngoId && ngoB.isNotEmpty) partnerNgoIds.add(ngoB);
      if (ngoB == need.ngoId && ngoA.isNotEmpty) partnerNgoIds.add(ngoA);
    }

    if (partnerNgoIds.isEmpty) return [];

    final volunteers = <Map<String, dynamic>>[];
    for (final partnerId in partnerNgoIds) {
      final pool = await _fetchAvailableVolunteers(
        ngoId: partnerId,
        needLat: need.lat,
        needLng: need.lng,
        radiusKm: AppConstants.expandedMatchingRadiusKm,
        requireCrossNgoConsent: true,
      );
      for (final v in pool) {
        volunteers.add({...v, 'ngoName': partnerId}); // ngoName enriched later if needed
      }
    }
    return volunteers;
  }

  Future<String> _runGeminiMatch(
    NeedEntity need,
    List<Map<String, dynamic>> volunteers, {
    required bool crossNgo,
  }) async {
    final result = await _gemini.matchVolunteer(
      needType: need.needType,
      lat: need.lat,
      lng: need.lng,
      urgencyScore: need.urgencyScore,
      description: need.rawText,
      volunteersJson: volunteers,
      crossNgo: crossNgo,
    );

    final matchedUid = result['matchedVolunteerUid'] as String? ?? '';
    final reason = result['reason'] as String? ?? '';

    // Guard: make sure UID is actually in our list
    final validUids = volunteers.map((v) => v['uid'] as String).toSet();
    if (!validUids.contains(matchedUid)) {
      throw Exception('Gemini returned an invalid volunteer UID. Please retry.');
    }

    await _db.runTransaction((tx) async {
      final needRef = _db.collection(AppConstants.needsCollection).doc(need.id);
      final volRef = _db.collection(AppConstants.volunteersCollection).doc(matchedUid);
      final volSnap = await tx.get(volRef);
      final currentTasks = (volSnap.data()?['activeTasks'] as num?)?.toInt() ?? 0;

      tx.update(needRef, {
        'status': AppConstants.statusAssigned,
        'assignedTo': matchedUid,
        'matchReason': reason,
        if (crossNgo) 'crossNgoTaskId': const Uuid().v4(),
      });
      tx.update(volRef, {'activeTasks': currentTasks + 1});

      // If cross-NGO, write to crossNgoTasks collection
      if (crossNgo) {
        final matchedVol = volunteers.firstWhere((v) => v['uid'] == matchedUid);
        final crossTaskId = const Uuid().v4();
        final crossRef = _db.collection(AppConstants.crossNgoTasksCollection).doc(crossTaskId);
        tx.set(crossRef, CrossNgoTaskModel(
          id: crossTaskId,
          needId: need.id,
          sourceNgoId: need.ngoId,
          volunteerNgoId: matchedVol['ngoId'] as String? ?? '',
          volunteerUid: matchedUid,
          volunteerConsentGiven: true,
          status: CrossNgoTaskStatus.accepted,
        ).toJson());

        // Batch: set isAvailable=false across all NGO memberships
        final memberships = (volSnap.data()?['ngoMemberships'] as List<dynamic>?) ?? [];
        final updatedMemberships = memberships.map((m) {
          final map = Map<String, dynamic>.from(m as Map<String, dynamic>);
          map['status'] = 'busy';
          return map;
        }).toList();
        tx.update(volRef, {
          'isAvailable': false,
          'ngoMemberships': updatedMemberships,
        });
      }
    });

    return matchedUid;
  }
}
