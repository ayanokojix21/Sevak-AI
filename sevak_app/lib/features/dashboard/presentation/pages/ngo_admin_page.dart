import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/role_definitions.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../providers/auth_providers.dart';
import '../../../ngos/data/datasources/join_request_datasource.dart';
import '../../../partnerships/domain/entities/partnership_entity.dart';
import '../../../partnerships/data/models/partnership_model.dart';
import '../../../../providers/ngo_providers.dart';
import '../../../../providers/partnership_providers.dart';

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
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('NGO Admin'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () => context.pop(),
          ),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.person_add, size: 18), text: 'Join Requests'),
              Tab(icon: Icon(Icons.people, size: 18), text: 'Members'),
              Tab(icon: Icon(Icons.vpn_key, size: 18), text: 'Invite Codes'),
              Tab(icon: Icon(Icons.handshake_outlined, size: 18), text: 'Partnerships'),
              Tab(icon: Icon(Icons.settings_rounded, size: 18), text: 'Settings'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _JoinRequestsTab(ngoId: widget.ngoId),
            _MembersTab(ngoId: widget.ngoId),
            _InviteCodesTab(ngoId: widget.ngoId),
            _PartnershipsTab(ngoId: widget.ngoId),
            _SettingsTab(ngoId: widget.ngoId),
          ],
        ),
      ),
    );
  }
}


