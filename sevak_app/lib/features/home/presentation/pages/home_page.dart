import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/role_definitions.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/data/repositories/user_repository.dart';
import '../../../tasks/data/services/task_notification_service.dart';
import '../../../../providers/ngo_providers.dart';
import '../../../../providers/task_providers.dart';

/// Role-aware home page — renders role-specific content sections.
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();
    // Start Firestore listener for task notifications (Phase 4F)
    final uid = ref.read(authStateProvider).value?.uid;
    if (uid != null) {
      TaskNotificationService.startTaskListener(uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(volunteerProfileProvider);
    return profileAsync.when(
      data: (profile) {
        if (profile == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final role = PlatformRoleX.fromCode(profile.platformRole);

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Image.asset('assets/images/logo_sevak.png', height: 28),
                const SizedBox(width: 10),
                const Text('SevakAI'),
              ],
            ),
            actions: [
              // Role badge
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: role.color.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: role.color.withAlpha(80)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(role.icon, size: 14, color: role.color),
                    const SizedBox(width: 4),
                    Text(role.label,
                        style: TextStyle(color: role.color, fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  await ref.read(authControllerProvider.notifier).signOut();
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome
                Text(
                  'Welcome, ${profile.name.isNotEmpty ? profile.name : 'User'} 👋',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  _subtitleForRole(role, profile.primaryNgoId),
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 24),

                // ══════════════════════════════════════════════════════════════
                // SA SECTION — Super Admin Panel
                // ══════════════════════════════════════════════════════════════
                if (role == PlatformRole.SA) ...[
                  _SectionHeader(icon: Icons.admin_panel_settings, title: 'Super Admin', color: role.color),
                  const SizedBox(height: 12),
                  _ActionCard(
                    icon: Icons.shield_outlined,
                    title: 'Super Admin Panel',
                    subtitle: 'Approve NGOs, view analytics, manage platform',
                    color: PlatformRole.SA.color,
                    onTap: () => context.push('/super-admin'),
                  ),
                  const SizedBox(height: 12),
                  // SA can also access Dashboard to view all needs
                  _ActionCard(
                    icon: Icons.map_outlined,
                    title: 'Open Dashboard',
                    subtitle: 'View all needs across the platform',
                    color: PlatformRole.CO.color,
                    onTap: () => context.push('/dashboard'),
                  ),
                  const SizedBox(height: 24),
                ],

                // ══════════════════════════════════════════════════════════════
                // NA SECTION — NGO Admin (not shown for SA, SA has own panel)
                // ══════════════════════════════════════════════════════════════
                if (role == PlatformRole.NA) ...[
                  _SectionHeader(icon: Icons.business, title: 'NGO Admin', color: role.color),
                  const SizedBox(height: 12),
                  if (profile.primaryNgoId.isNotEmpty) ...[
                    _ActionCard(
                      icon: Icons.business_center,
                      title: 'Manage Your NGO',
                      subtitle: 'Staff, invites, join requests',
                      color: PlatformRole.NA.color,
                      onTap: () => context.push('/ngo-admin/${profile.primaryNgoId}'),
                    ),
                    // Pending join requests badge
                    Consumer(builder: (context, ref, _) {
                      final requestsAsync = ref.watch(
                          pendingJoinRequestsProvider(profile.primaryNgoId));
                      return requestsAsync.when(
                        data: (requests) {
                          if (requests.isEmpty) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: _InfoBanner(
                              icon: Icons.person_add,
                              text: '${requests.length} pending join request${requests.length == 1 ? '' : 's'}',
                              color: AppColors.warning,
                              onTap: () => context.push('/ngo-admin/${profile.primaryNgoId}'),
                            ),
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      );
                    }),
                    const SizedBox(height: 12),
                    _ActionCard(
                      icon: Icons.map_outlined,
                      title: 'Open Dashboard',
                      subtitle: 'View needs, map, and manage tasks',
                      color: PlatformRole.CO.color,
                      onTap: () => context.push('/dashboard'),
                    ),
                  ] else ...[
                    _InfoBanner(
                      icon: Icons.info_outline,
                      text: 'Your NGO is pending approval or not linked yet.',
                      color: AppColors.warning,
                    ),
                  ],
                  const SizedBox(height: 24),
                ],

                // ══════════════════════════════════════════════════════════════
                // CO SECTION — Coordinator Dashboard
                // ══════════════════════════════════════════════════════════════
                if (role == PlatformRole.CO) ...[
                  _SectionHeader(icon: Icons.dashboard_rounded, title: 'Coordinator Dashboard', color: PlatformRole.CO.color),
                  const SizedBox(height: 12),
                  _ActionCard(
                    icon: Icons.map_outlined,
                    title: 'Open Dashboard',
                    subtitle: 'View needs, map, and manage tasks',
                    color: PlatformRole.CO.color,
                    onTap: () => context.push('/dashboard'),
                  ),
                  const SizedBox(height: 24),
                ],

                // ══════════════════════════════════════════════════════════════
                // VL SECTION — Volunteer controls
                // ══════════════════════════════════════════════════════════════
                if (role == PlatformRole.VL) ...[
                  _SectionHeader(icon: Icons.volunteer_activism, title: 'Volunteer', color: PlatformRole.VL.color),
                  const SizedBox(height: 12),
                  if (profile.primaryNgoId.isNotEmpty)
                    _InfoBanner(
                      icon: Icons.badge,
                      text: 'Active member of an NGO',
                      color: PlatformRole.VL.color,
                    )
                  else
                    _InfoBanner(
                      icon: Icons.info_outline,
                      text: 'Join an NGO to start receiving tasks',
                      color: AppColors.warning,
                    ),
                  const SizedBox(height: 12),

                  // My Tasks card with real-time badge count
                  Consumer(builder: (context, ref, _) {
                    final tasksAsync = ref.watch(myTasksStreamProvider);
                    final count = tasksAsync.maybeWhen(data: (t) => t.length, orElse: () => 0);
                    return _ActionCard(
                      icon: Icons.task_alt,
                      title: 'My Tasks${count > 0 ? " ($count)" : ""}',
                      subtitle: count > 0
                          ? '$count active task${count == 1 ? "" : "s"} assigned to you'
                          : 'No active tasks right now',
                      color: PlatformRole.VL.color,
                      onTap: () => context.push('/my-tasks'),
                    );
                  }),
                  const SizedBox(height: 12),

                  // Availability toggle
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.bgSurface.withAlpha(120),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Available for tasks',
                                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                  SizedBox(height: 2),
                                  Text('Toggle your availability for partner NGO tasks',
                                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                ],
                              ),
                            ),
                            Switch(
                              value: profile.isAvailable,
                              activeTrackColor: AppColors.accent.withAlpha(100),
                              activeColor: AppColors.accent,
                              onChanged: (val) {
                                ref.read(userRepositoryProvider).updateCrossNgoConsent(profile.uid, val);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // ══════════════════════════════════════════════════════════════
                // COMMUNITY ACTIONS (everyone can report needs)
                // ══════════════════════════════════════════════════════════════
                _SectionHeader(icon: Icons.campaign, title: 'Community Actions', color: AppColors.accent),
                const SizedBox(height: 12),
                _ActionCard(
                  icon: Icons.add_circle_outline,
                  title: 'Report a Need',
                  subtitle: 'Submit a new community need for AI triage',
                  color: AppColors.accent,
                  onTap: () => context.push('/submit-need'),
                ),
                const SizedBox(height: 12),

                // ══════════════════════════════════════════════════════════════
                // DISCOVER NGOs — CU and VL only (SA/NA/CO already have NGO)
                // ══════════════════════════════════════════════════════════════
                if (role == PlatformRole.CU || role == PlatformRole.VL) ...[
                  _ActionCard(
                    icon: Icons.explore,
                    title: 'Discover NGOs',
                    subtitle: 'Browse and request to join organizations',
                    color: AppColors.primary,
                    onTap: () => context.push('/discover-ngos'),
                  ),
                  const SizedBox(height: 12),
                ],

                // ══════════════════════════════════════════════════════════════
                // INVITE CODE — CU and VL only
                // ══════════════════════════════════════════════════════════════
                if (role == PlatformRole.CU || role == PlatformRole.VL) ...[
                  const SizedBox(height: 12),
                  _SectionHeader(icon: Icons.vpn_key, title: 'Have an Invite Code?', color: AppColors.textSecondary),
                  const SizedBox(height: 12),
                  _InviteCodeSection(),
                ],

                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error loading profile: $e'))),
    );
  }

  String _subtitleForRole(PlatformRole role, String ngoId) {
    switch (role) {
      case PlatformRole.SA:
        return 'Platform Super Administrator';
      case PlatformRole.NA:
        return 'NGO Administrator';
      case PlatformRole.CO:
        return 'Coordinator — Managing needs & tasks';
      case PlatformRole.VL:
        return ngoId.isNotEmpty ? 'Active Volunteer' : 'Volunteer — Join an NGO to get started';
      case PlatformRole.CU:
        return 'Community User — Report needs & join NGOs';
    }
  }
}

// ── Reusable Widgets ─────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _SectionHeader({required this.icon, required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
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
                width: 44,
                height: 44,
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
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: color.withAlpha(120)),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final VoidCallback? onTap;

  const _InfoBanner({required this.icon, required this.text, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w500))),
            if (onTap != null) Icon(Icons.chevron_right, size: 16, color: color),
          ],
        ),
      ),
    );
  }
}

class _InviteCodeSection extends ConsumerStatefulWidget {
  @override
  ConsumerState<_InviteCodeSection> createState() => _InviteCodeSectionState();
}

class _InviteCodeSectionState extends ConsumerState<_InviteCodeSection> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    ref.listen<AsyncValue<void>>(authControllerProvider, (prev, next) {
      if (next.hasError) {
        SnackbarUtils.showError(context, next.error.toString());
      }
      if (prev?.isLoading == true && next.hasValue && !next.isLoading) {
        _codeController.clear();
        SnackbarUtils.showSuccess(context, 'Invite code redeemed successfully!');
      }
    });

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _codeController,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              hintText: 'Enter code...',
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          height: 48,
          child: FilledButton(
            onPressed: authState.isLoading
                ? null
                : () {
                    final code = _codeController.text.trim();
                    if (code.isEmpty) return;
                    ref.read(authControllerProvider.notifier).consumeInviteCode(code);
                  },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: authState.isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Redeem', style: TextStyle(color: AppColors.bgBase, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}
