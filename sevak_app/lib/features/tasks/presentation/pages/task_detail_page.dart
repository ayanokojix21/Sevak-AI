import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../domain/entities/task_entity.dart';
import '../../../../providers/task_providers.dart';

/// Task Detail page — full need info, accept/decline/complete actions, map link.
class TaskDetailPage extends ConsumerWidget {
  final String taskId;
  const TaskDetailPage({super.key, required this.taskId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(myTasksStreamProvider);
    final controller = ref.watch(taskControllerProvider);

    ref.listen<AsyncValue<void>>(taskControllerProvider, (_, next) {
      if (next.hasError) SnackbarUtils.showError(context, next.error.toString());
      if (next.hasValue && !next.isLoading) {
        SnackbarUtils.showSuccess(context, 'Task updated!');
      }
    });

    final task = tasksAsync.maybeWhen(
      data: (tasks) => tasks.where((t) => t.id == taskId).firstOrNull,
      orElse: () => null,
    );

    if (task == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back_ios_new)),
        ),
        body: const Center(
          child: Text('Task not found or already completed.',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    final urgencyColor = task.urgencyScore >= 80
        ? AppColors.error
        : task.urgencyScore >= 50 ? AppColors.warning : AppColors.success;

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        backgroundColor: AppColors.bgBase,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
        title: const Text('Task Details', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: urgencyColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: urgencyColor.withAlpha(80)),
                  ),
                  child: Text(task.needType,
                      style: TextStyle(color: urgencyColor, fontWeight: FontWeight.w700, fontSize: 12)),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.bgElevated,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('Score: ${task.urgencyScore}/100',
                      style: TextStyle(color: urgencyColor, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
                if (task.isCrossNgo) ...[ 
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primary.withAlpha(60)),
                    ),
                    child: Text(
                      'via ${task.sourceNgoName ?? 'Partner NGO'}',
                      style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // ── Description ──────────────────────────────────────────────────
            _InfoCard(
              icon: Icons.description_outlined,
              label: 'Description',
              content: task.description,
            ),
            const SizedBox(height: 12),

            // ── Location ─────────────────────────────────────────────────────
            _InfoCard(
              icon: Icons.location_on_outlined,
              label: 'Location',
              content: task.location,
            ),
            const SizedBox(height: 12),

            // ── AI Match Reason ───────────────────────────────────────────────
            if (task.matchReason != null && task.matchReason!.isNotEmpty) ...[ 
              _InfoCard(
                icon: Icons.auto_awesome,
                label: 'Why you were matched',
                content: task.matchReason!,
                contentColor: AppColors.primary,
              ),
              const SizedBox(height: 12),
            ],

            // ── Photo ─────────────────────────────────────────────────────────
            if (task.imageUrl != null && task.imageUrl!.isNotEmpty) ...[ 
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  task.imageUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
              const SizedBox(height: 12),
            ],

            const SizedBox(height: 8),

            // ── Open Maps button ──────────────────────────────────────────────
            OutlinedButton.icon(
              icon: const Icon(Icons.map_outlined, size: 18),
              label: const Text('Open in Google Maps'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final url = 'https://www.google.com/maps/dir/?api=1&destination=${task.lat},${task.lng}';
                final uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            ),
            const SizedBox(height: 28),

            // ── Action Buttons ────────────────────────────────────────────────
            if (task.status == 'ASSIGNED') ...[ 
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: controller.isLoading ? null : () async {
                        // Decline: revert status to SCORED
                        await ref.read(taskControllerProvider.notifier).updateStatus(task.id, 'SCORED');
                        if (!context.mounted) return;
                        context.pop();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: BorderSide(color: AppColors.error.withAlpha(120)),
                        minimumSize: const Size(0, 52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Decline'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: controller.isLoading ? null : () {
                        ref.read(taskControllerProvider.notifier).updateStatus(task.id, 'IN_PROGRESS');
                      },
                      icon: controller.isLoading
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.play_arrow_rounded, size: 18),
                      label: const Text('Start Task'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        minimumSize: const Size(0, 52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            if (task.status == 'IN_PROGRESS') ...[ 
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: controller.isLoading ? null : () async {
                    await ref.read(taskControllerProvider.notifier).updateStatus(task.id, 'COMPLETED');
                    if (!context.mounted) return;
                    SnackbarUtils.showSuccess(context, 'Task completed! Great work 🎉');
                    context.pop();
                  },
                  icon: controller.isLoading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Mark as Complete'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.success,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String content;
  final Color contentColor;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.content,
    this.contentColor = AppColors.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(label,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11,
                      fontWeight: FontWeight.w600, letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 6),
          Text(content, style: TextStyle(color: contentColor, fontSize: 14, height: 1.5)),
        ],
      ),
    );
  }
}
