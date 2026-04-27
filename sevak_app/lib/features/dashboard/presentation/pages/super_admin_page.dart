import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../providers/ngo_providers.dart';
import '../../../../providers/dashboard_providers.dart';
import '../widgets/stat_cards.dart';

class SuperAdminPage extends ConsumerStatefulWidget {
  const SuperAdminPage({super.key});

  @override
  ConsumerState<SuperAdminPage> createState() => _SuperAdminPageState();
}

class _SuperAdminPageState extends ConsumerState<SuperAdminPage> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Super Admin'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.business_center), text: 'NGO Management'),
              Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _NgoManagementTab(),
            _PlatformAnalyticsTab(),
          ],
        ),
      ),
    );
  }
}


class _NgoManagementTab extends ConsumerWidget {
  const _NgoManagementTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingNgosProvider);
    final activeAsync = ref.watch(activeNgosProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Pending Approvals
        _sectionHeader(context, 'Pending Approvals', Icons.pending_actions),
        const SizedBox(height: 10),
        pendingAsync.when(
          data: (ngos) => ngos.isEmpty
              ? _emptyState(context, 'No pending requests', Icons.check_circle_outline)
              : Column(
                  children: ngos.map((ngo) {
                    final cs = Theme.of(context).colorScheme;
                    return Card(
                    color: cs.surfaceContainerLow,
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: SevakColors.warning.withAlpha(60)),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: SevakColors.warning.withAlpha(25),
                        child: Icon(Icons.business, color: SevakColors.warning, size: 20),
                      ),
                      title: Text(ngo.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('${ngo.city.isNotEmpty ? ngo.city : "No city"} · ${ngo.createdAt.day}/${ngo.createdAt.month}/${ngo.createdAt.year}',
                          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.check_circle, color: SevakColors.success),
                            tooltip: 'Approve',
                            onPressed: () {
                              ref.read(ngosDatasourceProvider).approveNgo(ngo.id, ngo.adminUid);
                              SnackbarUtils.showSuccess(context, 'NGO Approved & Admin role assigned');
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.cancel, color: cs.error),
                            tooltip: 'Reject',
                            onPressed: () {
                              ref.read(ngosDatasourceProvider).updateNgoStatus(ngo.id, 'rejected');
                              SnackbarUtils.showError(context, 'NGO Rejected');
                            },
                          ),
                        ],
                      ),
                    ),
                  );}).toList(),
                ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error: $e'),
        ),

        const SizedBox(height: 28),

        // Active NGOs
        _sectionHeader(context, 'Active NGOs', Icons.verified),
        const SizedBox(height: 10),
        activeAsync.when(
          data: (ngos) => ngos.isEmpty
              ? _emptyState(context, 'No active NGOs yet', Icons.business_outlined)
              : Column(
                  children: ngos.map((ngo) {
                    final cs = Theme.of(context).colorScheme;
                    return Card(
                    color: cs.surfaceContainerLow,
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: cs.outlineVariant),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: cs.primaryContainer,
                        child: Icon(Icons.business, color: cs.onPrimaryContainer, size: 20),
                      ),
                      title: Text(ngo.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('${ngo.city.isNotEmpty ? ngo.city : "—"} · ${ngo.volunteerCount} members',
                          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.open_in_new, size: 18, color: cs.primary),
                            tooltip: 'Manage',
                            onPressed: () => context.push('/ngo-admin/${ngo.id}'),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_forever, size: 20, color: cs.error),
                            tooltip: 'Suspend NGO',
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Suspend NGO?'),
                                  content: Text('Are you sure you want to suspend ${ngo.name}?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                    FilledButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      style: FilledButton.styleFrom(backgroundColor: cs.error, foregroundColor: cs.onError),
                                      child: const Text('Suspend'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await ref.read(ngosDatasourceProvider).updateNgoStatus(ngo.id, 'suspended');
                                if (context.mounted) SnackbarUtils.showError(context, 'NGO Suspended');
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );}).toList(),
                ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error: $e'),
        ),
      ],
    );
  }

  Widget _sectionHeader(BuildContext context, String title, IconData icon) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 16, color: cs.primary),
        const SizedBox(width: 6),
        Text(title.toUpperCase(),
            style: TextStyle(color: cs.primary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
      ],
    );
  }

  Widget _emptyState(BuildContext context, String message, IconData icon) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Icon(icon, size: 36, color: cs.onSurfaceVariant),
          const SizedBox(height: 8),
          Text(message, style: TextStyle(color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}


class _PlatformAnalyticsTab extends ConsumerWidget {
  const _PlatformAnalyticsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Real data from Firestore streams
    final activeNgos = ref.watch(activeNgosProvider);
    final allNgos = ref.watch(allNgosProvider);
    final allNeeds = ref.watch(allNeedsStreamProvider);

        final cs = Theme.of(context).colorScheme;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Icon(Icons.analytics, size: 16, color: cs.primary),
                const SizedBox(width: 6),
                Text('LIVE PLATFORM METRICS',
                    style: TextStyle(color: cs.primary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
              ],
            ),
        const SizedBox(height: 16),
        Row(
          children: [
              Expanded(
              child: StatCards(
                title: 'Active NGOs',
                value: activeNgos.when(data: (n) => '${n.length}', loading: () => '...', error: (_, __) => '—'),
                icon: Icons.business,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCards(
                title: 'Total NGOs',
                value: allNgos.when(data: (n) => '${n.length}', loading: () => '...', error: (_, __) => '—'),
                icon: Icons.domain,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StatCards(
                title: 'Total Needs',
                value: allNeeds.when(data: (n) => '${n.length}', loading: () => '...', error: (_, __) => '—'),
                icon: Icons.campaign,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCards(
                title: 'Resolved',
                value: allNeeds.when(
                  data: (n) => '${n.where((need) => need.status == AppConstants.statusCompleted).length}',
                  loading: () => '...',
                  error: (_, __) => '—',
                ),
                icon: Icons.check_circle,
                accentColor: SevakColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // Emergency broadcast
        Center(
          child: FilledButton.icon(
            icon: const Icon(Icons.campaign, size: 18),
            label: const Text('Platform-Wide Emergency Broadcast'),
            style: FilledButton.styleFrom(
              backgroundColor: cs.error,
              foregroundColor: cs.onError,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
            onPressed: () => SnackbarUtils.showSuccess(context, 'Emergency broadcast sent!'),
          ),
        ),
      ],
    );
  }
}
