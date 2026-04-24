import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Shared widget for rendering a styled need-type chip (FOOD, MEDICAL, etc.).
/// Single source of truth — replaces `_TypeChip` in need_detail_panel and
/// duplicated switch blocks in task_list_table.
class NeedTypeChip extends StatelessWidget {
  final String needType;
  const NeedTypeChip({super.key, required this.needType});

  @override
  Widget build(BuildContext context) {
    final icon = needTypeIcon(needType);
    final color = needTypeColor(needType);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(76)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            needType,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Returns the icon for a given need type string.
  static IconData needTypeIcon(String type) => switch (type) {
        'FOOD' => Icons.restaurant_rounded,
        'MEDICAL' => Icons.local_hospital_rounded,
        'SHELTER' => Icons.home_rounded,
        'CLOTHING' => Icons.checkroom_rounded,
        _ => Icons.help_outline_rounded,
      };

  /// Returns the colour for a given need type string.
  static Color needTypeColor(String type) => switch (type) {
        'FOOD' => const Color(0xFFFF7043),
        'MEDICAL' => const Color(0xFFEF5350),
        'SHELTER' => const Color(0xFF42A5F5),
        'CLOTHING' => const Color(0xFFAB47BC),
        _ => const Color(0xFF78909C),
      };
}

/// Shared widget for rendering a styled status badge (RAW, SCORED, ASSIGNED…).
/// Single source of truth — replaces `_StatusChip` in need_detail_panel and
/// `_StatusBadge` in task_list_table.
class StatusBadge extends StatelessWidget {
  final String status;
  /// When [compact] is true, uses smaller padding (for table rows).
  final bool compact;

  const StatusBadge({super.key, required this.status, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final color = statusColor(status);
    final pad = compact
        ? const EdgeInsets.symmetric(horizontal: 8, vertical: 3)
        : const EdgeInsets.symmetric(horizontal: 10, vertical: 5);
    final fontSize = compact ? 11.0 : 12.0;

    return Container(
      padding: pad,
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(compact ? 6 : 8),
        border: Border.all(color: color.withAlpha(76)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Returns the colour for a given status string.
  static Color statusColor(String status) => switch (status) {
        'RAW' => AppColors.textDisabled,
        'SCORED' => AppColors.info,
        'ASSIGNED' => AppColors.urgencyUrgent,
        'IN_PROGRESS' => AppColors.primary,
        'COMPLETED' => AppColors.urgencyModerate,
        _ => AppColors.textDisabled,
      };
}
