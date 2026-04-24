import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../needs/data/models/need_model.dart';
import '../../../ngos/data/models/ngo_model.dart';

/// Firestore datasource for all Coordinator Dashboard operations.
/// Handles streaming needs, claiming needs, and fetching NGO data.
class DashboardFirestoreDatasource {
  final FirebaseFirestore _firestore;

  DashboardFirestoreDatasource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Streams ALL needs across the platform (global visibility).
  /// Ordered by creation date, newest first.
  Stream<List<NeedModel>> streamAllNeeds() {
    return _firestore
        .collection(AppConstants.needsCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                NeedModel.fromJson(doc.data(), doc.id))
            .toList());
  }

  /// Streams needs claimed by a specific NGO.
  Stream<List<NeedModel>> streamNgoNeeds(String ngoId) {
    return _firestore
        .collection(AppConstants.needsCollection)
        .where('ngoId', isEqualTo: ngoId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                NeedModel.fromJson(doc.data(), doc.id))
            .toList());
  }

  /// Claims an unclaimed need for the given NGO by updating `ngoId`.
  Future<void> claimNeedForNgo({
    required String needId,
    required String ngoId,
  }) async {
    await _firestore
        .collection(AppConstants.needsCollection)
        .doc(needId)
        .update({'ngoId': ngoId});
  }

  /// Fetches the NGO document associated with a coordinator UID.
  Future<NgoModel?> getNgoByCoordinatorUid(String uid) async {
    final snapshot = await _firestore
        .collection(AppConstants.ngosCollection)
        .where('coordinatorUid', isEqualTo: uid)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    final doc = snapshot.docs.first;
    return NgoModel.fromJson(doc.data(), doc.id);
  }

  /// Fetches NGO name by its document ID.
  Future<String> getNgoName(String ngoId) async {
    if (ngoId.isEmpty) return 'Unclaimed';

    final doc = await _firestore
        .collection(AppConstants.ngosCollection)
        .doc(ngoId)
        .get();

    if (!doc.exists || doc.data() == null) return 'Unknown NGO';
    return doc.data()!['name'] as String? ?? 'Unknown NGO';
  }

  /// Updates the status of a need document.
  Future<void> updateNeedStatus({
    required String needId,
    required String newStatus,
  }) async {
    await _firestore
        .collection(AppConstants.needsCollection)
        .doc(needId)
        .update({'status': newStatus});
  }
}
