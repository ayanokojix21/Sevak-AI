import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sevak_app/features/auth/domain/entities/invite_code_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final inviteCodeDatasourceProvider = Provider<InviteCodesDatasource>((ref) {
  return InviteCodesDatasource();
});

class InviteCodesDatasource {
  final FirebaseFirestore _firestore;

  InviteCodesDatasource({FirebaseFirestore? firestore}) 
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<InviteCodeEntity> generateInviteCode(String ngoId, String targetRole, bool isSingleUse) async {
    // Generate a random 6-character alphanumeric code
    final chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = (List.generate(6, (index) => chars[(DateTime.now().microsecondsSinceEpoch + index) % chars.length])).join();

    final entity = InviteCodeEntity(
      code: random,
      ngoId: ngoId,
      targetRole: targetRole,
      isSingleUse: isSingleUse,
    );

    await _firestore.collection('ngoInvites').doc(random).set(entity.toJson());
    return entity;
  }

  Future<InviteCodeEntity?> getInviteCode(String code) async {
    final doc = await _firestore.collection('ngoInvites').doc(code).get();
    if (doc.exists && doc.data() != null) {
      return InviteCodeEntity.fromJson(doc.data()!);
    }
    return null;
  }

  Future<void> deleteInviteCode(String code) async {
    await _firestore.collection('ngoInvites').doc(code).delete();
  }
}
