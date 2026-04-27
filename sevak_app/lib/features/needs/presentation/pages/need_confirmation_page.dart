import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../providers/need_providers.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/snackbar_utils.dart';

class NeedConfirmationPage extends ConsumerWidget {
  const NeedConfirmationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final needState = ref.watch(needControllerProvider);
    final need = needState.value;

    if (need == null) {
      return const Scaffold(body: Center(child: Text('No data found.')));
    }

    Color urgencyColor;
    if (need.urgencyScore >= 80) {
      urgencyColor = AppColors.urgencyCritical;
    } else if (need.urgencyScore >= 50) {
      urgencyColor = AppColors.urgencyUrgent;
    } else {
      urgencyColor = AppColors.urgencyModerate;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm AI Extraction'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (need.imageUrl != null && need.imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(need.imageUrl!, height: 200, fit: BoxFit.cover),
              ),
            const SizedBox(height: 24),
            _buildDataRow('Category', need.needType),
            _buildDataRow('Urgency', '${need.urgencyScore}/100', color: urgencyColor),
            _buildDataRow('Reason', need.urgencyReason),
            _buildDataRow('Location', need.location),
            _buildDataRow('Coordinates', '${need.lat.toStringAsFixed(4)}, ${need.lng.toStringAsFixed(4)}'),
            _buildDataRow('People Affected', need.peopleAffected.toString()),

            // High-urgency warning banner (text-only, no image yet)
            if (need.urgencyScore > 60 && (need.imageUrl == null || need.imageUrl!.isEmpty)) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.warning.withAlpha(120)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'A photo is required to publish high-urgency needs.',
                        style: TextStyle(color: AppColors.warning, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ref.read(needControllerProvider.notifier).reset();
                      context.go('/');
                    },
                    child: const Text('Discard'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      // If urgency > 60 and no photo was provided, block and redirect
                      if (need.urgencyScore > 60 &&
                          (need.imageUrl == null || need.imageUrl!.isEmpty)) {
                        final addPhoto = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            icon: const Icon(
                              Icons.camera_alt_outlined,
                              color: AppColors.warning,
                              size: 36,
                            ),
                            title: const Text('Photo Required'),
                            content: Text(
                              'This need has a high urgency score of '
                              '${need.urgencyScore}/100.\n\n'
                              'A photo is mandatory for high-urgency needs to '
                              'verify the situation and prevent misuse.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.warning,
                                  foregroundColor: AppColors.bgBase,
                                ),
                                child: const Text('Add Photo'),
                              ),
                            ],
                          ),
                        );
                        if (addPhoto == true) {
                          ref.read(needControllerProvider.notifier).reset();
                          if (context.mounted) {
                            context.go('/submit-need?requirePhoto=true');
                          }
                        }
                        return;
                      }

                      // No urgency restriction — publish normally
                      ref.read(needControllerProvider.notifier).reset();
                      SnackbarUtils.showSuccess(context, 'Need published successfully!');
                      context.go('/');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Publish Need'),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDataRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 18, color: color)),
        ],
      ),
    );
  }
}
