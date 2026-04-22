import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ngo_model.dart';

class NgosFirestoreDatasource {
  final FirebaseFirestore _firestore;

  NgosFirestoreDatasource({FirebaseFirestore? firestore}) 
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<List<NgoModel>> streamPendingNgos() {
    return _firestore
        .collection('ngos')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NgoModel.fromJson(doc.data(), doc.id))
            .toList());
  }

  Stream<List<NgoModel>> streamActiveNgos() {
    return _firestore
        .collection('ngos')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NgoModel.fromJson(doc.data(), doc.id))
            .toList());
  }

  Future<void> updateNgoStatus(String ngoId, String status) async {
    await _firestore.collection('ngos').doc(ngoId).update({'status': status});
  }
}
