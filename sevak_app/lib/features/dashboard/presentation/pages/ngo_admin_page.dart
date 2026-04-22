import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sevak_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:sevak_app/features/auth/data/datasources/invite_codes_datasource.dart';

class NgoAdminPage extends ConsumerStatefulWidget {
  final String ngoId;
  const NgoAdminPage({super.key, required this.ngoId});

  @override
  ConsumerState<NgoAdminPage> createState() => _NgoAdminPageState();
}

class _NgoAdminPageState extends ConsumerState<NgoAdminPage> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('NGO Admin Panel'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Staff Management'),
              Tab(text: 'Cross-NGO Settings'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _StaffManagementTab(widget.ngoId),
            const _CrossNgoSettingsTab(),
          ],
        ),
      ),
    );
  }
}

class _StaffManagementTab extends ConsumerWidget {
  final String ngoId;
  const _StaffManagementTab(this.ngoId);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffAsync = ref.watch(ngoStaffProvider(ngoId));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          leading: const Icon(Icons.person_add),
          title: const Text('Invite new Coordinator'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            final codeEnt = await ref.read(inviteCodeDatasourceProvider).generateInviteCode(ngoId, 'CO', true);
            if (!context.mounted) return;
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Coordinator Invite Generated'),
                content: SelectableText('Share this single-use code: ${codeEnt.code}'),
                actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
              ),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.volunteer_activism),
          title: const Text('Generate Volunteer Invite Code'),
          subtitle: const Text('Volunteers can use this code to permanently join your NGO'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            final codeEnt = await ref.read(inviteCodeDatasourceProvider).generateInviteCode(ngoId, 'VL', false);
            if (!context.mounted) return;
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Volunteer Invite Generated'),
                content: SelectableText('Share this multi-use code with your volunteers: ${codeEnt.code}'),
                actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
              ),
            );
          },
        ),
        const Divider(),
        const Text('Current Staff', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        staffAsync.when(
          data: (staff) => staff.isEmpty ? const Text('No active staff found') : Column(
            children: staff.map((member) => ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(member.name),
              subtitle: Text('Role: ${member.platformRole}'),
              trailing: IconButton(
                icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                onPressed: () {
                  // TODO: Demote to VL
                },
              ),
            )).toList(),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Text('Error loading staff'),
        ),
      ],
    );
  }
}

class _CrossNgoSettingsTab extends ConsumerStatefulWidget {
  const _CrossNgoSettingsTab();

  @override
  ConsumerState<_CrossNgoSettingsTab> createState() => _CrossNgoSettingsTabState();
}

class _CrossNgoSettingsTabState extends ConsumerState<_CrossNgoSettingsTab> {
  bool _shareMedical = true;
  bool _shareFood = false;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Partnership Management', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        ListTile(
          leading: const Icon(Icons.handshake),
          title: const Text('Send Partnership Invite'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // TODO: show firestore selection dialog to add new partner
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Partnership invite dialog coming soon')));
          },
        ),
        const Divider(),
        const SizedBox(height: 16),
        const Text('Volunteer Sharing Rules (Opt-in)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        SwitchListTile(
          title: const Text('Share Volunteers for MEDICAL Needs'),
          subtitle: const Text('Allow partner NGOs to match with your medical volunteers'),
          value: _shareMedical,
          onChanged: (val) => setState(() => _shareMedical = val),
        ),
        SwitchListTile(
          title: const Text('Share Volunteers for FOOD Needs'),
          subtitle: const Text('Allow partner NGOs to match with your food distribution volunteers'),
          value: _shareFood,
          onChanged: (val) => setState(() => _shareFood = val),
        ),
      ],
    );
  }
}
