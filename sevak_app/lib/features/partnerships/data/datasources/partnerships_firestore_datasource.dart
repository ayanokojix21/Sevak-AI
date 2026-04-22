import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/partnership_model.dart';
import '../models/cross_ngo_task_model.dart';

class PartnershipsFirestoreDatasource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- Partnerships ---
  
  Future<void> createPartnership(PartnershipModel model) async {
    await _firestore.collection('partnerships').doc(model.id).set(model.toJson());
  }

  Future<void> updatePartnershipStatus(String id, String status) async {
    await _firestore.collection('partnerships').doc(id).update({'status': status});
  }

  Stream<List<PartnershipModel>> watchPartnershipsForNgo(String ngoId) {
    return _firestore
        .collection('partnerships')
        .where(
          Filter.or(
            Filter('ngoA', isEqualTo: ngoId),
            Filter('ngoB', isEqualTo: ngoId),
          ),
        )
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PartnershipModel.fromJson(doc.data(), doc.id))
            .toList());
  }

  // --- Cross-NGO Tasks ---

  Future<void> createCrossNgoTask(CrossNgoTaskModel model) async {
    await _firestore.collection('crossNgoTasks').doc(model.id).set(model.toJson());
  }

  Future<void> updateCrossNgoTaskStatus(String id, String status) async {
    await _firestore.collection('crossNgoTasks').doc(id).update({'status': status});
  }

  Future<void> updateVolunteerConsent(String id, bool consent, String volunteerUid) async {
    await _firestore.collection('crossNgoTasks').doc(id).update({
      'volunteerConsentGiven': consent,
      'volunteerUid': volunteerUid,
    });
  }
}
