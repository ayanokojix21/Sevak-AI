import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../providers/need_providers.dart';

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
      urgencyColor = Colors.red;
    } else if (need.urgencyScore >= 50) {
      urgencyColor = Colors.orange;
    } else {
      urgencyColor = Colors.green;
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
            if (need.imageUrl != null)
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
                    onPressed: () {
                      ref.read(needControllerProvider.notifier).reset();
                      SnackbarUtils.showSuccess(context, 'Need published successfully!');
                      context.go('/');
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
