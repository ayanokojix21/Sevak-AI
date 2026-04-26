import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/invite_code_entity.dart';



class InviteCodesDatasource {
  final FirebaseFirestore _firestore;

  InviteCodesDatasource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Generates a cryptographically secure 6-character invite code.
  Future<InviteCodeEntity> generateInviteCode(
      String ngoId, String targetRole, bool isSingleUse) async {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    final code = List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();

    final entity = InviteCodeEntity(
      code: code,
      ngoId: ngoId,
      targetRole: targetRole,
      isSingleUse: isSingleUse,
    );

    await _firestore
        .collection(AppConstants.ngoInvitesCollection)
        .doc(code)
        .set(entity.toJson());
    return entity;
  }

  Future<InviteCodeEntity?> getInviteCode(String code) async {
    final doc = await _firestore
        .collection(AppConstants.ngoInvitesCollection)
        .doc(code)
        .get();
    if (doc.exists && doc.data() != null) {
      return InviteCodeEntity.fromJson(doc.data()!);
    }
    return null;
  }

  Future<void> deleteInviteCode(String code) async {
    await _firestore
        .collection(AppConstants.ngoInvitesCollection)
        .doc(code)
        .delete();
  }
}
