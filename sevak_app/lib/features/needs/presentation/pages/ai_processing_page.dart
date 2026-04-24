import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
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
    // Listen for result changes — navigate or show error
    ref.listen(needControllerProvider, (previous, next) {
      if (!mounted) return;

      if (next is AsyncData && next.value != null) {
        context.pushReplacement('/need-confirmation');
      } else if (next is AsyncError) {
        final errorMsg = SnackbarUtils.messageFrom(next.error);
        debugPrint('AI Processing error: $errorMsg');
        SnackbarUtils.showError(context, 'AI Processing failed: $errorMsg');
        context.pop();
      }
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.bgBase,
              Color(0xFF0F1A2E),
              AppColors.bgBase,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated pulsing circle
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final scale = 1.0 + (_pulseController.value * 0.15);
                  final opacity = 0.4 + (_pulseController.value * 0.6);
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withAlpha((opacity * 60).toInt()),
                        border: Border.all(
                          color: AppColors.primary.withAlpha((opacity * 255).toInt()),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        size: 40,
                        color: AppColors.primary,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 40),
              const Text(
                'SevakAI is analyzing...',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Extracting emergency type, urgency score,\nand location data from your report.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              const SizedBox(
                width: 200,
                child: LinearProgressIndicator(
                  backgroundColor: AppColors.bgElevated,
                  color: AppColors.primary,
                  minHeight: 3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
