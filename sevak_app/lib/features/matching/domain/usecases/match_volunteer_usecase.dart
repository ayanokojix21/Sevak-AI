import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/distance_calculator.dart';
import '../../../needs/domain/entities/need_entity.dart';
import '../../../partnerships/data/models/cross_ngo_task_model.dart';
import '../../../partnerships/domain/entities/cross_ngo_task_entity.dart';
import '../../data/datasources/matching_ai_datasource.dart';

/// Volunteer matching engine with **deterministic pre-scoring** + AI selection.
///
/// Pipeline:
/// 1. Fetch available volunteers within radius
/// 2. Filter out overloaded volunteers (activeTasks >= maxConcurrentTasks)
/// 3. Compute a deterministic pre-score (skill, distance, workload, freshness)
/// 4. Send top candidates to AI for final selection
/// 5. Persist assignment in a Firestore transaction
class MatchVolunteerUseCase {
  final MatchingAiDatasource _ai;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  MatchVolunteerUseCase(this._ai);

  /// Main entry point. Tries single-NGO first, escalates to cross-NGO.
  Future<String> call(NeedEntity need) async {
    final hasNeedLocation = !(need.lat == 0.0 && need.lng == 0.0);
    if (!hasNeedLocation) {
      debugPrint(
        '[Matching] WARNING: Need has no GPS location (0,0). '
        'Will match by NGO membership only — distance scoring disabled.',
      );
    }

    final ownVolunteers = await _fetchAndScoreVolunteers(
      ngoId: need.ngoId,
      needLat: need.lat,
      needLng: need.lng,
      needType: need.needType,
      radiusKm: AppConstants.maxMatchingRadiusKm,
      requireCrossNgoConsent: false,
      rejectedBy: need.rejectedBy,
      submittedBy: need.submittedBy,
      skipDistanceFilter: !hasNeedLocation,
    );

    if (ownVolunteers.isNotEmpty) {
      return _runAiMatch(need, ownVolunteers, crossNgo: false);
    }
    
    if (!hasNeedLocation) {
      // Without coordinates, we cannot expand the radius meaningfully
      throw Exception('No volunteers available for NGO ${need.ngoId}. Try again later.');
    }

    // Expand to 50 km and retry within own NGO
    final ownExpanded = await _fetchAndScoreVolunteers(
      ngoId: need.ngoId,
      needLat: need.lat,
      needLng: need.lng,
      needType: need.needType,
      radiusKm: AppConstants.expandedMatchingRadiusKm,
      requireCrossNgoConsent: false,
      rejectedBy: need.rejectedBy,
      submittedBy: need.submittedBy,
      skipDistanceFilter: false,
    );

    if (ownExpanded.isNotEmpty) {
      return _runAiMatch(need, ownExpanded, crossNgo: false);
    }

    debugPrint('[Matching] No own-NGO volunteers. Escalating cross-NGO...');
    final partnerVolunteers = await _fetchCrossNgoVolunteers(need, need.rejectedBy);

    if (partnerVolunteers.isEmpty) {
      throw Exception('No volunteers available — even from partner NGOs. Try again later.');
    }

    return _runAiMatch(need, partnerVolunteers, crossNgo: true);
  }

  // DETERMINISTIC PRE-SCORING

  /// Computes a 0-100 pre-score for a volunteer candidate.
  ///
  /// Breakdown:
  /// - Skill match: 0-30 pts
  /// - Distance: 0-30 pts (closer = higher)
  /// - Workload: 0-20 pts (fewer tasks = higher)
  /// - Location freshness: 0-20 pts
  int _computePreScore({
    required List<String> skills,
    required String needType,
    required double distanceKm,
    required double radiusKm,
    required int activeTasks,
    required int maxTasks,
    required DateTime? locationUpdatedAt,
  }) {
    // Skill match (0-30)
    int skillScore = 0;
    for (final skill in skills) {
      final normalised = skill.toLowerCase().trim();
      final matchedTypes = AppConstants.skillToNeedTypes[normalised];
      if (matchedTypes != null && matchedTypes.contains(needType)) {
        skillScore = 30;
        break;
      }
    }

    // Distance (0-30) — linear decay from max radius
    final distanceScore = ((1.0 - (distanceKm / radiusKm)).clamp(0.0, 1.0) * 30).round();

    // Workload (0-20) — fewer active tasks = higher score
    final workloadRatio = (1.0 - (activeTasks / maxTasks)).clamp(0.0, 1.0);
    final workloadScore = (workloadRatio * 20).round();

    // Location freshness (0-20) — more recent = higher
    int freshnessScore = 10; // Default if no timestamp
    if (locationUpdatedAt != null) {
      final ageMinutes = DateTime.now().difference(locationUpdatedAt).inMinutes;
      if (ageMinutes < 15) {
        freshnessScore = 20;
      } else if (ageMinutes < 60) {
        freshnessScore = 15;
      } else if (ageMinutes < 120) {
        freshnessScore = 10;
      } else {
        freshnessScore = 5;
      }
    }

    return skillScore + distanceScore + workloadScore + freshnessScore;
  }

  // DATA FETCHING

