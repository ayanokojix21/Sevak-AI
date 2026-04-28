import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../providers/community_report_providers.dart';
import '../../../../providers/auth_providers.dart';
import '../../domain/entities/community_report_entity.dart';
import '../../../../providers/need_providers.dart';
import '../../../dashboard/presentation/pages/live_tracking_page.dart';
import '../../../needs/data/models/need_model.dart';

// ─── Status pipeline definition ───────────────────────────────────────────────
// Each step has a label, icon, and the set of report/need statuses that map to it.

class _Step {
  final String label;
  final IconData icon;
  const _Step(this.label, this.icon);
}

const _steps = [
  _Step('Submitted', Icons.upload_file_rounded),
  _Step('Under Review', Icons.manage_search_rounded),
  _Step('Approved', Icons.verified_rounded),
  _Step('Volunteer Found', Icons.person_search_rounded),
  _Step('In Progress', Icons.directions_run_rounded),
  _Step('Resolved', Icons.check_circle_rounded),
];

/// Returns the active step index (0-based) for the combined report + need status.
int _activeStep(String reportStatus, String? needStatus) {
  if (reportStatus == 'PENDING_APPROVAL') return 1; // under review
  if (reportStatus == 'REJECTED') return 1;          // stuck at review (rejected)
  // APPROVED — now track the need doc
  if (needStatus == null || needStatus == 'RAW' || needStatus == 'SCORED') return 3;
  if (needStatus == 'ASSIGNED') return 3;
  if (needStatus == 'IN_PROGRESS') return 4;
  if (needStatus == 'COMPLETED' || needStatus == 'CLOSED') return 5;
  return 2; // APPROVED but need not yet found
}


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
            onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
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
                  Icon(Icons.inbox_outlined, size: 72, color: cs.onSurfaceVariant),
                  const SizedBox(height: 16),
                  Text(
                    'No reports yet',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: cs.onSurface),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap "New Report" to submit your first emergency.',
                    style: TextStyle(color: cs.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => context.push('/submit-community-report'),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Submit a Report'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            itemCount: reports.length,
            itemBuilder: (context, index) => _ReportCard(
              report: reports[index],
            ).animate().fadeIn(delay: (60 * index).ms, duration: 300.ms).slideY(begin: 0.08),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

// ─── Report Card ──────────────────────────────────────────────────────────────

class _ReportCard extends ConsumerWidget {
  final CommunityReportEntity report;
  const _ReportCard({required this.report});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isApproved = report.status == 'APPROVED';
    final isRejected = report.status == 'REJECTED';

    return Card(
      color: cs.surfaceContainerLow,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isRejected
              ? cs.error.withAlpha(80)
              : cs.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ──────────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Need-type icon container
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _needTypeColor(report.needType, cs).withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _needTypeIcon(report.needType),
                    color: _needTypeColor(report.needType, cs),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.needType,
                        style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.location_on_rounded, size: 12, color: cs.onSurfaceVariant),
                          const SizedBox(width: 2),
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
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Urgency badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _urgencyColor(report.urgencyScore).withAlpha(30),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _urgencyColor(report.urgencyScore).withAlpha(80)),
                  ),
                  child: Text(
                    '${report.urgencyScore}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _urgencyColor(report.urgencyScore),
                    ),
                  ),
                ),
              ],
            ),

            // ── Description ─────────────────────────────────────────────────
            const SizedBox(height: 10),
            Text(
              report.rawText,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),

            const SizedBox(height: 16),
            Divider(color: cs.outlineVariant, height: 1),
            const SizedBox(height: 16),

            // ── Status tracker ──────────────────────────────────────────────
            if (isRejected)
              _RejectedBanner(cs: cs)
            else if (!isApproved)
              _StatusStepper(activeStep: 1, needStatus: null, rejected: false)
            else
              _NeedStatusTracker(reportId: report.id, ref: ref, cs: cs),
          ],
        ),
      ),
    );
  }

  Color _urgencyColor(int score) {
    if (score >= 80) return SevakColors.urgencyCritical;
    if (score >= 50) return SevakColors.urgencyUrgent;
    return SevakColors.urgencyModerate;
  }

  IconData _needTypeIcon(String type) {
    switch (type.toUpperCase()) {
      case 'MEDICAL': return Icons.local_hospital_rounded;
      case 'FOOD': return Icons.fastfood_rounded;
      case 'SHELTER': return Icons.home_rounded;
      case 'CLOTHING': return Icons.checkroom_rounded;
      default: return Icons.report_problem_rounded;
    }
  }

  Color _needTypeColor(String type, ColorScheme cs) {
    switch (type.toUpperCase()) {
      case 'MEDICAL': return SevakColors.urgencyCritical;
      case 'FOOD': return SevakColors.urgencyUrgent;
      case 'SHELTER': return SevakColors.info;
      case 'CLOTHING': return const Color(0xFF9C27B0);
      default: return cs.primary;
    }
  }
}

// ─── Rejected Banner ──────────────────────────────────────────────────────────

