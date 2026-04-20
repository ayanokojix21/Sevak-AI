import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../needs/domain/entities/need_entity.dart';

/// Real-time stat cards showing aggregate dashboard metrics.
/// Computes stats from the live needs list — no separate Firestore query needed.
class StatCards extends ConsumerWidget {
  final List<NeedEntity> needs;

  const StatCards({super.key, required this.needs});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeNeeds = needs
        .where((n) =>
            n.status == AppConstants.statusScored ||
            n.status == AppConstants.statusRaw)
        .length;

    final assignedNeeds = needs
        .where((n) =>
            n.status == AppConstants.statusAssigned ||
            n.status == AppConstants.statusInProgress)
        .length;

    final resolvedNeeds = needs
        .where((n) => n.status == AppConstants.statusCompleted)
        .length;

    final criticalNeeds = needs.where((n) => n.urgencyScore >= 80).length;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive: 4 cards on wide, 2x2 grid on narrow
        final isWide = constraints.maxWidth > 700;
        final cards = [
          _StatCard(
            icon: Icons.warning_amber_rounded,
            label: 'Active Needs',
            value: activeNeeds.toString(),
            color: AppColors.urgencyCritical,
            gradient: const LinearGradient(
              colors: [Color(0x33FF4444), Color(0x0AFF4444)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          _StatCard(
            icon: Icons.person_pin_circle_rounded,
            label: 'Assigned',
            value: assignedNeeds.toString(),
            color: AppColors.urgencyUrgent,
            gradient: const LinearGradient(
              colors: [Color(0x33FFB300), Color(0x0AFFB300)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          _StatCard(
            icon: Icons.check_circle_rounded,
            label: 'Resolved',
            value: resolvedNeeds.toString(),
            color: AppColors.urgencyModerate,
            gradient: const LinearGradient(
              colors: [Color(0x334CAF50), Color(0x0A4CAF50)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          _StatCard(
            icon: Icons.local_fire_department_rounded,
            label: 'Critical',
            value: criticalNeeds.toString(),
            color: AppColors.primary,
            gradient: const LinearGradient(
              colors: [Color(0x336C63FF), Color(0x0A6C63FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ];

        if (isWide) {
          return Row(
            children: cards
                .map((card) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: card,
                      ),
                    ))
                .toList(),
          );
        }

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: cards
              .map((card) => SizedBox(
                    width: (constraints.maxWidth - 12) / 2,
                    child: card,
                  ))
              .toList(),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final LinearGradient gradient;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(51), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(38),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}
