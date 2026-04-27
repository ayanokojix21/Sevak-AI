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
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final needState = ref.watch(needControllerProvider);
    final need = needState.value;

    if (need == null) {
      return const Scaffold(body: Center(child: Text('No data found.')));
    }

    // M3-aligned urgency color via AppTheme helper
    final urgencyColor = AppTheme.urgencyColor(need.urgencyScore);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Analysis Result'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (need.imageUrl != null && need.imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child:
                    Image.network(need.imageUrl!, height: 200, fit: BoxFit.cover),
              ),
            const SizedBox(height: 20),

            // Data rows inside a Card
            Card(
              color: cs.surfaceContainerLow,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: cs.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _DataRow(label: 'Category', value: need.needType, cs: cs, tt: tt),
                    _DataRow(
                        label: 'Urgency',
                        value: '${need.urgencyScore}/100',
                        valueColor: urgencyColor,
                        cs: cs,
                        tt: tt),
                    _DataRow(label: 'Reason', value: need.urgencyReason, cs: cs, tt: tt),
                    _DataRow(label: 'Location', value: need.location, cs: cs, tt: tt),
                    _DataRow(
                        label: 'Coordinates',
                        value:
                            '${need.lat.toStringAsFixed(4)}, ${need.lng.toStringAsFixed(4)}',
                        cs: cs,
                        tt: tt),
                    _DataRow(
                        label: 'People Affected',
                        value: need.peopleAffected.toString(),
                        cs: cs,
                        tt: tt,
                        isLast: true),
                  ],
                ),
              ),
            ),

            // High-urgency warning banner
            if (need.urgencyScore > 60 &&
                (need.imageUrl == null || need.imageUrl!.isEmpty)) ...[
              const SizedBox(height: 12),
              Card(
                color: SevakColors.warning.withAlpha(25),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: SevakColors.warning.withAlpha(120)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: SevakColors.warning, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'A photo is required to publish high-urgency needs.',
                          style: tt.bodySmall
                              ?.copyWith(color: SevakColors.warning),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 28),
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
                  child: FilledButton(
                    onPressed: () async {
                      if (need.urgencyScore > 60 &&
                          (need.imageUrl == null || need.imageUrl!.isEmpty)) {
                        final addPhoto = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            icon: Icon(Icons.camera_alt_outlined,
                                color: SevakColors.warning, size: 36),
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
                                  backgroundColor: SevakColors.warning,
                                  foregroundColor: Colors.black87,
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
                      ref.read(needControllerProvider.notifier).reset();
                      if (context.mounted) {
                        SnackbarUtils.showSuccess(
                            context, 'Need published successfully!');
                        context.go('/');
                      }
                    },
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
}

class _DataRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final ColorScheme cs;
  final TextTheme tt;
  final bool isLast;

  const _DataRow({
    required this.label,
    required this.value,
    required this.cs,
    required this.tt,
    this.valueColor,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: tt.labelSmall?.copyWith(
                color: cs.onSurfaceVariant, letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Text(value,
            style: tt.titleMedium?.copyWith(
                color: valueColor ?? cs.onSurface,
                fontWeight:
                    valueColor != null ? FontWeight.bold : FontWeight.normal)),
        if (!isLast) ...[
          const SizedBox(height: 12),
          Divider(color: cs.outlineVariant, height: 1),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}