  Future<List<Map<String, dynamic>>> _fetchAndScoreVolunteers({
    required String ngoId,
    required double needLat,
    required double needLng,
    required String needType,
    required double radiusKm,
    required bool requireCrossNgoConsent,
    required List<String> rejectedBy,
    required String submittedBy,
    bool skipDistanceFilter = false,
  }) async {
    // Build query — if ngoId is empty/unassigned, query all available volunteers
    // (handles CU-submitted needs which have no NGO affiliation)
    final Query query = ngoId.isNotEmpty && ngoId != 'unassigned'
        ? _db
            .collection(AppConstants.volunteersCollection)
            .where('isAvailable', isEqualTo: true)
            .where('primaryNgoId', isEqualTo: ngoId)
        : _db
            .collection(AppConstants.volunteersCollection)
            .where('isAvailable', isEqualTo: true);

    final snap = await query.get();
    final cutoff = DateTime.now().subtract(AppConstants.staleLocationThreshold);

    final results = <Map<String, dynamic>>[];
    debugPrint('[Matching] Found ${snap.docs.length} active volunteers for NGO "$ngoId" before filtering.');
    
    for (final doc in snap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final uid = doc.id;

      // Skip the community user who submitted this need — never assign to yourself
      if (uid == submittedBy && submittedBy.isNotEmpty) {
        debugPrint('[Matching] Skipping $uid: Is the submitter of this need.');
        continue;
      }

      // Skip community users (CU role) — they are not trained volunteers
      final platformRole = data['platformRole'] as String? ?? 'VL';
      if (platformRole == 'CU') {
        debugPrint('[Matching] Skipping $uid: Community User (CU), not a volunteer.');
        continue;
      }

      // Skip volunteers who already rejected this specific need
      if (rejectedBy.contains(uid)) {
        debugPrint('[Matching] Skipping $uid: Already rejected this need.');
        continue;
      }

      final updatedAt = (data['locationUpdatedAt'] as Timestamp?)?.toDate();

      // Only skip if location is explicitly stale (older than threshold).
      // A null updatedAt means new volunteer — don't punish them, let distance check handle it.
      if (updatedAt != null && updatedAt.isBefore(cutoff)) {
        debugPrint('[Matching] Skipping $uid: Stale location ($updatedAt)');
        continue;
      }

      final volLat = (data['currentLat'] as num?)?.toDouble() ?? 0.0;
      final volLng = (data['currentLng'] as num?)?.toDouble() ?? 0.0;

      // If the need has valid coordinates, require the volunteer to also have location.
      // If neither has coords (both 0,0), fall back to NGO-wide matching without distance.
      final volHasLocation = !(volLat == 0.0 && volLng == 0.0);
      if (!volHasLocation && !skipDistanceFilter) {
        debugPrint('[Matching] Skipping $uid: No location data (0.0, 0.0) and distance filter active.');
        continue;
      }

      if (!skipDistanceFilter && volHasLocation) {
        final distanceKm = DistanceCalculator.distanceInKm(needLat, needLng, volLat, volLng);
        if (distanceKm > radiusKm) {
          debugPrint('[Matching] Skipping $uid: Too far (${distanceKm.toStringAsFixed(1)}km > ${radiusKm}km).');
          continue;
        }
      }

      // Cross-NGO consent check
      if (requireCrossNgoConsent) {
        final memberships = (data['ngoMemberships'] as List<dynamic>?) ?? [];
        final hasCrossConsent = memberships.any((m) {
          final map = m as Map<String, dynamic>;
          return map['crossNgoConsent'] == true && map['status'] == 'active';
        });
        if (!hasCrossConsent) {
          debugPrint('[Matching] Skipping $uid: No cross-NGO consent');
          continue;
        }
      }

      final skills = List<String>.from(data['skills'] as Iterable? ?? []);
      final activeTasks = (data['activeTasks'] as num?)?.toInt() ?? 0;
      final maxTasks = (data['maxConcurrentTasks'] as num?)?.toInt() ?? AppConstants.defaultMaxConcurrentTasks;

      // Skip overloaded volunteers
      if (activeTasks >= maxTasks) {
        debugPrint('[Matching] Skipping $uid: Overloaded ($activeTasks >= $maxTasks)');
        continue;
      }

      debugPrint('[Matching] Volunteer $uid PASSED all filters!');
      final effectiveDistanceKm = volHasLocation
          ? DistanceCalculator.distanceInKm(needLat, needLng, volLat, volLng)
          : 0.0; // Unknown distance — score neutrally
      final preScore = _computePreScore(
        skills: skills,
        needType: needType,
        distanceKm: effectiveDistanceKm,
        radiusKm: radiusKm,
        activeTasks: activeTasks,
        maxTasks: maxTasks,
        locationUpdatedAt: updatedAt,
      );

      results.add({
        'uid': doc.id,
        'name': data['name'] ?? '',
        'skills': skills,
        'languages': List<String>.from(data['languages'] as Iterable? ?? []),
        'distanceKm': double.parse(effectiveDistanceKm.toStringAsFixed(1)),
        'activeTasks': activeTasks,
        'maxConcurrentTasks': maxTasks,
        'preScore': preScore,
        'ngoId': ngoId,
      });
    }

    // Sort by pre-score descending — AI sees best candidates first
    results.sort((a, b) => (b['preScore'] as int).compareTo(a['preScore'] as int));
    return results;
  }

