import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sevak_app/providers/need_providers.dart';

class AiProcessingPage extends ConsumerWidget {
  const AiProcessingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final needState = ref.watch(needControllerProvider);

    // Listen to changes to navigate when done
    ref.listen(needControllerProvider, (previous, next) {
      if (next is AsyncData && next.value != null) {
        context.pushReplacement('/need-confirmation');
      } else if (next is AsyncError) {
        // Show error and pop back
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('AI Processing failed: \${next.error}')),
        );
        context.pop();
      }
    });

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(), // Replace with Lottie in polish phase
            const SizedBox(height: 32),
            const Text(
              'SevakAI is analyzing...',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'Extracting emergency type, urgency score,\nand location data.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