class _JoinRequestsTab extends ConsumerWidget {
  final String ngoId;
  const _JoinRequestsTab({required this.ngoId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(pendingJoinRequestsProvider(ngoId));

    return requestsAsync.when(
      data: (requests) {
        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inbox, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant),
                SizedBox(height: 12),
                Text('No pending join requests',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (_, i) {
            final req = requests[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        child: Text(
                          req.userName.isNotEmpty ? req.userName[0].toUpperCase() : '?',
                          style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(req.userName, style: const TextStyle(fontWeight: FontWeight.w600)),
                            Text(req.userEmail,
                                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (req.message.isNotEmpty) ...[
                    SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('"${req.message}"',
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13, fontStyle: FontStyle.italic)),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () {
                          ref.read(joinRequestDatasourceProvider).rejectRequest(req.id);
                          SnackbarUtils.showError(context, 'Request rejected');
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.red.shade300),
                          foregroundColor: Colors.red.shade300,
                        ),
                        child: const Text('Reject'),
                      ),
                      SizedBox(width: 10),
                      FilledButton(
                        onPressed: () {
                          ref.read(joinRequestDatasourceProvider).approveRequest(req);
                          SnackbarUtils.showSuccess(context, 'Volunteer approved & added!');
                        },
                        style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
                        child: const Text('Approve', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}


class _MembersTab extends ConsumerWidget {
  final String ngoId;
  const _MembersTab({required this.ngoId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(ngoMembersProvider(ngoId));

    return membersAsync.when(
      data: (members) {
        if (members.isEmpty) {
          return Center(
            child: Text('No members yet', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: members.length,
          itemBuilder: (_, i) {
            final member = members[i];
            final role = PlatformRoleX.fromCode(member.platformRole);

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: role.color.withAlpha(25),
                  child: Icon(role.icon, color: role.color, size: 20),
                ),
                title: Text(member.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                subtitle: Text(member.email,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: role.color.withAlpha(20),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(role.label,
                          style: TextStyle(color: role.color, fontSize: 10, fontWeight: FontWeight.w600)),
                    ),
                    SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.remove_circle_outline, color: Theme.of(context).colorScheme.error, size: 20),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Remove Member?'),
                            content: Text('Are you sure you want to remove ${member.name} from this NGO?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel')),
                              FilledButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
                                child: const Text('Remove'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await ref.read(userRepositoryProvider).removeNgoMembership(member.uid, ngoId);
                          if (context.mounted) {
                            SnackbarUtils.showSuccess(context, 'Member removed');
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}


class _InviteCodesTab extends ConsumerWidget {
  final String ngoId;
  const _InviteCodesTab({required this.ngoId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Generate invite codes to fast-track volunteers and coordinators into your NGO.',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
        ),
        const SizedBox(height: 20),

        // Coordinator invite
        _InviteButton(
          icon: Icons.dashboard_rounded,
          title: 'Coordinator Invite',
          subtitle: 'Single-use code for a new coordinator',
          color: PlatformRole.CO.color,
          onTap: () async {
            final code = await ref.read(inviteCodeDatasourceProvider)
                .generateInviteCode(ngoId, 'CO', true);
            if (!context.mounted) return;
            _showCodeDialog(context, 'Coordinator Invite', code.code);
          },
        ),
        const SizedBox(height: 12),

        // Volunteer invite
        _InviteButton(
          icon: Icons.volunteer_activism,
          title: 'Volunteer Invite',
          subtitle: 'Multi-use code for volunteers',
          color: PlatformRole.VL.color,
          onTap: () async {
            final code = await ref.read(inviteCodeDatasourceProvider)
                .generateInviteCode(ngoId, 'VL', false);
            if (!context.mounted) return;
            _showCodeDialog(context, 'Volunteer Invite', code.code);
          },
        ),
      ],
    );
  }

  void _showCodeDialog(BuildContext context, String title, String code) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Share this code:', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13)),
            SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SelectableText(
                code,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 4),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}

class _InviteButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _InviteButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(subtitle, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.add_circle_outline, color: color),
            ],
          ),
        ),
      ),
    );
  }
}


class _PartnershipsTab extends ConsumerStatefulWidget {
  final String ngoId;
  const _PartnershipsTab({required this.ngoId});

  @override
  ConsumerState<_PartnershipsTab> createState() => _PartnershipsTabState();
}

class _PartnershipsTabState extends ConsumerState<_PartnershipsTab> {
  final _targetNgoController = TextEditingController();
  final List<String> _selectedSkills = [];
  static const _allSkills = ['FOOD', 'MEDICAL', 'SHELTER', 'CLOTHING', 'OTHER'];

  @override
  void dispose() {
    _targetNgoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final partnershipsAsync = ref.watch(partnershipsStreamProvider(widget.ngoId));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.handshake_outlined, size: 18, color: Theme.of(context).colorScheme.primary),
                  SizedBox(width: 8),
                  Text('Send Partnership Invite',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _targetNgoController,
                decoration: const InputDecoration(
                  hintText: 'Partner NGO ID',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              SizedBox(height: 12),
              Text('Share these need types:',
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _allSkills.map((skill) {
                  final selected = _selectedSkills.contains(skill);
                  return FilterChip(
                    label: Text(skill, style: TextStyle(
                      fontSize: 11,
                      color: selected ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
                    )),
                    selected: selected,
                    selectedColor: Theme.of(context).colorScheme.primary,
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    checkmarkColor: Colors.white,
                    side: BorderSide(color: selected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outlineVariant),
                    onSelected: (val) => setState(() {
                      if (val) _selectedSkills.add(skill);
                      else _selectedSkills.remove(skill);
                    }),
                  );
                }).toList(),
              ),
              SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.send, size: 16),
                  label: const Text('Send Invite'),
                  style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
                  onPressed: () async {
                    final targetId = _targetNgoController.text.trim();
                    if (targetId.isEmpty || _selectedSkills.isEmpty) {
                      SnackbarUtils.showError(context, 'Enter partner NGO ID and select at least one skill');
                      return;
                    }
                    await ref.read(sendPartnershipInviteUseCaseProvider).call(
                      senderNgoId: widget.ngoId,
                      targetNgoId: targetId,
                      sharedSkills: List.from(_selectedSkills),
                    );
                    _targetNgoController.clear();
                    _selectedSkills.clear();
                    if (!context.mounted) return;
                    SnackbarUtils.showSuccess(context, 'Partnership invite sent!');
                  },
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 20),

        Text('PARTNERSHIPS', style: TextStyle(
          fontSize: 11, fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurfaceVariant, letterSpacing: 1.2,
        )),
        const SizedBox(height: 10),
        partnershipsAsync.when(
          data: (partnerships) {
            if (partnerships.isEmpty) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.handshake_outlined, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      SizedBox(height: 12),
                      Text('No partnerships yet', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      SizedBox(height: 4),
                      Text('Send an invite above to start collaborating with other NGOs.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
                    ],
                  ),
                ),
              );
            }
            return Column(
              children: partnerships.map((p) => _PartnershipCard(
                partnership: p,
                myNgoId: widget.ngoId,
                onAccept: () async {
                  await ref.read(acceptPartnershipUseCaseProvider).call(p.id);
                  if (!context.mounted) return;
                  SnackbarUtils.showSuccess(context, 'Partnership accepted!');
                },
                onDecline: () async {
                  await ref.read(partnershipsDatasourceProvider)
                      .updatePartnershipStatus(p.id, 'rejected');
                  if (!context.mounted) return;
                  SnackbarUtils.showError(context, 'Partnership declined');
                },
              )).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ],
    );
  }
}

class _PartnershipCard extends StatelessWidget {
  final PartnershipModel partnership;
  final String myNgoId;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  const _PartnershipCard({
    required this.partnership,
    required this.myNgoId,
    this.onAccept,
    this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final isIncoming = partnership.ngoB == myNgoId && partnership.status == PartnershipStatus.pending;
    final partnerNgoId = partnership.ngoA == myNgoId ? partnership.ngoB : partnership.ngoA;

    Color statusColor;
    String statusLabel;
    switch (partnership.status) {
      case PartnershipStatus.active:
        statusColor = SevakColors.success;
        statusLabel = 'ACTIVE';
      case PartnershipStatus.pending:
        statusColor = SevakColors.warning;
        statusLabel = 'PENDING';
      case PartnershipStatus.rejected:
        statusColor = Theme.of(context).colorScheme.error;
        statusLabel = 'DECLINED';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.business, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Expanded(
                child: Text('Partner: $partnerNgoId',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusColor.withAlpha(80)),
                ),
                child: Text(statusLabel,
                    style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          if (partnership.sharedSkills.isNotEmpty) ...[
            SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: partnership.sharedSkills.map((s) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(s, style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              )).toList(),
            ),
          ],
          if (isIncoming) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: onDecline,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.red.shade300),
                    foregroundColor: Colors.red.shade300,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  child: Text('Decline', style: TextStyle(fontSize: 12)),
                ),
                SizedBox(width: 8),
                FilledButton(
                  onPressed: onAccept,
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  child: const Text('Accept', style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}


// ─── Settings Tab ─────────────────────────────────────────────────────────────

class _SettingsTab extends ConsumerStatefulWidget {
  final String ngoId;
  const _SettingsTab({required this.ngoId});

  @override
  ConsumerState<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends ConsumerState<_SettingsTab> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  bool _initialized = false;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final ds = ref.watch(ngosDatasourceProvider);

    return StreamBuilder(
      stream: ds.streamNgoById(widget.ngoId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final ngo = snapshot.data;
        if (ngo == null) {
          return Center(
            child: Text('NGO not found', style: TextStyle(color: cs.onSurfaceVariant)),
          );
        }

        if (!_initialized) {
          _nameCtrl.text = ngo.name;
          _descCtrl.text = ngo.description;
          _cityCtrl.text = ngo.city;
          _initialized = true;
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── NGO Info Card ─────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: cs.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.business_rounded, color: cs.primary, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(ngo.name, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: ngo.status == 'active'
                                        ? SevakColors.success.withAlpha(25)
                                        : SevakColors.warning.withAlpha(25),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    ngo.status.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: ngo.status == 'active' ? SevakColors.success : SevakColors.warning,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text('${ngo.volunteerCount} members',
                                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.tag, size: 14, color: cs.onSurfaceVariant),
                        const SizedBox(width: 6),
                        Text('NGO ID: ', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                        Expanded(
                          child: SelectableText(
                            widget.ngoId,
                            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant, fontFamily: 'monospace'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Edit Section ──────────────────────────────────────────
            Text('EDIT NGO DETAILS', style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700,
              color: cs.onSurfaceVariant, letterSpacing: 1.2,
            )),
            const SizedBox(height: 12),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'NGO Name',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                prefixIcon: Icon(Icons.description_outlined),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _cityCtrl,
              decoration: const InputDecoration(
                labelText: 'City',
                prefixIcon: Icon(Icons.location_city_outlined),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _saving ? null : _saveChanges,
                icon: _saving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save_rounded, size: 18),
                label: Text(_saving ? 'Saving...' : 'Save Changes'),
              ),
            ),
            const SizedBox(height: 32),

            // ── Danger Zone ───────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.errorContainer.withAlpha(30),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cs.error.withAlpha(60)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_rounded, color: cs.error, size: 18),
                      const SizedBox(width: 8),
                      Text('Danger Zone',
                          style: tt.titleSmall?.copyWith(color: cs.error, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Disbanding will permanently delete your NGO. All members will lose access. This cannot be undone.',
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _confirmDisband,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: cs.error),
                        foregroundColor: cs.error,
                      ),
                      icon: const Icon(Icons.delete_forever_rounded, size: 18),
                      label: const Text('Disband NGO'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        );
      },
    );
  }

  Future<void> _saveChanges() async {
    if (_nameCtrl.text.trim().isEmpty) {
      SnackbarUtils.showError(context, 'NGO name cannot be empty');
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(ngosDatasourceProvider).updateNgoFields(widget.ngoId, {
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'city': _cityCtrl.text.trim(),
      });
      if (mounted) SnackbarUtils.showSuccess(context, 'NGO details updated!');
    } catch (e) {
      if (mounted) SnackbarUtils.showError(context, 'Failed: $e');
    }
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _confirmDisband() async {
    final cs = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_rounded, color: cs.error),
            const SizedBox(width: 8),
            const Text('Disband NGO?'),
          ],
        ),
        content: const Text(
          'This will permanently delete your NGO and remove all members. Are you absolutely sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: cs.error),
            child: const Text('Yes, Disband'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref.read(ngosDatasourceProvider).disbandNgo(widget.ngoId);
        await ref.read(userRepositoryProvider).removeNgoMembership(
          ref.read(authStateProvider).value!.uid,
          widget.ngoId,
        );
        if (mounted) {
          SnackbarUtils.showSuccess(context, 'NGO disbanded');
          context.go('/home');
        }
      } catch (e) {
        if (mounted) SnackbarUtils.showError(context, 'Failed: $e');
      }
    }
  }
}