class _RejectedBanner extends StatelessWidget {
  final ColorScheme cs;
  const _RejectedBanner({required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.cancel_rounded, color: cs.onErrorContainer, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Your report was not approved. Please re-submit with more details or a photo.',
              style: TextStyle(color: cs.onErrorContainer, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Need Status Tracker (when APPROVED) ─────────────────────────────────────

class _NeedStatusTracker extends ConsumerWidget {
  final String reportId;
  final WidgetRef ref;
  final ColorScheme cs;

  const _NeedStatusTracker({
    required this.reportId,
    required this.ref,
    required this.cs,
  });

  @override
  Widget build(BuildContext context, WidgetRef widgetRef) {
    return StreamBuilder<NeedModel?>(
      stream: widgetRef.watch(needsFirestoreProvider).streamNeedById(reportId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        final need = snapshot.data;
        final needStatus = need?.status;
        final activeStep = _activeStep('APPROVED', needStatus);
        final isResolved = needStatus == 'COMPLETED' || needStatus == 'CLOSED';
        final isInProgress = needStatus == 'IN_PROGRESS' || needStatus == 'ASSIGNED';
        final isCompleted = needStatus == 'COMPLETED';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status stepper
            _StatusStepper(activeStep: activeStep, needStatus: needStatus, rejected: false),

            const SizedBox(height: 16),

            // Action buttons
            if (need != null) ...[
              // Volunteer completed — ask CU to close
              if (isCompleted) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: SevakColors.warning.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: SevakColors.warning.withAlpha(80)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: SevakColors.warning, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Volunteer marked this resolved. Tap "Close" to confirm.',
                          style: TextStyle(
                            color: SevakColors.warning,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Live track + close buttons
              if (!isResolved || isCompleted)
                Row(
                  children: [
                    if (isInProgress) ...[
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(MaterialPageRoute<void>(
                              builder: (_) => LiveTrackingPage(need: need),
                            ));
                          },
                          icon: const Icon(Icons.map_rounded, size: 18),
                          label: const Text('Live Track'),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    if (needStatus == 'SCORED') ...[
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          onPressed: null,
                          icon: const Icon(Icons.search_rounded, size: 18),
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
                      child: _CloseButton(needId: need.id),
                    ),
                  ],
                ),

              // Fully resolved
              if (needStatus == 'CLOSED')
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: SevakColors.success.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: SevakColors.success.withAlpha(80)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_rounded, color: SevakColors.success, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Emergency Resolved & Closed',
                        style: TextStyle(
                          color: SevakColors.success,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        );
      },
    );
  }
}

// ─── Status Stepper Widget ────────────────────────────────────────────────────

class _StatusStepper extends StatelessWidget {
  final int activeStep;   // 0-based index into _steps
  final String? needStatus;
  final bool rejected;

  const _StatusStepper({
    required this.activeStep,
    required this.needStatus,
    required this.rejected,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Report Status',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
        ),
        const SizedBox(height: 12),
        ..._steps.asMap().entries.map((entry) {
          final i = entry.key;
          final step = entry.value;
          final isDone = i < activeStep;
          final isActive = i == activeStep;
          final isFuture = i > activeStep;

          Color dotColor;
          Color lineColor;
          Color labelColor;
          Widget dotChild;

          if (isDone) {
            dotColor = SevakColors.success;
            lineColor = SevakColors.success.withAlpha(80);
            labelColor = cs.onSurface;
            dotChild = const Icon(Icons.check_rounded, size: 14, color: Colors.white);
          } else if (isActive) {
            dotColor = cs.primary;
            lineColor = cs.outlineVariant;
            labelColor = cs.primary;
            dotChild = SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: cs.onPrimary,
              ),
            );
          } else {
            dotColor = cs.outlineVariant;
            lineColor = cs.outlineVariant.withAlpha(60);
            labelColor = cs.onSurfaceVariant;
            dotChild = Icon(step.icon, size: 12, color: cs.onSurfaceVariant);
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dot + vertical line column
              SizedBox(
                width: 28,
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: 400.ms,
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                        boxShadow: isActive
                            ? [BoxShadow(color: cs.primary.withAlpha(60), blurRadius: 8)]
                            : null,
                      ),
                      child: Center(child: dotChild),
                    ),
                    if (i < _steps.length - 1)
                      AnimatedContainer(
                        duration: 400.ms,
                        width: 2,
                        height: 28,
                        color: lineColor,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Label + sublabel
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    top: 4,
                    bottom: i < _steps.length - 1 ? 16 : 0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                          color: isFuture ? cs.onSurfaceVariant : labelColor,
                        ),
                      ),
                      if (isActive) ...[
                        const SizedBox(height: 2),
                        Text(
                          _activeSubLabel(i, needStatus),
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  String _activeSubLabel(int stepIndex, String? needStatus) {
    switch (stepIndex) {
      case 1: return 'NGO coordinator is reviewing your report';
      case 2: return 'Report approved — NGO is on it';
      case 3: return 'Matching you with the best available volunteer...';
      case 4: return 'Volunteer is heading to your location';
      case 5: return 'Emergency has been resolved!';
      default: return '';
    }
  }
}

// ─── Close Button ─────────────────────────────────────────────────────────────

class _CloseButton extends ConsumerWidget {
  final String needId;
  const _CloseButton({required this.needId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    return FilledButton(
      onPressed: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Close Emergency?'),
            content: const Text(
              'Are you sure you want to close this emergency? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('Close', style: TextStyle(color: cs.error)),
              ),
            ],
          ),
        );
        if (confirm == true && context.mounted) {
          await ref.read(needsFirestoreProvider).updateNeedStatus(needId, 'CLOSED');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Emergency closed successfully.')),
            );
          }
        }
      },
      style: FilledButton.styleFrom(
        backgroundColor: cs.errorContainer,
        foregroundColor: cs.onErrorContainer,
      ),
      child: const Text('Close'),
    );
  }
}
