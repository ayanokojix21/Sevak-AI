import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/need_widgets.dart';
import '../../../needs/domain/entities/need_entity.dart';

/// Sortable table listing all needs with status badges.
/// Tapping a row selects it in the map and detail panel.
class TaskListTable extends StatefulWidget {
  final List<NeedEntity> needs;
  final NeedEntity? selectedNeed;
  final ValueChanged<NeedEntity> onNeedTapped;

  const TaskListTable({
    super.key,
    required this.needs,
    this.selectedNeed,
    required this.onNeedTapped,
  });

  @override
  State<TaskListTable> createState() => _TaskListTableState();
}

class _TaskListTableState extends State<TaskListTable> {
  String _sortField = 'urgencyScore';
  bool _sortAscending = false;

  List<NeedEntity> get _sortedNeeds {
    final sorted = [...widget.needs];
    sorted.sort((a, b) {
      int result;
      switch (_sortField) {
        case 'urgencyScore':
          result = a.urgencyScore.compareTo(b.urgencyScore);
        case 'createdAt':
          result = a.createdAt.compareTo(b.createdAt);
        case 'needType':
          result = a.needType.compareTo(b.needType);
        case 'status':
          result = _statusOrder(a.status).compareTo(_statusOrder(b.status));
        default:
          result = 0;
      }
      return _sortAscending ? result : -result;
    });
    return sorted;
  }

  int _statusOrder(String status) {
    return switch (status) {
      'RAW' => 0,
      'SCORED' => 1,
      'ASSIGNED' => 2,
      'IN_PROGRESS' => 3,
      'COMPLETED' => 4,
      _ => 5,
    };
  }

  void _toggleSort(String field) {
    setState(() {
      if (_sortField == field) {
        _sortAscending = !_sortAscending;
      } else {
        _sortField = field;
        _sortAscending = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.needs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inbox_rounded, size: 48, color: AppColors.textDisabled),
              SizedBox(height: 12),
              Text(
                'No needs reported yet',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Minimum width prevents column compression overflow on mobile
    const double minTableWidth = 520;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: minTableWidth,
            maxWidth: MediaQuery.of(context).size.width > minTableWidth
                ? MediaQuery.of(context).size.width - 32
                : minTableWidth,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Table header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: const BoxDecoration(
                  color: AppColors.bgElevated,
                  border: Border(bottom: BorderSide(color: AppColors.border)),
                ),
                child: Row(
                  children: [
                    _HeaderCell('Type', 'needType', flex: 2),
                    _HeaderCell('Urgency', 'urgencyScore', flex: 2),
                    _HeaderCell('Status', 'status', flex: 2),
                    _HeaderCell('Location', '', flex: 3, sortable: false),
                    _HeaderCell('Date', 'createdAt', flex: 2),
                  ],
                ),
              ),

              // Table rows
              ...(_sortedNeeds.map((need) {
                final isSelected = widget.selectedNeed?.id == need.id;
                return _NeedRow(
                  need: need,
                  isSelected: isSelected,
                  onTap: () => widget.onNeedTapped(need),
                );
              })),
            ],
          ),
        ),
      ),
    );
  }

  Widget _HeaderCell(String label, String field,
      {int flex = 1, bool sortable = true}) {
    final isActive = _sortField == field;
    return Expanded(
      flex: flex,
      child: GestureDetector(
        onTap: sortable ? () => _toggleSort(field) : null,
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppColors.primary : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            if (sortable && isActive) ...[
              const SizedBox(width: 2),
              Icon(
                _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 12,
                color: AppColors.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NeedRow extends StatelessWidget {
  final NeedEntity need;
  final bool isSelected;
  final VoidCallback onTap;

  const _NeedRow({
    required this.need,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final urgencyColor = AppTheme.urgencyColor(need.urgencyScore);
    final dateStr = DateFormat('d MMM, HH:mm').format(need.createdAt);

    return Material(
      color: isSelected ? AppColors.primary.withAlpha(25) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
          ),
          child: Row(
            children: [
              // Type
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    Icon(
                      NeedTypeChip.needTypeIcon(need.needType),
                      size: 16,
                      color: NeedTypeChip.needTypeColor(need.needType),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        need.needType,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              // Urgency
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: urgencyColor.withAlpha(38),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        need.urgencyScore.toString(),
                        style: TextStyle(
                          color: urgencyColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Status
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: StatusBadge(status: need.status, compact: true),
                ),
              ),

              // Location
              Expanded(
                flex: 3,
                child: Text(
                  need.location,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Date
              Expanded(
                flex: 2,
                child: Text(
                  dateStr,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
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

