import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/need_model.dart';

class NeedsFirestoreDatasource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  static const String _collectionPath = 'needs';

  Future<NeedModel> saveNeed(NeedModel need) async {
    final docRef = _firestore.collection(_collectionPath).doc(need.id);
    await docRef.set(need.toJson());
    return need;
  }

  Stream<List<NeedModel>> streamNeeds({String? ngoId, String? status}) {
    Query query = _firestore.collection(_collectionPath);

    if (ngoId != null && ngoId.isNotEmpty) {
      query = query.where('ngoId', isEqualTo: ngoId);
    }
    
    if (status != null && status.isNotEmpty) {
      query = query.where('status', isEqualTo: status);
    }

    query = query.orderBy('createdAt', descending: true);

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return NeedModel.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }
}
