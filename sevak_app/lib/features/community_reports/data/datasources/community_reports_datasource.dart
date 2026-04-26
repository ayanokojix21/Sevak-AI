import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../models/community_report_model.dart';
import '../../domain/entities/community_report_entity.dart';

final communityReportsDatasourceProvider =
    Provider<CommunityReportsDatasource>((ref) {
  return CommunityReportsDatasource(FirebaseFirestore.instance);
});

class CommunityReportsDatasource {
  final FirebaseFirestore _db;

  CommunityReportsDatasource(this._db);

  Future<void> submitReport(CommunityReportModel report) async {
    await _db
        .collection(AppConstants.communityReportsCollection)
        .doc(report.id)
        .set(report.toJson());
  }

  /// Streams reports submitted by a specific user (Community User history).
  Stream<List<CommunityReportEntity>> streamReportsForUser(String uid) {
    return _db
        .collection(AppConstants.communityReportsCollection)
        .where('submittedBy', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => CommunityReportModel.fromJson(doc.data(), doc.id))
            .toList());
  }

  /// Streams PENDING_APPROVAL reports for a specific NGO (NGO admin inbox).
  /// Requires index: communityReports → targetNgoId ASC, status ASC, createdAt DESC
  Stream<List<CommunityReportEntity>> streamPendingReportsForNgo(String ngoId) {
    return _db
        .collection(AppConstants.communityReportsCollection)
        .where('targetNgoId', isEqualTo: ngoId)
        .where('status', isEqualTo: 'PENDING_APPROVAL')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => CommunityReportModel.fromJson(doc.data(), doc.id))
            .toList());
  }

  /// Streams ALL pending reports across the platform (global dashboard).
  /// Requires index: communityReports → status ASC, createdAt DESC
  Stream<List<CommunityReportEntity>> streamAllPendingReports() {
    return _db
        .collection(AppConstants.communityReportsCollection)
        .where('status', isEqualTo: 'PENDING_APPROVAL')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => CommunityReportModel.fromJson(doc.data(), doc.id))
            .toList());
  }

  Future<void> approveReport(String reportId) async {
    await _db
        .collection(AppConstants.communityReportsCollection)
        .doc(reportId)
        .update({'status': 'APPROVED'});
  }

  Future<void> rejectReport(String reportId) async {
    await _db
        .collection(AppConstants.communityReportsCollection)
        .doc(reportId)
        .update({'status': 'REJECTED'});
  }
}
