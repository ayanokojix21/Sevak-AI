import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/app_constants.dart';
import '../models/ngo_model.dart';

class NgosFirestoreDatasource {
  final FirebaseFirestore _firestore;

  NgosFirestoreDatasource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<List<NgoModel>> streamPendingNgos() {
    return _firestore
        .collection(AppConstants.ngosCollection)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NgoModel.fromJson(doc.data(), doc.id))
            .toList());
  }

  Stream<List<NgoModel>> streamActiveNgos() {
    return _firestore
        .collection(AppConstants.ngosCollection)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NgoModel.fromJson(doc.data(), doc.id))
            .toList());
  }

  Stream<List<NgoModel>> streamAllNgos() {
    return _firestore
        .collection(AppConstants.ngosCollection)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NgoModel.fromJson(doc.data(), doc.id))
            .toList());
  }

  Future<NgoModel?> getNgoById(String ngoId) async {
    final doc = await _firestore
        .collection(AppConstants.ngosCollection)
        .doc(ngoId)
        .get();
    if (doc.exists && doc.data() != null) {
      return NgoModel.fromJson(doc.data()!, doc.id);
    }
    return null;
  }

  Future<void> updateNgoStatus(String ngoId, String status) async {
    await _firestore
        .collection(AppConstants.ngosCollection)
        .doc(ngoId)
        .update({'status': status});
  }

  /// Approves an NGO and sets the creator as NGO Admin (if not already higher).
  Future<void> approveNgo(String ngoId, String adminUid) async {
    // Read the creator's current profile to avoid downgrading SA → NA
    final volunteerRef = _firestore
        .collection(AppConstants.volunteersCollection)
        .doc(adminUid);
    final volunteerDoc = await volunteerRef.get();
    final currentRole = volunteerDoc.data()?['platformRole'] as String? ?? 'CU';

    // Only upgrade if current role is below NA
    const hierarchy = {'CU': 0, 'VL': 1, 'CO': 2, 'NA': 3, 'SA': 4};
    final shouldUpgrade = (hierarchy[currentRole] ?? 0) < (hierarchy['NA'] ?? 3);

    final batch = _firestore.batch();

    // 1. Activate the NGO
    batch.update(
      _firestore.collection(AppConstants.ngosCollection).doc(ngoId),
      {'status': 'active'},
    );

    // 2. Add membership + conditionally upgrade role
    final updateData = <String, dynamic>{
      'primaryNgoId': ngoId,
      'ngoMemberships': FieldValue.arrayUnion([
        {
          'ngoId': ngoId,
          'role': 'NA',
          'crossNgoConsent': false,
          'status': 'active',
        }
      ]),
    };
    if (shouldUpgrade) {
      updateData['platformRole'] = 'NA';
    }
    batch.update(volunteerRef, updateData);

    await batch.commit();
  }

  /// Updates editable NGO fields (name, description, city).
  Future<void> updateNgoFields(String ngoId, Map<String, dynamic> fields) async {
    await _firestore
        .collection(AppConstants.ngosCollection)
        .doc(ngoId)
        .update(fields);
  }

  /// Streams a single NGO document in real-time.
  Stream<NgoModel?> streamNgoById(String ngoId) {
    return _firestore
        .collection(AppConstants.ngosCollection)
        .doc(ngoId)
        .snapshots()
        .map((doc) => doc.exists && doc.data() != null
            ? NgoModel.fromJson(doc.data()!, doc.id)
            : null);
  }

  /// Disbands (deletes) the NGO document.
  Future<void> disbandNgo(String ngoId) async {
    await _firestore
        .collection(AppConstants.ngosCollection)
        .doc(ngoId)
        .delete();
  }
}
