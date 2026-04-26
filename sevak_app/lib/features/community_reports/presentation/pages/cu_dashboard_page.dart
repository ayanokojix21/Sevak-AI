import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../providers/community_report_providers.dart';
import '../../../../providers/auth_providers.dart';
import '../../domain/entities/community_report_entity.dart';
import '../../../../providers/need_providers.dart';
import '../../../dashboard/presentation/pages/live_tracking_page.dart';

class CuDashboardPage extends ConsumerWidget {
  const CuDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(myCommunityReportsProvider);

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        title: const Text('My Reports'),
        backgroundColor: AppColors.bgBase,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authControllerProvider.notifier).signOut();
            },
          ),
        ],
      ),
      body: reportsAsync.when(
        data: (reports) {
          if (reports.isEmpty) {
            return const Center(
              child: Text(
                'You have not submitted any reports yet.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              return _ReportCard(report: report);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/submit-community-report');
        },
        icon: const Icon(Icons.add),
        label: const Text('Report Emergency'),
        backgroundColor: AppColors.error,
      ),
    );
  }
}

class _ReportCard extends ConsumerWidget {
  final CommunityReportEntity report;

  const _ReportCard({required this.report});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  report.needType,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: report.status == 'PENDING_APPROVAL'
                      ? AppColors.warning.withAlpha(50)
                      : AppColors.success.withAlpha(50),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  report.status,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: report.status == 'PENDING_APPROVAL' ? AppColors.warning : AppColors.success,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(report.rawText, maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  report.location,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (report.status == 'APPROVED') ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  // Fetch the need document directly by ID
                  final needsDs = ref.read(needsFirestoreProvider);
                  final need = await needsDs.getNeedById(report.id);
                  
                  if (!context.mounted) return;
                  
                  if (need == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Could not find the emergency details.')),
                    );
                    return;
                  }

                  if (need.status == 'ASSIGNED' || need.status == 'IN_PROGRESS') {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => LiveTrackingPage(need: need),
                    ));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Volunteer not assigned yet. Please wait.')),
                    );
                  }
                },
                icon: const Icon(Icons.map, size: 18),
                label: const Text('Live Track Response'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
