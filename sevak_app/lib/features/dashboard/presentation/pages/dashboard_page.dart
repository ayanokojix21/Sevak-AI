import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../providers/dashboard_providers.dart';
import '../../../../providers/matching_providers.dart';
import '../../../needs/domain/entities/need_entity.dart';

import '../widgets/need_detail_panel.dart';
import '../widgets/needs_map.dart';
import '../widgets/stat_cards.dart';
import '../widgets/task_list_table.dart';

/// Coordinator Dashboard — the real-time command center.
///
/// Layout:
/// - **Desktop/Web**: Side-by-side map + detail panel, stats on top, table at bottom.
/// - **Mobile/Tablet**: Stacked vertically with bottom-sheet detail panel.
class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  @override
  void initState() {
    super.initState();
    // Load coordinator's NGO on dashboard open
    _loadCoordinatorNgo();
  }

  Future<void> _loadCoordinatorNgo() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final ngo = await ref
        .read(dashboardControllerProvider.notifier)
        .loadCoordinatorNgo(uid);

    if (ngo != null && mounted) {
      ref.read(coordinatorNgoProvider.notifier).state = ngo;
    }
  }

  @override
  Widget build(BuildContext context) {
    final showGlobal = ref.watch(showGlobalNeedsProvider);
    final coordinatorNgo = ref.watch(coordinatorNgoProvider);
    final selectedNeed = ref.watch(selectedNeedProvider);

    // Choose the stream based on global/NGO toggle
    final needsStream = showGlobal
        ? ref.watch(allNeedsStreamProvider)
        : coordinatorNgo != null
            ? ref.watch(mergedNgoNeedsProvider(coordinatorNgo.id))
            : const AsyncValue<List<NeedEntity>>.data([]);

    // Listen for controller errors
    ref.listen<AsyncValue<void>>(dashboardControllerProvider, (prev, next) {
      if (next.hasError) {
        SnackbarUtils.showError(context, next.error.toString());
      }
    });

    // Listen for matching results
    ref.listen<AsyncValue<String?>>(matchingControllerProvider, (prev, next) {
      if (next.hasError) {
        SnackbarUtils.showError(context, 'Matching failed: ${next.error}');
      } else if (next.hasValue && next.value != null && !(prev?.isLoading ?? false)) {
        SnackbarUtils.showSuccess(context, 'Volunteer matched! ✅');
        ref.read(matchingControllerProvider.notifier).reset();
      }
    });

    return Scaffold(
      appBar: _buildAppBar(showGlobal, coordinatorNgo?.name),
      body: needsStream.when(
        data: (needs) => _buildBody(context, needs, selectedNeed, coordinatorNgo?.id),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 16),
              Text('Failed to load needs', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(err.toString(), style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool showGlobal, String? ngoName) {
    return AppBar(
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.dashboard_rounded,
                  color: Theme.of(context).colorScheme.onPrimaryContainer, size: 18),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Command Center',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis),
                  if (ngoName != null)
                    Text(ngoName,
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w400,
                        ),
                        overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        // M3 SegmentedButton toggle
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('All'), icon: Icon(Icons.public, size: 16)),
              ButtonSegment(value: false, label: Text('NGO'), icon: Icon(Icons.business, size: 16)),
            ],
            selected: {showGlobal},
            onSelectionChanged: (v) =>
                ref.read(showGlobalNeedsProvider.notifier).state = v.first,
            style: SegmentedButton.styleFrom(
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(
    BuildContext context,
    List<NeedEntity> needs,
    NeedEntity? selectedNeed,
    String? coordinatorNgoId,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;

        if (isWide) {
          return _buildDesktopLayout(needs, selectedNeed, coordinatorNgoId);
        }
        return _buildMobileLayout(needs, selectedNeed, coordinatorNgoId);
      },
    );
  }

  /// Desktop/web: side-by-side layout
  Widget _buildDesktopLayout(
    List<NeedEntity> needs,
    NeedEntity? selectedNeed,
    String? coordinatorNgoId,
  ) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Stats row
          _buildStatRow(needs),
          const SizedBox(height: 20),

          // Map + Detail panel row
          Expanded(
            flex: 3,
            child: Row(
              children: [
                // Map
                Expanded(
                  flex: selectedNeed != null ? 3 : 5,
                  child: NeedsMap(
                    needs: needs,
                    selectedNeed: selectedNeed,
                    onNeedTapped: (need) =>
                        ref.read(selectedNeedProvider.notifier).state = need,
                  ),
                ),

                // Detail panel (slides in when a need is selected)
                if (selectedNeed != null) ...[
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 360,
                    child: _buildDetailPanel(selectedNeed, coordinatorNgoId),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Task list table
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              child: TaskListTable(
                needs: needs,
                selectedNeed: selectedNeed,
                onNeedTapped: (need) =>
                    ref.read(selectedNeedProvider.notifier).state = need,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Mobile: stacked layout with bottom-sheet detail
  Widget _buildMobileLayout(
    List<NeedEntity> needs,
    NeedEntity? selectedNeed,
    String? coordinatorNgoId,
  ) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Stats
              _buildStatRow(needs),
              const SizedBox(height: 16),

              // Map
              SizedBox(
                height: 350,
                child: NeedsMap(
                  needs: needs,
                  selectedNeed: selectedNeed,
                  onNeedTapped: (need) {
                    ref.read(selectedNeedProvider.notifier).state = need;
                    _showMobileDetailSheet(context, need, coordinatorNgoId);
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Task table
              TaskListTable(
                needs: needs,
                selectedNeed: selectedNeed,
                onNeedTapped: (need) {
                  ref.read(selectedNeedProvider.notifier).state = need;
                  _showMobileDetailSheet(context, need, coordinatorNgoId);
                },
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ],
    );
  }

  void _showMobileDetailSheet(
    BuildContext context,
    NeedEntity need,
    String? coordinatorNgoId,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => _buildDetailPanel(
          need,
          coordinatorNgoId,
          onClose: () => Navigator.pop(ctx),
        ),
      ),
    );
  }

  Widget _buildDetailPanel(
    NeedEntity need,
    String? coordinatorNgoId, {
    VoidCallback? onClose,
  }) {
    final isMatching = ref.watch(matchingControllerProvider).isLoading;

    return FutureBuilder<String>(
      future: ref.read(dashboardControllerProvider.notifier).getNgoName(need.ngoId),
      builder: (context, snapshot) {
        final ngoName = snapshot.data ?? (need.ngoId.isEmpty ? 'Unclaimed' : 'Loading...');

        return NeedDetailPanel(
          need: need,
          claimedByNgoName: ngoName,
          coordinatorNgoId: coordinatorNgoId,
          isMatching: isMatching,
          // Retry AI Match — only shown on stuck SCORED/RAW needs owned by this coordinator
          onApprove: (need.status == 'SCORED' || need.status == 'RAW') &&
                  coordinatorNgoId != null &&
                  need.ngoId == coordinatorNgoId
              ? () => ref.read(matchingControllerProvider.notifier).matchForNeed(need)
              : null,
          // Cancel Task — coordinator can cancel any assigned task in their NGO
          onCancel: coordinatorNgoId != null && need.ngoId == coordinatorNgoId
              ? () async {
                  await ref.read(dashboardControllerProvider.notifier).updateStatus(
                        needId: need.id,
                        newStatus: 'CANCELLED',
                      );
                  if (!context.mounted) return;
                  SnackbarUtils.showSuccess(context, 'Task cancelled.');
                  if (onClose != null) {
                    onClose();
                  } else {
                    ref.read(selectedNeedProvider.notifier).state = null;
                  }
                }
              : null,
          onMatch: coordinatorNgoId != null && need.ngoId == coordinatorNgoId
              ? () => ref.read(matchingControllerProvider.notifier).matchForNeed(need)
              : null,
          onClaim: coordinatorNgoId != null
              ? () async {
                  await ref.read(dashboardControllerProvider.notifier).claimNeed(
                        needId: need.id,
                        ngoId: coordinatorNgoId,
                      );
                  if (!context.mounted) return;
                  SnackbarUtils.showSuccess(context, 'Need claimed for your NGO!');
                }
              : null,
          onClose: onClose ??
              () => ref.read(selectedNeedProvider.notifier).state = null,
        );
      },
    );
  }

  Widget _buildStatRow(List<NeedEntity> needs) {
    final cs = Theme.of(context).colorScheme;
    final total      = needs.length;
    final critical   = needs.where((n) => (n.urgencyScore) >= 80).length;
    final assigned   = needs.where((n) => n.status == 'ASSIGNED' || n.status == 'IN_PROGRESS').length;
    final completed  = needs.where((n) => n.status == 'COMPLETED').length;
    return Row(
      children: [
        Expanded(child: StatCards(title: 'Total', value: '$total', icon: Icons.list_alt, accentColor: cs.primary)),
        const SizedBox(width: 8),
        Expanded(child: StatCards(title: 'Critical', value: '$critical', icon: Icons.warning_amber_rounded, accentColor: cs.error)),
        const SizedBox(width: 8),
        Expanded(child: StatCards(title: 'Active', value: '$assigned', icon: Icons.assignment_ind, accentColor: cs.tertiary)),
        const SizedBox(width: 8),
        Expanded(child: StatCards(title: 'Done', value: '$completed', icon: Icons.check_circle_outline, accentColor: SevakColors.success)),
      ],
    );
  }
}

// _ToggleButton removed — replaced by SegmentedButton in _buildAppBar.
