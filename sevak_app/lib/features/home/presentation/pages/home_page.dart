import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/role_definitions.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../providers/auth_providers.dart';
import '../../../auth/domain/entities/volunteer.dart';
import '../../../tasks/data/services/task_notification_service.dart';
import '../../../../providers/ngo_providers.dart';
import '../../../../providers/task_providers.dart';
import '../../../../providers/community_report_providers.dart';
import '../../../location/data/location_service.dart';
import '../../../../app.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool _gpsEnabled = true;
  bool _locationGranted = true;

  @override
  void initState() {
    super.initState();
    TaskNotificationService.requestPermissions();
    final uid = ref.read(authStateProvider).value?.uid;
    if (uid != null) {
      TaskNotificationService.startTaskListener(uid);
      _initRoleBasedListeners();
      _checkAndUpdateLocation(uid);
    }
  }

  Future<void> _checkAndUpdateLocation(String uid) async {
    final hasPermission = await LocationService.hasLocationPermission();
    if (!hasPermission) {
      final result = await LocationService.requestLocationPermission();
      if (result == LocationPermission.denied || result == LocationPermission.deniedForever) {
        if (mounted) setState(() => _locationGranted = false);
        return;
      }
    }
    final serviceOn = await LocationService.isLocationServiceEnabled();
    if (!serviceOn) {
      if (mounted) setState(() => _gpsEnabled = false);
      return;
    }
    if (mounted) setState(() { _gpsEnabled = true; _locationGranted = true; });
    final success = await LocationService().updateVolunteerLocation(uid);
    if (!success) {
      final stillOn = await LocationService.isLocationServiceEnabled();
      if (mounted && !stillOn) setState(() => _gpsEnabled = false);
    }
  }

  Future<void> _initRoleBasedListeners() async {
    final profile = await ref.read(volunteerProfileProvider.future);
    if (profile != null &&
        (profile.platformRole == 'CO' || profile.platformRole == 'NA' ||
         profile.platformRole == 'coordinator' || profile.platformRole == 'ngo_admin')) {
      TaskNotificationService.startCoordinatorListener(profile.primaryNgoId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final themeMode = ref.watch(themeModeProvider);

    final profileAsync = ref.watch(volunteerProfileProvider);
    return profileAsync.when(
      data: (profile) {
        if (profile == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final role = PlatformRoleX.fromCode(profile.platformRole);

        return Scaffold(
          drawer: _AppDrawer(profile: profile, role: role),
          appBar: AppBar(
            title: Row(
              children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Image.asset('assets/images/logo_sevak.png', fit: BoxFit.contain),
                  ),
                ),
                const SizedBox(width: 10),
                Text('SevakAI', style: tt.titleLarge),
              ],
            ),
            actions: [
              // Theme toggle
              IconButton(
                icon: Icon(
                  themeMode == ThemeMode.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                ),
                tooltip: themeMode == ThemeMode.dark ? 'Switch to Light' : 'Switch to Dark',
                onPressed: () {
                  ref.read(themeModeProvider.notifier).state =
                      themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
                },
              ),
              // Role chip
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: cs.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(role.icon, size: 14, color: cs.onSecondaryContainer),
                    const SizedBox(width: 4),
                    Text(role.label,
                        style: tt.labelSmall?.copyWith(
                          color: cs.onSecondaryContainer,
                          fontWeight: FontWeight.w600,
                        )),
                  ],
                ),
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
                  style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  _subtitleForRole(role, profile.primaryNgoId),
                  style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 24),

                // GPS Warning
                if (!_gpsEnabled || !_locationGranted) ...[
                  Card(
                    color: cs.errorContainer,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Icon(Icons.location_off, color: cs.onErrorContainer),
                            const SizedBox(width: 8),
                            Expanded(child: Text(
                              !_locationGranted ? 'Location permission denied' : 'GPS is turned off',
                              style: tt.titleSmall?.copyWith(color: cs.onErrorContainer, fontWeight: FontWeight.w600),
                            )),
                          ]),
                          const SizedBox(height: 8),
                          Text(
                            !_locationGranted
                                ? 'SevakAI needs location permission to match you with emergencies.'
                                : 'SevakAI needs GPS to match you with nearby emergencies.',
                            style: tt.bodySmall?.copyWith(color: cs.onErrorContainer),
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: () async {
                              if (!_locationGranted) await LocationService.openAppPermissionSettings();
                              else await LocationService.openDeviceLocationSettings();
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: cs.error,
                              foregroundColor: cs.onError,
                            ),
                            icon: const Icon(Icons.settings, size: 16),
                            label: Text(!_locationGranted ? 'Open Settings' : 'Turn On GPS'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // SA SECTION
                if (role == PlatformRole.SA) ...[
                  _SectionHeader(icon: Icons.admin_panel_settings, title: 'Super Admin', cs: cs, tt: tt),
                  const SizedBox(height: 12),
                  _ActionCard(icon: Icons.shield_outlined, title: 'Super Admin Panel',
                    subtitle: 'Approve NGOs, view analytics, manage platform', onTap: () => context.push('/super-admin')),
                  const SizedBox(height: 8),
                  _ActionCard(icon: Icons.map_outlined, title: 'Open Dashboard',
                    subtitle: 'View all needs across the platform', onTap: () => context.push('/dashboard')),
                  const SizedBox(height: 24),
                ],

                // NA SECTION
                if (role == PlatformRole.NA) ...[
                  _SectionHeader(icon: Icons.business, title: 'NGO Admin', cs: cs, tt: tt),
                  const SizedBox(height: 12),
                  if (profile.primaryNgoId.isNotEmpty) ...[
                    _ActionCard(icon: Icons.business_center, title: 'Manage Your NGO',
                      subtitle: 'Staff, invites, join requests',
                      onTap: () => context.push('/ngo-admin/${profile.primaryNgoId}')),
                    Consumer(builder: (context, ref, _) {
                      final requestsAsync = ref.watch(pendingJoinRequestsProvider(profile.primaryNgoId));
                      return requestsAsync.maybeWhen(
                        data: (requests) => requests.isEmpty ? const SizedBox.shrink() : Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: _InfoBanner(icon: Icons.person_add,
                            text: '${requests.length} pending join request${requests.length == 1 ? '' : 's'}',
                            color: SevakColors.warning,
                            onTap: () => context.push('/ngo-admin/${profile.primaryNgoId}')),
                        ),
                        orElse: () => const SizedBox.shrink(),
                      );
                    }),
                    const SizedBox(height: 8),
                    _ActionCard(icon: Icons.map_outlined, title: 'Open Dashboard',
                      subtitle: 'View needs, map, and manage tasks', onTap: () => context.push('/dashboard')),
                  ] else
                    _InfoBanner(icon: Icons.info_outline, text: 'Your NGO is pending approval or not linked yet.', color: SevakColors.warning),
                  const SizedBox(height: 24),
                ],

                // CO SECTION
                if (role == PlatformRole.CO) ...[
                  _SectionHeader(icon: Icons.dashboard_rounded, title: 'Coordinator Dashboard', cs: cs, tt: tt),
                  const SizedBox(height: 12),
                  _ActionCard(icon: Icons.map_outlined, title: 'Open Dashboard',
                    subtitle: 'View needs, map, and manage tasks', onTap: () => context.push('/dashboard')),
                  const SizedBox(height: 24),
                ],

                // VL SECTION
                if (role == PlatformRole.VL) ...[
                  _SectionHeader(icon: Icons.volunteer_activism, title: 'Volunteer', cs: cs, tt: tt),
                  const SizedBox(height: 12),
                  profile.primaryNgoId.isNotEmpty
                    ? _InfoBanner(icon: Icons.badge, text: 'Active member of an NGO', color: cs.primary)
                    : _InfoBanner(icon: Icons.info_outline, text: 'Join an NGO to start receiving tasks', color: SevakColors.warning),
                  const SizedBox(height: 12),
                  Consumer(builder: (context, ref, _) {
                    final tasksAsync = ref.watch(myTasksStreamProvider);
                    final count = tasksAsync.maybeWhen(data: (t) => t.length, orElse: () => 0);
                    return _ActionCard(
                      icon: Icons.task_alt,
                      title: 'My Tasks${count > 0 ? " ($count)" : ""}',
                      subtitle: count > 0 ? '$count active task${count == 1 ? "" : "s"} assigned' : 'No active tasks right now',
                      onTap: () => context.push('/my-tasks'),
                    );
                  }),
                  const SizedBox(height: 12),
                  // Availability toggle — M3 Card style
                  Card(
                    color: cs.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: cs.outlineVariant),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Available for tasks', style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                                Text('Toggle availability for partner NGO tasks',
                                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                              ],
                            ),
                          ),
                          Switch(
                            value: profile.isAvailable,
                            onChanged: (val) {
                              ref.read(userRepositoryProvider).updateCrossNgoConsent(profile.uid, val);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // COMMUNITY ACTIONS
                _SectionHeader(icon: Icons.campaign, title: 'Community Actions', cs: cs, tt: tt),
                const SizedBox(height: 12),
                _ActionCard(icon: Icons.add_circle_outline, title: 'Report a Need',
                  subtitle: 'Submit a community need for AI triage',
                  onTap: () => context.push('/submit-need')),
                const SizedBox(height: 12),

                // CU + VL sections
                if (role == PlatformRole.CU || role == PlatformRole.VL) ...[
                  if (role == PlatformRole.CU) ...[
                    _SectionHeader(icon: Icons.history, title: 'My Emergency Reports', cs: cs, tt: tt),
                    const SizedBox(height: 12),
                    Consumer(builder: (context, ref, _) {
                      final reportsAsync = ref.watch(myCommunityReportsProvider);
                      return reportsAsync.maybeWhen(
                        data: (reports) => reports.isEmpty ? const SizedBox.shrink() : Column(
                          children: reports.take(2).map((report) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _InfoBanner(
                              icon: Icons.assignment_outlined,
                              text: '${report.needType}: ${report.status}',
                              color: report.status == 'PENDING_APPROVAL' ? SevakColors.warning : SevakColors.success,
                              onTap: () => context.push('/cu-dashboard'),
                            ),
                          )).toList(),
                        ),
                        orElse: () => const SizedBox.shrink(),
                      );
                    }),
                    const SizedBox(height: 16),
                  ],
                  _ActionCard(icon: Icons.explore, title: 'Discover NGOs',
                    subtitle: 'Browse and request to join organizations',
                    onTap: () => context.push('/discover-ngos')),
                  const SizedBox(height: 12),
                  _SectionHeader(icon: Icons.vpn_key, title: 'Have an Invite Code?', cs: cs, tt: tt),
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
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }

  String _subtitleForRole(PlatformRole role, String ngoId) {
    switch (role) {
      case PlatformRole.SA: return 'Platform Super Administrator';
      case PlatformRole.NA: return 'NGO Administrator';
      case PlatformRole.CO: return 'Coordinator — Managing needs & tasks';
      case PlatformRole.VL: return ngoId.isNotEmpty ? 'Active Volunteer' : 'Volunteer — Join an NGO to get started';
      case PlatformRole.CU: return 'Community User — Report needs & join NGOs';
    }
  }
}

// ── Section Header ────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final ColorScheme cs;
  final TextTheme tt;

  const _SectionHeader({required this.icon, required this.title, required this.cs, required this.tt});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: cs.primary),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: GoogleFonts.roboto(
            color: cs.primary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

// ── Action Card — M3 Card.filled with InkWell ─────────────────────────────────
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Card(
      color: cs.surfaceContainerLow,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: cs.onPrimaryContainer, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Info Banner ───────────────────────────────────────────────────────────────
class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final VoidCallback? onTap;

  const _InfoBanner({required this.icon, required this.text, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: tt.bodySmall?.copyWith(color: color, fontWeight: FontWeight.w500))),
            if (onTap != null) Icon(Icons.chevron_right, size: 16, color: color),
          ],
        ),
      ),
    );
  }
}

