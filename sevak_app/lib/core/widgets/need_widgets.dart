import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// NeedTypeChip — Material 3 tonal chip for need categories.
// ─────────────────────────────────────────────────────────────────────────────
class NeedTypeChip extends StatelessWidget {
  final String needType;

  const NeedTypeChip({super.key, required this.needType});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        needType.toUpperCase(),
        style: GoogleFonts.roboto(
          color: cs.onSecondaryContainer,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// StatusBadge — M3 tonal badge that maps status strings to semantic colors.
// ─────────────────────────────────────────────────────────────────────────────
class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  Color _bg(String s, ColorScheme cs) {
    switch (s.toUpperCase()) {
      case 'SCORED':
      case 'RAW':
        return cs.tertiaryContainer;
      case 'ASSIGNED':
        return cs.primaryContainer;
      case 'IN_PROGRESS':
        return SevakColors.urgencyUrgent.withAlpha(30);
      case 'COMPLETED':
        return SevakColors.success.withAlpha(30);
      case 'CLOSED':
        return cs.surfaceContainerHighest;
      default:
        return cs.surfaceContainerHighest;
    }
  }

  Color _fg(String s, ColorScheme cs) {
    switch (s.toUpperCase()) {
      case 'SCORED':
      case 'RAW':
        return cs.onTertiaryContainer;
      case 'ASSIGNED':
        return cs.onPrimaryContainer;
      case 'IN_PROGRESS':
        return SevakColors.urgencyUrgent;
      case 'COMPLETED':
        return SevakColors.success;
      case 'CLOSED':
        return cs.onSurfaceVariant;
      default:
        return cs.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _bg(status, cs),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: GoogleFonts.roboto(
          color: _fg(status, cs),
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// UrgencyBadge — dot + label chip using M3 semantic colors.
// ─────────────────────────────────────────────────────────────────────────────
class UrgencyBadge extends StatelessWidget {
  final int score;

  const UrgencyBadge({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.urgencyColor(score);
    final label = AppTheme.urgencyLabel(score);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.roboto(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
