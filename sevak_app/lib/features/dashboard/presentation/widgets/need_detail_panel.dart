import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/need_widgets.dart';
import '../../../needs/domain/entities/need_entity.dart';
import '../pages/live_tracking_page.dart';

/// Detail panel displayed when a need is selected on the map or table.
/// Fully M3: Card surface, colorScheme tokens, no glassmorphism.
class NeedDetailPanel extends StatelessWidget {
  final NeedEntity need;
  final String claimedByNgoName;
  final String? coordinatorNgoId;
  final VoidCallback? onClaim;
  final VoidCallback? onApprove;
  final VoidCallback? onCancel;
  final VoidCallback? onClose;
  final Future<void> Function()? onMatch;
  final bool isMatching;

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
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final urgencyColor = AppTheme.urgencyColor(need.urgencyScore);
    final urgencyLabel = AppTheme.urgencyLabel(need.urgencyScore);
    final isClaimed = need.ngoId.isNotEmpty;
    final dateFormatted =
        DateFormat('d MMM yyyy, h:mm a').format(need.createdAt);

    return Card(
      color: cs.surfaceContainerLow,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
            child: Row(
              children: [
                // Urgency pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: urgencyColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle, color: urgencyColor),
                      ),
                      const SizedBox(width: 6),
                      Text(urgencyLabel,
                          style: tt.labelSmall?.copyWith(
                              color: urgencyColor,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text('${need.urgencyScore}/100',
                    style: tt.labelMedium?.copyWith(
                        color: urgencyColor, fontWeight: FontWeight.w600)),
                const Spacer(),
                if (onClose != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: onClose,
                  ),
              ],
            ),
          ),

          // ── Scrollable content ────────────────────────────────────────
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Photo
                  if (need.imageUrl != null && need.imageUrl!.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: need.imageUrl!,
                        height: 180,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          height: 180,
                          color: cs.surfaceContainerHighest,
                          child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2)),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          height: 180,
                          color: cs.surfaceContainerHighest,
                          child: Icon(Icons.broken_image,
                              color: cs.onSurfaceVariant),
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),

                  // Badges row
                  Row(
                    children: [
                      NeedTypeChip(needType: need.needType),
                      const SizedBox(width: 8),
                      StatusBadge(status: need.status),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // AI analysis
                  if (need.urgencyReason.isNotEmpty) ...[
                    Text('AI ANALYSIS',
                        style: tt.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant, letterSpacing: 1.0)),
                    const SizedBox(height: 6),
                    Text(need.urgencyReason,
                        style: tt.bodyMedium?.copyWith(
                            color: cs.onSurface, height: 1.5)),
                    const SizedBox(height: 16),
                  ],

                  // Situation Intelligence card
                  Card(
                    color: cs.secondaryContainer.withAlpha(60),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: cs.primary.withAlpha(40)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.auto_awesome,
                                  size: 16, color: cs.primary),
                              const SizedBox(width: 8),
                              Text('SITUATION INTELLIGENCE',
                                  style: tt.labelSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.8,
                                      color: cs.primary)),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: cs.primaryContainer,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text('GEMINI',
                                    style: tt.labelSmall?.copyWith(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w700,
                                        color: cs.onPrimaryContainer)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _AiInfoRow(label: 'Impact Scale',
                              value: '${need.peopleAffected} People'),
                          _AiInfoRow(
                              label: 'Severity',
                              value: need.scaleAssessment.severity,
                              color: need.scaleAssessment.severity ==
                                      'CRITICAL'
                                  ? cs.error
                                  : cs.primary),
                          _AiInfoRow(
                              label: 'Vulnerable Groups',
                              value: need.scaleAssessment.vulnerableGroups
                                      .isEmpty
                                  ? 'None detected'
                                  : need.scaleAssessment.vulnerableGroups
                                      .join(', ')),
                          _AiInfoRow(
                              label: 'Infra Damage',
                              value: need.scaleAssessment.infrastructureDamage),
                          Divider(height: 20, color: cs.outlineVariant),
                          Text(need.scaleAssessment.estimatedScope,
                              style: tt.bodySmall?.copyWith(
                                  fontStyle: FontStyle.italic,
                                  color: cs.onSurfaceVariant,
                                  height: 1.4)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Info rows
                  _InfoRow(icon: Icons.location_on_outlined,
                      label: 'Location', value: need.location),
                  _InfoRow(icon: Icons.gps_fixed,
                      label: 'Coordinates',
                      value:
                          '${need.lat.toStringAsFixed(4)}, ${need.lng.toStringAsFixed(4)}'),
                  _InfoRow(icon: Icons.groups_outlined,
                      label: 'Affected', value: '${need.peopleAffected} people'),
                  _InfoRow(icon: Icons.access_time,
                      label: 'Submitted', value: dateFormatted),
                  _InfoRow(
                      icon: Icons.business_outlined,
                      label: 'Claimed by',
                      value: isClaimed ? claimedByNgoName : 'Unclaimed',
                      valueColor: isClaimed ? cs.primary : cs.onSurfaceVariant),

                  if (need.assignedTo != null &&
                      need.assignedTo!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    _InfoRow(icon: Icons.person_outline,
                        label: 'Assigned to', value: need.assignedTo!),
                  ],
                  if (need.matchReason != null &&
                      need.matchReason!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    _InfoRow(icon: Icons.psychology_outlined,
                        label: 'Match reason', value: need.matchReason!),
                  ],

                  const SizedBox(height: 20),

                  // Actions
                  if ((need.status == 'SCORED' || need.status == 'RAW') &&
                      onApprove != null)
                    FilledButton.icon(
                      onPressed: onApprove,
                      icon: const Icon(Icons.auto_awesome, size: 18),
                      label: const Text('Retry AI Match'),
                    ),

                  if ((need.status == 'ASSIGNED' ||
                          need.status == 'IN_PROGRESS' ||
                          need.status == 'SCORED') &&
                      coordinatorNgoId != null &&
                      onCancel != null) ...[
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: onCancel,
                      icon: Icon(Icons.cancel_outlined,
                          size: 18, color: cs.error),
                      label: Text('Cancel Task',
                          style: TextStyle(color: cs.error)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: cs.error.withAlpha(160)),
                      ),
                    ),
                  ],

                  if ((need.status == 'ASSIGNED' ||
                          need.status == 'IN_PROGRESS') &&
                      need.assignedTo != null &&
                      need.assignedTo!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => LiveTrackingPage(need: need),
                        ));
                      },
                      icon: const Icon(Icons.map_outlined, size: 18),
                      label: const Text('Live Track Volunteer'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
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
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: cs.onSurfaceVariant),
          const SizedBox(width: 8),
          SizedBox(
            width: 90,
            child: Text(label,
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          ),
          Expanded(
            child: Text(value,
                style: tt.bodySmall?.copyWith(
                    color: valueColor ?? cs.onSurface,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _AiInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _AiInfoRow(
      {required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          Text(value,
              style: tt.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color ?? cs.onSurface)),
        ],
      ),
    );
  }
}
