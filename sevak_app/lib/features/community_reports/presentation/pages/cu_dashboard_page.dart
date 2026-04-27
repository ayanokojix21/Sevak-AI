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
            StreamBuilder(
              stream: ref.watch(needsFirestoreProvider).streamNeedById(report.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final need = snapshot.data;
                if (need == null) {
                  return const Text('Emergency details not found.', style: TextStyle(color: AppColors.error));
                }

                if (need.status == 'CLOSED') {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.success.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.success.withAlpha(50)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: AppColors.success, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Emergency Resolved & Closed',
                          style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    if (need.status == 'COMPLETED') ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withAlpha(20),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.warning.withAlpha(50)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, color: AppColors.warning, size: 18),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Volunteer marked this as resolved. Please verify and close.',
                                style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.w600, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    Row(
                      children: [
                        if (need.status == 'ASSIGNED' || need.status == 'IN_PROGRESS') ...[
                          Expanded(
                            flex: 2,
                            child: FilledButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(MaterialPageRoute(
                                  builder: (context) => LiveTrackingPage(need: need),
                                ));
                              },
                              icon: const Icon(Icons.map, size: 18),
                              label: const Text('Live Track'),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        if (need.status == 'SCORED') ...[
                          Expanded(
                            flex: 2,
                            child: FilledButton.icon(
                              onPressed: null,
                              icon: const Icon(Icons.search, size: 18),
                              label: const Text('Finding Volunteer...'),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.border,
                                foregroundColor: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          flex: 1,
                          child: FilledButton(
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Close Emergency?'),
                                  content: const Text('Are you sure you want to close this emergency? This action cannot be undone.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text('Close Emergency', style: TextStyle(color: AppColors.error)),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await ref.read(needsFirestoreProvider).updateNeedStatus(need.id, 'CLOSED');
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Emergency Closed successfully.')),
                                  );
                                }
                              }
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.error.withAlpha(20),
                              foregroundColor: AppColors.error,
                              padding: EdgeInsets.zero,
                            ),
                            child: const Text('Close'),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
