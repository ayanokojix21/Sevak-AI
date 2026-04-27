import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';

/// M3 stat card — tonal icon + headline number.
class StatCards extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? accentColor;

  const StatCards({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final color = accentColor ?? cs.primary;

    return Card(
      color: cs.surfaceContainerLow,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: tt.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact row of stat cards for dashboard header.
class StatCardRow extends StatelessWidget {
  final List<_StatDef> stats;

  const StatCardRow({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: stats.asMap().entries.map((entry) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: entry.key == 0 ? 0 : 8),
            child: StatCards(
              title: entry.value.title,
              value: entry.value.value,
              icon: entry.value.icon,
              accentColor: entry.value.color,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _StatDef {
  final String title;
  final String value;
  final IconData icon;
  final Color? color;

  const _StatDef({required this.title, required this.value, required this.icon, this.color});
}

/// Helper: builds a stat definition.
_StatDef statDef({required String title, required String value, required IconData icon, Color? color}) =>
    _StatDef(title: title, value: value, icon: icon, color: color);
