import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../domain/entities/task_entity.dart';
import '../../../../providers/task_providers.dart';

/// My Tasks page — real-time list of tasks assigned to this volunteer.
class MyTasksPage extends ConsumerWidget {
  const MyTasksPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final tasksAsync = ref.watch(myTasksStreamProvider);

    ref.listen<AsyncValue<void>>(taskControllerProvider, (_, next) {
      if (next.hasError)
        SnackbarUtils.showError(context, next.error.toString());
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: tasksAsync.when(
        data: (tasks) {
          if (tasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: cs.onSurfaceVariant),
                  const SizedBox(height: 16),
                  Text('No active tasks', style: tt.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    "You'll be notified when a need is assigned to you.",
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
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
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final urgencyColor = AppTheme.urgencyColor(task.urgencyScore);

    return Card(
      color: cs.surfaceContainerLow,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Urgency dot
                  Container(
                    width: 10, height: 10,
                    decoration:
                        BoxDecoration(color: urgencyColor, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(task.needType,
                        style: tt.labelSmall?.copyWith(
                            color: urgencyColor,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8)),
                  ),
                  // Cross-NGO badge
                  if (task.isCrossNgo)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('PARTNER',
                          style: tt.labelSmall?.copyWith(
                              color: cs.onPrimaryContainer,
                              fontSize: 9,
                              fontWeight: FontWeight.w700)),
                    ),
                  const SizedBox(width: 8),
                  // Status chip
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(task.status,
                        style: tt.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant, fontSize: 10)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(task.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: tt.bodyMedium),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.location_on_outlined,
                      size: 13, color: cs.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(task.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tt.bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant)),
                  ),
                  Icon(Icons.chevron_right, size: 16, color: cs.onSurfaceVariant),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
