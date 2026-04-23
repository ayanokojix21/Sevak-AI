import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/role_definitions.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/data/datasources/invite_codes_datasource.dart';
import '../../../ngos/data/datasources/join_request_datasource.dart';
import '../../../../providers/ngo_providers.dart';

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
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('NGO Admin'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () => context.pop(),
          ),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.person_add, size: 18), text: 'Join Requests'),
              Tab(icon: Icon(Icons.people, size: 18), text: 'Members'),
              Tab(icon: Icon(Icons.vpn_key, size: 18), text: 'Invite Codes'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _JoinRequestsTab(ngoId: widget.ngoId),
            _MembersTab(ngoId: widget.ngoId),
            _InviteCodesTab(ngoId: widget.ngoId),
          ],
        ),
      ),
    );
  }
}

// ── Join Requests Tab ────────────────────────────────────────────────────────

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
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Request rejected')),
                          );
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
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Volunteer approved & added!')),
                          );
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

// ── Members Tab ──────────────────────────────────────────────────────────────

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
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: role.color.withAlpha(20),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(role.label,
                      style: TextStyle(color: role.color, fontSize: 10, fontWeight: FontWeight.w600)),
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

// ── Invite Codes Tab ─────────────────────────────────────────────────────────

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
