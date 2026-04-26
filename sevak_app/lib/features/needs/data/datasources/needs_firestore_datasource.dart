import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/need_model.dart';

final needsFirestoreDatasourceProvider = Provider((ref) => NeedsFirestoreDatasource());

class NeedsFirestoreDatasource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<NeedModel> saveNeed(NeedModel need) async {
    final docRef = _firestore
        .collection(AppConstants.needsCollection)
        .doc(need.id);
    await docRef.set(need.toJson());
    return need;
  }

  Future<NeedModel?> getNeedById(String needId) async {
    final doc = await _firestore.collection(AppConstants.needsCollection).doc(needId).get();
    if (!doc.exists) return null;
    return NeedModel.fromJson(doc.data()!, doc.id);
  }

  /// Streams needs filtered by optional [ngoId] and [status].
  /// Note: Firestore requires a composite index when both filters are active.
  /// Single-filter queries fall back gracefully to ordering by createdAt only.
  Stream<List<NeedModel>> streamNeeds({String? ngoId, String? status}) {
    Query<Map<String, dynamic>> query =
        _firestore.collection(AppConstants.needsCollection);

    if (ngoId != null && ngoId.isNotEmpty) {
      query = query.where('ngoId', isEqualTo: ngoId);
    }
    if (status != null && status.isNotEmpty) {
      query = query.where('status', isEqualTo: status);
    }

    query = query.orderBy('createdAt', descending: true);

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => NeedModel.fromJson(doc.data(), doc.id))
        .toList());
  }

  /// Convenience alias: stream all needs for a specific NGO.
  Stream<List<NeedModel>> streamNgoNeeds(String ngoId) =>
      streamNeeds(ngoId: ngoId);
}
