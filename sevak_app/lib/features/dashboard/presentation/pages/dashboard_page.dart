import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../providers/dashboard_providers.dart';
import '../../../needs/domain/entities/need_entity.dart';
import '../controllers/dashboard_controller.dart';
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
            ? ref.watch(ngoNeedsStreamProvider(coordinatorNgo.id))
            : const AsyncValue<List<NeedEntity>>.data([]);

    // Listen for controller errors
    ref.listen<AsyncValue<void>>(dashboardControllerProvider, (prev, next) {
      if (next.hasError) {
        SnackbarUtils.showError(context, next.error.toString());
      }
    });

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: _buildAppBar(showGlobal, coordinatorNgo?.name),
      body: needsStream.when(
        data: (needs) => _buildBody(context, needs, selectedNeed, coordinatorNgo?.id),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                'Failed to load needs',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(err.toString(), style: const TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool showGlobal, String? ngoName) {
    return AppBar(
      backgroundColor: AppColors.bgBase,
      elevation: 0,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.dashboard_rounded, color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Command Center',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (ngoName != null)
                    Text(
                      ngoName,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        // Global/NGO toggle
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: AppColors.bgElevated,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ToggleButton(
                label: 'All',
                icon: Icons.public,
                isActive: showGlobal,
                onTap: () => ref.read(showGlobalNeedsProvider.notifier).state = true,
              ),
              _ToggleButton(
                label: 'NGO',
                icon: Icons.business,
                isActive: !showGlobal,
                onTap: () => ref.read(showGlobalNeedsProvider.notifier).state = false,
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),
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
          StatCards(needs: needs),
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
              StatCards(needs: needs),
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
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: AppColors.textDisabled,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: _buildDetailPanel(
                  need,
                  coordinatorNgoId,
                  onClose: () => Navigator.pop(ctx),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailPanel(
    NeedEntity need,
    String? coordinatorNgoId, {
    VoidCallback? onClose,
  }) {
    return FutureBuilder<String>(
      future: ref.read(dashboardControllerProvider.notifier).getNgoName(need.ngoId),
      builder: (context, snapshot) {
        final ngoName = snapshot.data ?? (need.ngoId.isEmpty ? 'Unclaimed' : 'Loading...');

        return NeedDetailPanel(
          need: need,
          claimedByNgoName: ngoName,
          coordinatorNgoId: coordinatorNgoId,
          onClaim: coordinatorNgoId != null
              ? () async {
                  await ref.read(dashboardControllerProvider.notifier).claimNeed(
                        needId: need.id,
                        ngoId: coordinatorNgoId,
                      );
                  if (!mounted) return;
                  SnackbarUtils.showSuccess(context, 'Need claimed for your NGO!');
                }
              : null,
          onClose: onClose ??
              () => ref.read(selectedNeedProvider.notifier).state = null,
        );
      },
    );
  }
}

// ── Toggle Button ─────────────────────────────────────────────────────────────

class _ToggleButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withAlpha(38) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? AppColors.primary : AppColors.textDisabled,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? AppColors.primary : AppColors.textDisabled,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
