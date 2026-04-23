import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../auth/domain/entities/volunteer.dart';
import '../../domain/entities/join_request_entity.dart';

final joinRequestDatasourceProvider = Provider<JoinRequestDatasource>((ref) {
  return JoinRequestDatasource();
});

class JoinRequestDatasource {
  final FirebaseFirestore _firestore;

  JoinRequestDatasource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Sends a join request. Prevents duplicates (same user + same NGO).
  Future<void> sendJoinRequest(JoinRequest request) async {
    // Check for existing pending request
    final existing = await _firestore
        .collection(AppConstants.joinRequestsCollection)
        .where('userId', isEqualTo: request.userId)
        .where('ngoId', isEqualTo: request.ngoId)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception('You already have a pending request for this NGO');
    }

    await _firestore
        .collection(AppConstants.joinRequestsCollection)
        .add(request.toJson());
  }

  /// Streams pending requests for an NGO (for admin approval UI).
  Stream<List<JoinRequest>> streamPendingRequests(String ngoId) {
    return _firestore
        .collection(AppConstants.joinRequestsCollection)
        .where('ngoId', isEqualTo: ngoId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => JoinRequest.fromJson(doc.data(), doc.id))
            .toList());
  }

  /// Streams all requests by a specific user (for "My Requests" UI).
  Stream<List<JoinRequest>> streamMyRequests(String userId) {
    return _firestore
        .collection(AppConstants.joinRequestsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => JoinRequest.fromJson(doc.data(), doc.id))
            .toList());
  }

  /// Approves a join request using a Firestore transaction for atomicity.
  /// Updates: request status + volunteer's ngoMemberships + NGO volunteerCount.
  Future<void> approveRequest(JoinRequest request) async {
    await _firestore.runTransaction((txn) async {
      // 1. Read the request doc to verify it's still pending
      final requestRef = _firestore
          .collection(AppConstants.joinRequestsCollection)
          .doc(request.id);
      final requestSnap = await txn.get(requestRef);

      if (!requestSnap.exists) throw Exception('Request no longer exists');
      if (requestSnap.data()?['status'] != 'pending') {
        throw Exception('Request already processed');
      }

      // 2. Read the volunteer doc
      final volunteerRef = _firestore
          .collection(AppConstants.volunteersCollection)
          .doc(request.userId);
      final volunteerSnap = await txn.get(volunteerRef);

      if (!volunteerSnap.exists) throw Exception('Volunteer not found');

      // 3. Build updated membership
      final newMembership = NgoMembership(
        ngoId: request.ngoId,
        role: 'VL',
        crossNgoConsent: false,
        status: 'active',
      );

      final existingMemberships =
          (volunteerSnap.data()?['ngoMemberships'] as List<dynamic>?)
                  ?.map((m) =>
                      NgoMembership.fromJson(m as Map<String, dynamic>).toJson())
                  .toList() ??
              [];
      existingMemberships.add(newMembership.toJson());

      // Determine the new primary NGO (set if currently empty)
      final currentPrimary =
          volunteerSnap.data()?['primaryNgoId'] as String? ?? '';

      // Determine role upgrade: CU → VL
      final currentRole =
          volunteerSnap.data()?['platformRole'] as String? ?? 'CU';
      final newRole = (currentRole == 'CU') ? 'VL' : currentRole;

      // 4. Atomically update all documents
      txn.update(requestRef, {'status': 'approved'});
      txn.update(volunteerRef, {
        'ngoMemberships': existingMemberships,
        'primaryNgoId':
            currentPrimary.isEmpty ? request.ngoId : currentPrimary,
        'platformRole': newRole,
      });

      // 5. Increment NGO volunteer count
      final ngoRef = _firestore
          .collection(AppConstants.ngosCollection)
          .doc(request.ngoId);
      txn.update(ngoRef, {
        'volunteerCount': FieldValue.increment(1),
      });
    });
  }

  /// Rejects a join request with an optional reason.
  Future<void> rejectRequest(String requestId, {String? reason}) async {
    await _firestore
        .collection(AppConstants.joinRequestsCollection)
        .doc(requestId)
        .update({
      'status': 'rejected',
      'rejectionReason': reason ?? '',
    });
  }
}
