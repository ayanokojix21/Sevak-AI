import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/community_reports/domain/entities/community_report_entity.dart';
import '../features/community_reports/data/datasources/community_reports_datasource.dart';
import 'auth_providers.dart';

final myCommunityReportsProvider = StreamProvider<List<CommunityReportEntity>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);
  
  final ds = ref.watch(communityReportsDatasourceProvider);
  return ds.streamReportsForUser(user.uid);
});

final pendingCommunityReportsProvider = StreamProvider.family<List<CommunityReportEntity>, String>((ref, ngoId) {
  final ds = ref.watch(communityReportsDatasourceProvider);
  return ds.streamPendingReportsForNgo(ngoId);
});

final globalPendingCommunityReportsProvider = StreamProvider<List<CommunityReportEntity>>((ref) {
  final ds = ref.watch(communityReportsDatasourceProvider);
  return ds.streamAllPendingReports();
});