  Future<List<Map<String, dynamic>>> _fetchCrossNgoVolunteers(NeedEntity need, List<String> rejectedBy) async {
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
      final pool = await _fetchAndScoreVolunteers(
        ngoId: partnerId,
        needLat: need.lat,
        needLng: need.lng,
        needType: need.needType,
        radiusKm: AppConstants.expandedMatchingRadiusKm,
        requireCrossNgoConsent: true,
        rejectedBy: rejectedBy,
        submittedBy: need.submittedBy,
      );
      for (final v in pool) {
        volunteers.add({...v, 'ngoName': partnerId});
      }
    }

    // Re-sort combined pool by pre-score
    volunteers.sort((a, b) => (b['preScore'] as int).compareTo(a['preScore'] as int));
    return volunteers;
  }

  // AI MATCH + FIRESTORE TRANSACTION

  Future<String> _runAiMatch(
    NeedEntity need,
    List<Map<String, dynamic>> volunteers, {
    required bool crossNgo,
  }) async {
    // 1. Calculate required volunteers heuristically
    int requiredVolunteers = (need.peopleAffected / 5).ceil();
    if (requiredVolunteers < 1) requiredVolunteers = 1;
    if (need.urgencyScore >= 80) requiredVolunteers *= 2;
    
    // Cap at a reasonable limit
    final cap = need.urgencyScore >= 80 ? 10 : 5;
    if (requiredVolunteers > cap) requiredVolunteers = cap;
    
    // Do not request more than available
    if (requiredVolunteers > volunteers.length) {
      requiredVolunteers = volunteers.length;
    }

    final result = await _ai.matchVolunteer(
      needType: need.needType,
      lat: need.lat,
      lng: need.lng,
      urgencyScore: need.urgencyScore,
      description: need.rawText,
      volunteersJson: volunteers,
      requiredVolunteerCount: requiredVolunteers,
      crossNgo: crossNgo,
    );

    final matchedUidsRaw = result['matchedVolunteerUids'];
    final matchedUids = (matchedUidsRaw as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    final reason = result['reason'] as String? ?? '';

    if (matchedUids.isEmpty) {
      throw Exception('AI failed to select any volunteers. Please retry.');
    }

    // Guard: make sure UIDs are actually in our list
    final validUids = volunteers.map((v) => v['uid'] as String).toSet();
    final finalUids = matchedUids.where((uid) => validUids.contains(uid)).toList();
    if (finalUids.isEmpty) {
      throw Exception('AI returned invalid volunteer UIDs. Please retry.');
    }

    await _db.runTransaction((tx) async {
      final needRef = _db.collection(AppConstants.needsCollection).doc(need.id);

      final needSnap = await tx.get(needRef);
      if (!needSnap.exists) {
        throw Exception('Need ${need.id} no longer exists.');
      }
      // Bail if already assigned by a concurrent call
      if ((needSnap.data()?['status'] as String?) == AppConstants.statusAssigned) {
        throw Exception('Need ${need.id} is already assigned by a concurrent process.');
      }

      final volSnaps = <String, DocumentSnapshot>{};
      for (final uid in finalUids) {
        final volRef = _db.collection(AppConstants.volunteersCollection).doc(uid);
        volSnaps[uid] = await tx.get(volRef);
      }

      for (final uid in finalUids) {
        final volRef = _db.collection(AppConstants.volunteersCollection).doc(uid);
        final volSnap = volSnaps[uid]!;
        final currentTasks = (volSnap.data() as Map<String, dynamic>?)?['activeTasks'];
        final taskCount = (currentTasks as num?)?.toInt() ?? 0;
        tx.update(volRef, {'activeTasks': taskCount + 1});

        // If cross-NGO, write to crossNgoTasks collection per volunteer
        if (crossNgo) {
          final matchedVol = volunteers.firstWhere((v) => v['uid'] == uid);
          final crossTaskId = const Uuid().v4();
          final crossRef = _db.collection(AppConstants.crossNgoTasksCollection).doc(crossTaskId);
          tx.set(crossRef, CrossNgoTaskModel(
            id: crossTaskId,
            needId: need.id,
            sourceNgoId: need.ngoId,
            volunteerNgoId: matchedVol['ngoId'] as String? ?? '',
            volunteerUid: uid,
            volunteerConsentGiven: true,
            status: CrossNgoTaskStatus.accepted,
          ).toJson());

          // Set volunteer as busy across all NGO memberships
          final memberships = (volSnap.data() as Map<String, dynamic>?)?['ngoMemberships'] as List<dynamic>? ?? [];
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
      }

      tx.update(needRef, {
        'status': AppConstants.statusAssigned,
        'assignedTo': finalUids.first,       // Legacy single-volunteer fallback
        'assignedVolunteerIds': finalUids,
        'matchReason': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    return finalUids.first;
  }
}
