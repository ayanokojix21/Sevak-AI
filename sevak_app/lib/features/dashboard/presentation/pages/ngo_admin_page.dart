import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
        body: const TabBarView(
          children: [
            _StaffManagementTab(),
            _CrossNgoSettingsTab(),
          ],
        ),
      ),
    );
  }
}

class _StaffManagementTab extends ConsumerWidget {
  const _StaffManagementTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          leading: const Icon(Icons.person_add),
          title: const Text('Invite new Coordinator'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // TODO: map to actual invite function via dynamic links / short codes
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invite dialog coming soon')));
          },
        ),
        const Divider(),
        const Text('Current Staff', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        ListTile(
          leading: const CircleAvatar(child: Icon(Icons.person)),
          title: const Text('Ravi Kumar'),
          subtitle: const Text('Role: Coordinator'),
          trailing: IconButton(
            icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
            onPressed: () {
              // TODO: Remove staff from Firestore
            },
          ),
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
