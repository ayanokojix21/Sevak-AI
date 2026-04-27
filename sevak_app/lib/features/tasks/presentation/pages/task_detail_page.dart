import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../domain/entities/task_entity.dart';
import '../../../../providers/need_providers.dart';
import '../../../../core/utils/image_compressor.dart';
import '../../../../providers/task_providers.dart';
import '../../../dashboard/presentation/pages/live_tracking_page.dart';
import '../../../needs/domain/entities/need_entity.dart';
import '../../../../providers/auth_providers.dart';
import '../../../../providers/matching_providers.dart';

import '../widgets/ai_co_pilot_widget.dart';

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
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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

                _InfoCard(
                  icon: Icons.description_outlined,
                  label: 'Description',
                  content: task.description,
                ),
                const SizedBox(height: 12),

                _InfoCard(
                  icon: Icons.location_on_outlined,
                  label: 'Location',
                  content: task.location,
                ),
                const SizedBox(height: 12),

                if (task.matchReason != null && task.matchReason!.isNotEmpty) ...[ 
                  _InfoCard(
                    icon: Icons.auto_awesome,
                    label: 'Why you were matched',
                    content: task.matchReason!,
                    contentColor: AppColors.primary,
                  ),
                  const SizedBox(height: 12),
                ],

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

                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.electric_moped, size: 20),
                    label: const Text('SevakAI Navigation (Zomato-style)', 
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      final currentUser = ref.read(volunteerProfileProvider).value;
                      if (currentUser == null) return;

                      // Reconstruct NeedEntity to reuse LiveTrackingPage
                      final need = NeedEntity(
                        id: task.id,
                        rawText: task.description,
                        location: task.location,
                        lat: task.lat,
                        lng: task.lng,
                        needType: task.needType,
                        urgencyScore: task.urgencyScore,
                        urgencyReason: '',
                        peopleAffected: 0,
                        status: task.status,
                        submittedBy: '', 
                        assignedTo: currentUser.uid, 
                        ngoId: task.ngoId,
                        createdAt: task.createdAt,
                        imageUrl: task.imageUrl,
                      );

                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => LiveTrackingPage(need: need),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 28),

                if (task.status == 'ASSIGNED') ...[ 
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: controller.isLoading ? null : () async {
                            // Decline: record rejection and rematch
                            final matchUseCase = ref.read(matchVolunteerUseCaseProvider);
                            await ref.read(taskControllerProvider.notifier).declineTask(task, matchUseCase);
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
                        _showCompleteDialog(context, ref, task);
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

                const SizedBox(height: 80),
              ],
            ),
          ),
          AiCoPilotWidget(task: task),
        ],
      ),
    );
  }

  void _showCompleteDialog(BuildContext context, WidgetRef ref, TaskEntity task) {
    final notesController = TextEditingController();
    Uint8List? successImageBytes;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          decoration: const BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Great Work!', 
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), 
                textAlign: TextAlign.center
              ),
              const SizedBox(height: 8),
              const Text('Share a success photo and a quick note for the NGO.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 20),
              
              if (successImageBytes != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(successImageBytes!, height: 120, fit: BoxFit.cover),
                )
              else
                OutlinedButton.icon(
                  onPressed: () async {
                    final picker = ImagePicker();
                    final picked = await picker.pickImage(source: ImageSource.camera);
                    if (picked != null) {
                      final bytes = await picked.readAsBytes();
                      setModalState(() => successImageBytes = bytes);
                    }
                  },
                  icon: const Icon(Icons.add_a_photo),
                  label: const Text('Add Success Photo'),
                ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: InputDecoration(
                  hintText: 'What was achieved? (e.g. delivered 5 kits)',
                  fillColor: AppColors.bgBase,
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () async {
                  Navigator.pop(context); // Close dialog
                  
                  final ai = ref.read(aiDatasourceProvider);
                  final cloudinary = ref.read(cloudinaryProvider);
                  
                  List<int>? bytes;
                  String? imageUrl;
                  
                  if (successImageBytes != null) {
                    bytes = await ImageCompressor.compress(successImageBytes!);
                    imageUrl = await cloudinary.uploadImage(bytes, 'success_${task.id}.jpg');
                  }
                  
                  await ref.read(taskControllerProvider.notifier).completeTaskWithStory(
                    task: task,
                    completionNotes: notesController.text,
                    ai: ai,
                    successImageBytes: bytes,
                    afterImageUrl: imageUrl,
                  );
                  
                  if (!context.mounted) return;
                  SnackbarUtils.showSuccess(context, 'Impact Story Generated! Task Completed 🎉');
                  context.pop(); // Back to tasks
                },
                style: FilledButton.styleFrom(backgroundColor: AppColors.success, minimumSize: const Size(0, 50)),
                child: const Text('Generate Impact & Complete'),
              ),
            ],
          ),
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
    ).animate().fade().slideY(begin: 0.05, end: 0);
  }
}
