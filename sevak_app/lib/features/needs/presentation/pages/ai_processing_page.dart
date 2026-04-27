import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/snackbar_utils.dart';
import '../../../../providers/need_providers.dart';

class AiProcessingPage extends ConsumerStatefulWidget {
  const AiProcessingPage({super.key});

  @override
  ConsumerState<AiProcessingPage> createState() => _AiProcessingPageState();
}

class _AiProcessingPageState extends ConsumerState<AiProcessingPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    ref.listen(needControllerProvider, (previous, next) {
      if (!mounted) return;
      if (next is AsyncData && next.value != null) {
        context.pushReplacement('/need-confirmation');
      } else if (next is AsyncError) {
        final errorMsg = SnackbarUtils.messageFrom(next.error);
        SnackbarUtils.showError(context, 'AI Processing failed: $errorMsg');
        context.pop();
      }
    });

    return Scaffold(
      backgroundColor: cs.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated pulsing icon in M3 primaryContainer
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final scale = 1.0 + (_pulseController.value * 0.12);
                  final alpha = (80 + (_pulseController.value * 100)).toInt();
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: cs.primaryContainer.withAlpha(alpha),
                        border: Border.all(
                          color: cs.primary.withAlpha(180),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        size: 48,
                        color: cs.onPrimaryContainer,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 40),
              Text(
                'SevakAI is analyzing...',
                style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Extracting emergency type, urgency score,\nand location data from your report.',
                textAlign: TextAlign.center,
                style: tt.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: 200,
                child: LinearProgressIndicator(
                  backgroundColor: cs.surfaceContainerHighest,
                  color: cs.primary,
                  minHeight: 4,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Powered by Google Gemini',
                style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
