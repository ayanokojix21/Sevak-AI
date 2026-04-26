import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/need_widgets.dart';
import '../../../needs/domain/entities/need_entity.dart';
import '../pages/live_tracking_page.dart';

/// Detail panel displayed when a need is selected on the map or table.
/// Shows photo, Gemini AI analysis, urgency badge, and claim status.
class NeedDetailPanel extends StatelessWidget {
  final NeedEntity need;
  final String claimedByNgoName;
  final String? coordinatorNgoId;
  final VoidCallback? onClaim;
  final VoidCallback? onApprove;   // Now used for "Retry AI Match" on stuck SCORED needs
  final VoidCallback? onCancel;    // Cancel an already-assigned task
  final VoidCallback? onClose;
  final Future<void> Function()? onMatch; // triggers matching engine
  final bool isMatching;                  // true while AI is running

  const NeedDetailPanel({
    super.key,
    required this.need,
    required this.claimedByNgoName,
    this.coordinatorNgoId,
    this.onClaim,
    this.onApprove,
    this.onCancel,
    this.onClose,
    this.onMatch,
    this.isMatching = false,
  });

  @override
  Widget build(BuildContext context) {
    final urgencyColor = AppTheme.urgencyColor(need.urgencyScore);
    final urgencyLabel = AppTheme.urgencyLabel(need.urgencyScore);
    final isClaimed = need.ngoId.isNotEmpty;
    final dateFormatted = DateFormat('d MMM yyyy, h:mm a').format(need.createdAt);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.bgSurface.withAlpha(220),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(64),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with close button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: urgencyColor.withAlpha(38),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: urgencyColor.withAlpha(76)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: urgencyColor,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        urgencyLabel,
                        style: TextStyle(
                          color: urgencyColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${need.urgencyScore}/100',
                  style: TextStyle(
                    color: urgencyColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (onClose != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: onClose,
                    style: IconButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),

          // Content (scrollable if panel is constrained)
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Image
                  if (need.imageUrl != null && need.imageUrl!.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: need.imageUrl!,
                        height: 180,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          height: 180,
                          color: AppColors.bgElevated,
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          height: 180,
                          color: AppColors.bgElevated,
                          child: const Icon(Icons.broken_image, color: AppColors.textDisabled),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Need type badge
                  Row(
                    children: [
                      NeedTypeChip(needType: need.needType),
                      const SizedBox(width: 8),
                      StatusBadge(status: need.status),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // AI Reasoning
                  if (need.urgencyReason.isNotEmpty) ...[
                    _SectionLabel(label: 'AI Analysis'),
                    const SizedBox(height: 6),
                    Text(
                      need.urgencyReason,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: AppColors.bgSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary.withAlpha(50)),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withAlpha(15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.auto_awesome, size: 16, color: AppColors.primary),
                            const SizedBox(width: 8),
                            const Text('SITUATION INTELLIGENCE', 
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.8, color: AppColors.primary)),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withAlpha(20),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('2026 SOTA', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.primary)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _AiInfoRow(label: 'Impact Scale', value: '${need.peopleAffected} People Affected'),
                        _AiInfoRow(label: 'Severity', value: need.scaleAssessment.severity, color: need.scaleAssessment.severity == 'CRITICAL' ? AppColors.error : AppColors.primary),
                        _AiInfoRow(label: 'Vulnerable Groups', value: need.scaleAssessment.vulnerableGroups.isEmpty ? 'None Detected' : need.scaleAssessment.vulnerableGroups.join(', ')),
                        _AiInfoRow(label: 'Infra Damage', value: need.scaleAssessment.infrastructureDamage),
                        const SizedBox(height: 8),
                        const Divider(height: 1, color: AppColors.border),
                        const SizedBox(height: 12),
                        Text(
                          need.scaleAssessment.estimatedScope, 
                          style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.textSecondary, height: 1.4),
                        ),
                      ],
                    ),
                  ),

                  // Location
                  _InfoRow(
                    icon: Icons.location_on_outlined,
                    label: 'Location',
                    value: need.location,
                  ),
                  const SizedBox(height: 10),

                  // Coordinates
                  _InfoRow(
                    icon: Icons.gps_fixed,
                    label: 'Coordinates',
                    value: '${need.lat.toStringAsFixed(4)}, ${need.lng.toStringAsFixed(4)}',
                  ),
                  const SizedBox(height: 10),

                  // People Affected
                  _InfoRow(
                    icon: Icons.groups_outlined,
                    label: 'People Affected',
                    value: need.peopleAffected.toString(),
                  ),
                  const SizedBox(height: 10),

                  // Submitted date
                  _InfoRow(
                    icon: Icons.access_time,
                    label: 'Submitted',
                    value: dateFormatted,
                  ),
                  const SizedBox(height: 10),

                  // Claimed by
                  _InfoRow(
                    icon: Icons.business_outlined,
                    label: 'Claimed by',
                    value: isClaimed ? claimedByNgoName : 'Unclaimed',
                    valueColor: isClaimed ? AppColors.accent : AppColors.textDisabled,
                  ),

                  // Match info
                  if (need.assignedTo != null && need.assignedTo!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _InfoRow(
                      icon: Icons.person_outline,
                      label: 'Assigned To',
                      value: need.assignedTo!,
                    ),
                  ],
                  if (need.matchReason != null && need.matchReason!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _InfoRow(
                      icon: Icons.psychology_outlined,
                      label: 'Match Reason',
                      value: need.matchReason!,
                    ),
                  ],

                  const SizedBox(height: 20),

                  if ((need.status == 'SCORED' || need.status == 'RAW') &&
                      onApprove != null)
                    SizedBox(
                      height: 48,
                      child: FilledButton.icon(
                        onPressed: onApprove,
                        icon: const Icon(Icons.auto_awesome, size: 20),
                        label: const Text('Retry AI Match',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),

                  if ((need.status == 'ASSIGNED' || need.status == 'IN_PROGRESS' || need.status == 'SCORED') &&
                      coordinatorNgoId != null && onCancel != null) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: onCancel,
                        icon: const Icon(Icons.cancel_outlined, size: 20),
                        label: const Text('Cancel Task',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: BorderSide(color: AppColors.error.withAlpha(160)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],

                  if ((need.status == 'ASSIGNED' || need.status == 'IN_PROGRESS') && 
                      need.assignedTo != null && need.assignedTo!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 48,
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => LiveTrackingPage(need: need),
                            ),
                          );
                        },
                        icon: const Icon(Icons.map_outlined, size: 20),
                        label: const Text('Live Track Volunteer',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
        ),
      ),
    );
  }
}


class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.0,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textDisabled),
        const SizedBox(width: 8),
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: valueColor ?? AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _AiInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _AiInfoRow({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color ?? AppColors.textPrimary)),
        ],
      ),
    );
  }
}

