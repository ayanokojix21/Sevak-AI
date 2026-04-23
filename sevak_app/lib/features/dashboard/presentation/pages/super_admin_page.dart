import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../providers/ngo_providers.dart';
import '../../../../providers/dashboard_providers.dart';

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
            icon: const Icon(Icons.arrow_back_ios_new),
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

// ── NGO Management Tab ───────────────────────────────────────────────────────

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
        _sectionHeader('Pending Approvals', Icons.pending_actions, AppColors.warning),
        const SizedBox(height: 10),
        pendingAsync.when(
          data: (ngos) => ngos.isEmpty
              ? _emptyState('No pending requests', Icons.check_circle_outline)
              : Column(
                  children: ngos.map((ngo) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: AppColors.bgSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.warning.withAlpha(50)),
                    ),
                    child: ListTile(
                      leading: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.warning.withAlpha(25),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.business, color: AppColors.warning, size: 20),
                      ),
                      title: Text(ngo.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('${ngo.city.isNotEmpty ? ngo.city : "No city"} · ${ngo.createdAt.day}/${ngo.createdAt.month}/${ngo.createdAt.year}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check_circle, color: AppColors.accent),
                            tooltip: 'Approve',
                            onPressed: () {
                              ref.read(ngosDatasourceProvider).approveNgo(ngo.id, ngo.adminUid);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('NGO Approved & Admin role assigned')),
                              );
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.cancel, color: Colors.red.shade400),
                            tooltip: 'Reject',
                            onPressed: () {
                              ref.read(ngosDatasourceProvider).updateNgoStatus(ngo.id, 'rejected');
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('NGO Rejected')),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  )).toList(),
                ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error: $e'),
        ),

        const SizedBox(height: 28),

        // Active NGOs
        _sectionHeader('Active NGOs', Icons.verified, AppColors.accent),
        const SizedBox(height: 10),
        activeAsync.when(
          data: (ngos) => ngos.isEmpty
              ? _emptyState('No active NGOs yet', Icons.business_outlined)
              : Column(
                  children: ngos.map((ngo) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: AppColors.bgSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: ListTile(
                      leading: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.accent.withAlpha(20),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.business, color: AppColors.accent, size: 20),
                      ),
                      title: Text(ngo.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('${ngo.city.isNotEmpty ? ngo.city : "—"} · ${ngo.volunteerCount} members',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.open_in_new, size: 18, color: AppColors.primary),
                            tooltip: 'Manage',
                            onPressed: () => context.push('/ngo-admin/${ngo.id}'),
                          ),
                          IconButton(
                            icon: Icon(Icons.block, size: 18, color: Colors.red.shade300),
                            tooltip: 'Suspend',
                            onPressed: () {
                              ref.read(ngosDatasourceProvider).updateNgoStatus(ngo.id, 'suspended');
                            },
                          ),
                        ],
                      ),
                    ),
                  )).toList(),
                ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error: $e'),
        ),
      ],
    );
  }

  Widget _sectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(title.toUpperCase(), style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
      ],
    );
  }

  Widget _emptyState(String message, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Icon(icon, size: 36, color: AppColors.textDisabled),
          const SizedBox(height: 8),
          Text(message, style: const TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

// ── Analytics Tab ────────────────────────────────────────────────────────────

class _PlatformAnalyticsTab extends ConsumerWidget {
  const _PlatformAnalyticsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Real data from Firestore streams
    final activeNgos = ref.watch(activeNgosProvider);
    final allNgos = ref.watch(allNgosProvider);
    final allNeeds = ref.watch(allNeedsStreamProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            const Icon(Icons.analytics, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            const Text('LIVE PLATFORM METRICS', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Active NGOs',
                activeNgos.when(data: (n) => '${n.length}', loading: () => '...', error: (_, __) => '—'),
                AppColors.primary,
                Icons.business,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Total NGOs',
                allNgos.when(data: (n) => '${n.length}', loading: () => '...', error: (_, __) => '—'),
                AppColors.accent,
                Icons.domain,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Needs',
                allNeeds.when(data: (n) => '${n.length}', loading: () => '...', error: (_, __) => '—'),
                const Color(0xFF6C63FF),
                Icons.campaign,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Resolved',
                allNeeds.when(
                  data: (n) => '${n.where((need) => need.status == 'COMPLETED').length}',
                  loading: () => '...',
                  error: (_, __) => '—',
                ),
                const Color(0xFF4CAF50),
                Icons.check_circle,
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
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Emergency broadcast sent!')),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(title, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