// ── Invite Code Section ───────────────────────────────────────────────────────
class _InviteCodeSection extends ConsumerStatefulWidget {
  @override
  ConsumerState<_InviteCodeSection> createState() => _InviteCodeSectionState();
}

class _InviteCodeSectionState extends ConsumerState<_InviteCodeSection> {
  final _codeController = TextEditingController();
  bool _isRedeeming = false;

  @override
  void dispose() { _codeController.dispose(); super.dispose(); }

  Future<void> _redeemCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;
    setState(() => _isRedeeming = true);
    try {
      await ref.read(authControllerProvider.notifier).consumeInviteCode(code);
      if (!mounted) return;
      _codeController.clear();
      SnackbarUtils.showSuccess(context, 'Invite code redeemed successfully!');
      final profile = ref.read(volunteerProfileProvider).value;
      if (profile != null && profile.skills.isEmpty) {
        if (mounted) context.go('/profile-setup');
      }
    } catch (e) {
      if (mounted) SnackbarUtils.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _isRedeeming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _codeController,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(hintText: 'Enter invite code…'),
          ),
        ),
        const SizedBox(width: 10),
        FilledButton(
          onPressed: _isRedeeming ? null : _redeemCode,
          child: _isRedeeming
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Redeem'),
        ),
      ],
    );
  }
}

