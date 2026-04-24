import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../domain/entities/task_entity.dart';
import '../../../../providers/task_providers.dart';

/// My Tasks page — real-time list of tasks assigned to this volunteer.
class MyTasksPage extends ConsumerWidget {
  const MyTasksPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(myTasksStreamProvider);

    ref.listen<AsyncValue<void>>(taskControllerProvider, (_, next) {
      if (next.hasError) SnackbarUtils.showError(context, next.error.toString());
    });

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        backgroundColor: AppColors.bgBase,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.accent.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.task_alt, color: AppColors.accent, size: 18),
            ),
            const SizedBox(width: 8),
            const Text('My Tasks', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
      ),
      body: tasksAsync.when(
        data: (tasks) {
          if (tasks.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: AppColors.textDisabled),
                  SizedBox(height: 16),
                  Text('No active tasks', style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
                  SizedBox(height: 4),
                  Text('You will be notified when a need is assigned to you.',
                      style: TextStyle(color: AppColors.textDisabled, fontSize: 13)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tasks.length,
            itemBuilder: (_, i) => _TaskCard(
              task: tasks[i],
              onTap: () => context.push('/task/${tasks[i].id}'),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accent)),
        error: (e, _) => Center(child: Text('Error loading tasks: $e')),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final TaskEntity task;
  final VoidCallback onTap;

  const _TaskCard({required this.task, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final urgencyColor = task.urgencyScore >= 80
        ? AppColors.error
        : task.urgencyScore >= 50
            ? AppColors.warning
            : AppColors.success;

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                // Urgency dot
                Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(color: urgencyColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    task.needType,
                    style: TextStyle(
                      color: urgencyColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                // Cross-NGO badge
                if (task.isCrossNgo)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(25),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.primary.withAlpha(80)),
                    ),
                    child: const Text('PARTNER', style: TextStyle(
                      color: AppColors.primary, fontSize: 9, fontWeight: FontWeight.w700,
                    )),
                  ),
                const SizedBox(width: 8),
                // Status chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.bgElevated,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(task.status,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              task.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 13, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(task.location,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ),
                const Icon(Icons.chevron_right, size: 16, color: AppColors.textDisabled),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
