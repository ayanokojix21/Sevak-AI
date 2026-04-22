import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sevak_app/providers/ngo_providers.dart';

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
          title: const Text('Super Admin Platform'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.business_center), text: 'NGO Management'),
              Tab(icon: Icon(Icons.analytics), text: 'Platform Analytics'),
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
        const Text('Pending Approvals', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        pendingAsync.when(
          data: (ngos) => ngos.isEmpty ? const Text('No pending requests') : Column(
            children: ngos.map((ngo) => Card(
              child: ListTile(
                leading: const Icon(Icons.business, color: Colors.orange),
                title: Text(ngo.name),
                subtitle: Text('Requested: ${ngo.createdAt.day}/${ngo.createdAt.month}/${ngo.createdAt.year}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check_circle, color: Colors.green),
                      tooltip: 'Approve',
                      onPressed: () {
                        ref.read(ngosDatasourceProvider).updateNgoStatus(ngo.id, 'active');
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('NGO Approved')));
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      tooltip: 'Reject',
                      onPressed: () {
                        ref.read(ngosDatasourceProvider).updateNgoStatus(ngo.id, 'rejected');
                      },
                    ),
                  ],
                ),
              ),
            )).toList(),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Text('Error: $e'),
        ),
        const SizedBox(height: 24),
        const Text('Active NGOs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        activeAsync.when(
          data: (ngos) => ngos.isEmpty ? const Text('No active NGOs') : Column(
            children: ngos.map((ngo) => ListTile(
              title: Text(ngo.name),
              subtitle: Text('Volunteers: ${ngo.volunteerCount}'),
              trailing: TextButton(
                child: const Text('Suspend', style: TextStyle(color: Colors.red)),
                onPressed: () {
                  ref.read(ngosDatasourceProvider).updateNgoStatus(ngo.id, 'suspended');
                },
              ),
            )).toList(),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Text('Error: $e'),
        ),
      ],
    );
  }
}

class _PlatformAnalyticsTab extends ConsumerWidget {
  const _PlatformAnalyticsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Aggregated Platform Metrics', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard('Total NGOs', '42', Colors.blue),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard('Total Volunteers', '1,204', Colors.purple),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard('Needs Resolved', '8,901', Colors.green),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard('Cross-NGO Tasks', '312', Colors.orange),
              ),
            ],
          ),
          const Spacer(),
          Center(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.campaign),
              label: const Text('Platform-Wide Emergency Broadcast'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade100,
                foregroundColor: Colors.red.shade900,
              ),
              onPressed: () {
                // TODO: Send global FCM broadcast ignoring all opt-outs
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Broadcast sent!')));
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 12, color: color)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