// ── Navigation Drawer — M3 NavigationDrawer ───────────────────────────────────
class _AppDrawer extends ConsumerWidget {
  final Volunteer profile;
  final PlatformRole role;

  const _AppDrawer({required this.profile, required this.role});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final name = profile.name.isNotEmpty ? profile.name : 'User';
    final email = profile.email;
    final parts = name.trim().split(' ');
    final initials = parts.length >= 2
        ? '${parts.first[0]}${parts.last[0]}'.toUpperCase()
        : name.substring(0, name.length.clamp(1, 2)).toUpperCase();

    return NavigationDrawer(
      onDestinationSelected: (i) {
        Navigator.pop(context);
        if (i == 0) context.push('/profile-setup?editing=true');
      },
      selectedIndex: -1,
      children: [
        // ── Header ───────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(20, 36, 20, 24),
          color: cs.surfaceContainerHighest,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              CircleAvatar(
                radius: 30,
                backgroundColor: cs.primaryContainer,
                child: Text(
                  initials,
                  style: tt.titleMedium?.copyWith(
                    color: cs.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(name, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              if (email.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(email,
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    overflow: TextOverflow.ellipsis),
              ],
              const SizedBox(height: 10),
              // Role chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: cs.secondaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(role.icon, size: 13, color: cs.onSecondaryContainer),
                    const SizedBox(width: 5),
                    Text(role.label,
                        style: tt.labelSmall?.copyWith(
                          color: cs.onSecondaryContainer,
                          fontWeight: FontWeight.w600,
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // ── Destinations ─────────────────────────────────────────────────
        const NavigationDrawerDestination(
          icon: Icon(Icons.edit_outlined),
          label: Text('Edit Profile'),
        ),

        const Divider(indent: 16, endIndent: 16),

        // Sign Out (manual ListTile for destructive action)
        ListTile(
          leading: Icon(Icons.logout, color: cs.error),
          title: Text('Sign Out',
              style: tt.titleSmall?.copyWith(
                color: cs.error,
                fontWeight: FontWeight.w600,
              )),
          onTap: () async {
            Navigator.pop(context);
            await ref.read(authControllerProvider.notifier).signOut();
          },
        ),

        const Spacer(),

        Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'SevakAI v1.0.0',
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
