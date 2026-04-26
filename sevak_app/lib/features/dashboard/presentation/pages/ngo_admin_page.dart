import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/role_definitions.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../providers/auth_providers.dart';
import '../../../auth/data/datasources/invite_codes_datasource.dart';
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
      length: 4,
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
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _JoinRequestsTab(ngoId: widget.ngoId),
            _MembersTab(ngoId: widget.ngoId),
            _InviteCodesTab(ngoId: widget.ngoId),
            _PartnershipsTab(ngoId: widget.ngoId),
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
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inbox, size: 48, color: AppColors.textDisabled),
                SizedBox(height: 12),
                Text('No pending join requests',
                    style: TextStyle(color: AppColors.textSecondary)),
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
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.primary.withAlpha(25),
                        child: Text(
                          req.userName.isNotEmpty ? req.userName[0].toUpperCase() : '?',
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(req.userName, style: const TextStyle(fontWeight: FontWeight.w600)),
                            Text(req.userEmail,
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (req.message.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.bgElevated,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('"${req.message}"',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontStyle: FontStyle.italic)),
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
                      const SizedBox(width: 10),
                      FilledButton(
                        onPressed: () {
                          ref.read(joinRequestDatasourceProvider).approveRequest(req);
                          SnackbarUtils.showSuccess(context, 'Volunteer approved & added!');
                        },
                        style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
                        child: const Text('Approve', style: TextStyle(color: AppColors.bgBase)),
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
          return const Center(
            child: Text('No members yet', style: TextStyle(color: AppColors.textSecondary)),
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
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: role.color.withAlpha(25),
                  child: Icon(role.icon, color: role.color, size: 20),
                ),
                title: Text(member.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                subtitle: Text(member.email,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
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
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: AppColors.error, size: 20),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Remove Member?'),
                            content: Text('Are you sure you want to remove ${member.name} from this NGO?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                              FilledButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: FilledButton.styleFrom(backgroundColor: AppColors.error),
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
        const Text(
          'Generate invite codes to fast-track volunteers and coordinators into your NGO.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
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
        backgroundColor: AppColors.bgSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Share this code:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.bgElevated,
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
      color: AppColors.bgSurface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
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
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
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
            color: AppColors.bgSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.handshake_outlined, size: 18, color: AppColors.primary),
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
              const SizedBox(height: 12),
              const Text('Share these need types:',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _allSkills.map((skill) {
                  final selected = _selectedSkills.contains(skill);
                  return FilterChip(
                    label: Text(skill, style: TextStyle(
                      fontSize: 11,
                      color: selected ? AppColors.bgBase : AppColors.textSecondary,
                    )),
                    selected: selected,
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.bgElevated,
                    checkmarkColor: AppColors.bgBase,
                    side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
                    onSelected: (val) => setState(() {
                      if (val) _selectedSkills.add(skill);
                      else _selectedSkills.remove(skill);
                    }),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.send, size: 16),
                  label: const Text('Send Invite'),
                  style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
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
        const SizedBox(height: 20),

        const Text('PARTNERSHIPS', style: TextStyle(
          fontSize: 11, fontWeight: FontWeight.w700,
          color: AppColors.textSecondary, letterSpacing: 1.2,
        )),
        const SizedBox(height: 10),
        partnershipsAsync.when(
          data: (partnerships) {
            if (partnerships.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.handshake_outlined, size: 48, color: AppColors.textDisabled),
                      SizedBox(height: 12),
                      Text('No partnerships yet', style: TextStyle(color: AppColors.textSecondary)),
                      SizedBox(height: 4),
                      Text('Send an invite above to start collaborating with other NGOs.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textDisabled, fontSize: 12)),
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
        statusColor = AppColors.success;
        statusLabel = 'ACTIVE';
      case PartnershipStatus.pending:
        statusColor = AppColors.warning;
        statusLabel = 'PENDING';
      case PartnershipStatus.rejected:
        statusColor = AppColors.error;
        statusLabel = 'DECLINED';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.business, size: 16, color: AppColors.textSecondary),
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
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: partnership.sharedSkills.map((s) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.bgElevated,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(s, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
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
                  child: const Text('Decline', style: TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: onAccept,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  child: const Text('Accept', style: TextStyle(color: AppColors.bgBase, fontSize: 12)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
