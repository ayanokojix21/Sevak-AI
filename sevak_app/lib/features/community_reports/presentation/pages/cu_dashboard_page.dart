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
    final cs = Theme.of(context).colorScheme;
    final reportsAsync = ref.watch(myCommunityReportsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reports'),
        actions: [
          FilledButton.icon(
            onPressed: () => context.push('/submit-community-report'),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('New Report'),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign out',
            onPressed: () {
              ref.read(authControllerProvider.notifier).signOut();
            },
          ),
        ],
      ),
      body: reportsAsync.when(
        data: (reports) {
          if (reports.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: cs.onSurfaceVariant),
                  const SizedBox(height: 16),
                  Text('You haven\'t submitted any reports yet.',
                      style: TextStyle(color: cs.onSurfaceVariant)),
                ],
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
    );
  }
}

class _ReportCard extends ConsumerWidget {
  final CommunityReportEntity report;

  const _ReportCard({required this.report});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isPending = report.status == 'PENDING_APPROVAL';

    return Card(
      color: cs.surfaceContainerLow,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(report.needType,
                      style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPending
                        ? SevakColors.warning.withAlpha(50)
                        : SevakColors.success.withAlpha(50),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    report.status,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isPending ? SevakColors.warning : SevakColors.success,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(report.rawText,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: tt.bodyMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: cs.onSurfaceVariant),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    report.location,
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
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
                    return Text('Emergency details not found.',
                        style: TextStyle(color: cs.error));
                  }

                  if (need.status == 'CLOSED') {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: SevakColors.success.withAlpha(20),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: SevakColors.success.withAlpha(50)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, color: SevakColors.success, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Emergency Resolved & Closed',
                            style: TextStyle(
                                color: SevakColors.success, fontWeight: FontWeight.bold),
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
                            color: SevakColors.warning.withAlpha(20),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: SevakColors.warning.withAlpha(50)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: SevakColors.warning, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Volunteer marked this as resolved. Please verify and close.',
                                  style: TextStyle(
                                      color: SevakColors.warning,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12),
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
                                  backgroundColor: cs.surfaceContainerHighest,
                                  foregroundColor: cs.onSurfaceVariant,
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
                                    content: const Text(
                                        'Are you sure you want to close this emergency? This action cannot be undone.'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, true),
                                        child: Text('Close Emergency',
                                            style: TextStyle(color: cs.error)),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await ref
                                      .read(needsFirestoreProvider)
                                      .updateNeedStatus(need.id, 'CLOSED');
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('Emergency Closed successfully.')),
                                    );
                                  }
                                }
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: cs.errorContainer,
                                foregroundColor: cs.onErrorContainer,
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
      ),
    );
  }
}
