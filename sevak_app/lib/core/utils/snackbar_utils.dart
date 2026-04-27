import 'package:flutter/material.dart';

import '../errors/failures.dart';
import '../theme/app_theme.dart';

class SnackbarUtils {
  SnackbarUtils._();

  /// Shows an M3-styled error snackbar using colorScheme.error tokens.
  static void showError(BuildContext context, String message) {
    final cs = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline_rounded,
                  color: cs.onErrorContainer, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(message,
                    style: TextStyle(
                        color: cs.onErrorContainer,
                        fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          backgroundColor: cs.errorContainer,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          elevation: 3,
        ),
      );
  }

  /// Shows an M3-styled success snackbar using SevakColors.success.
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(message,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          backgroundColor: SevakColors.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          elevation: 3,
        ),
      );
  }

  /// Convenience: extracts a human-readable message from any thrown object.
  static String messageFrom(Object? error) {
    if (error is Failure) return error.message;
    return error?.toString() ?? 'An unexpected error occurred.';
  }
}
