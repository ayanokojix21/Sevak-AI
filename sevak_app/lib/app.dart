import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'core/constants/role_definitions.dart';
import 'features/auth/domain/entities/volunteer.dart';
import 'providers/auth_providers.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/register_page.dart';
import 'features/auth/presentation/pages/profile_setup_page.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/dashboard/presentation/pages/dashboard_page.dart';
import 'features/dashboard/presentation/pages/super_admin_page.dart';
import 'features/dashboard/presentation/pages/ngo_admin_page.dart';
import 'features/needs/presentation/pages/ai_processing_page.dart';
import 'features/needs/presentation/pages/need_confirmation_page.dart';
import 'features/needs/presentation/pages/submit_need_page.dart';
import 'features/ngos/presentation/pages/ngo_discovery_page.dart';
import 'features/ngos/presentation/pages/register_ngo_page.dart';
import 'features/tasks/presentation/pages/my_tasks_page.dart';
import 'features/tasks/presentation/pages/task_detail_page.dart';
import 'features/community_reports/presentation/pages/cu_dashboard_page.dart';
import 'features/community_reports/presentation/pages/submit_community_report_page.dart';

// ── Theme Mode Provider ────────────────────────────────────────────────────
/// Persists the user's chosen brightness. Defaults to system/dark.
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.dark);

class SevakApp extends ConsumerWidget {
  const SevakApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router    = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'SevakAI',
      debugShowCheckedModeBanner: false,
      theme:      AppTheme.lightTheme,
      darkTheme:  AppTheme.darkTheme,
      themeMode:  themeMode,
      routerConfig: router,
    );
  }
}

final splashDelayProvider = FutureProvider<void>((ref) async {
  await Future.delayed(const Duration(seconds: 2));
});

/// Caches latest auth/profile snapshots and exposes them to [GoRouter.redirect].
/// By storing state internally, the redirect closure never touches Riverpod [ref],
/// which prevents the "cannot use ref after dependency changed" crash.
class _RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  AsyncValue<User?> _authState = const AsyncLoading();
  AsyncValue<void> _splashDelay = const AsyncLoading();
  AsyncValue<Volunteer?> _profileState = const AsyncLoading();

  _RouterNotifier(this._ref) {
    // Seed with current values immediately
    _authState = _ref.read(authStateProvider);
    _splashDelay = _ref.read(splashDelayProvider);
    _profileState = _ref.read(volunteerProfileProvider);

    // Keep in sync — when any of these change, cache the new value and wake router
    _ref.listen<AsyncValue<User?>>(authStateProvider, (_, next) {
      _authState = next;
      notifyListeners();
    });
    _ref.listen<AsyncValue<void>>(splashDelayProvider, (_, next) {
      _splashDelay = next;
      notifyListeners();
    });
    _ref.listen<AsyncValue<Volunteer?>>(volunteerProfileProvider, (_, next) {
      _profileState = next;
      notifyListeners();
    });
  }

  /// Pure redirect logic — reads only from cached fields, never from [ref].
  String? redirect(GoRouterState state) {
    // Still loading splash or auth — stay on splash
    if (_authState.isLoading || _splashDelay.isLoading) return '/';

    final isLoggedIn = _authState.value != null;
    final loc = state.matchedLocation;
    final isAuthRoute = loc == '/login' || loc == '/register';

    // Not logged in → force login
    if (!isLoggedIn && !isAuthRoute) return '/login';

    // Logged in → leave splash / auth screens
    if (isLoggedIn && (isAuthRoute || loc == '/')) {
      return '/home';
    }

    // Role guards — only run after profile has resolved
    if (isLoggedIn &&
        _profileState.hasValue &&
        _profileState.value != null) {
      final role = PlatformRoleX.fromCode(_profileState.value!.platformRole);
      if (loc == '/super-admin' && !role.canManagePlatform) return '/home';
      if (loc == '/dashboard' && !role.canAccessDashboard) return '/home';
      if (loc.startsWith('/ngo-admin') && !role.canManageNGO) return '/home';
    }

    return null;
  }
}

final _routerNotifierProvider = ChangeNotifierProvider<_RouterNotifier>(
  (ref) => _RouterNotifier(ref),
);

/// The GoRouter is a TRUE singleton — it is created once and never rebuilt.
/// [ref.read] (not ref.watch) + [ref.keepAlive()] guarantee this.
/// Navigation updates are driven entirely through [refreshListenable].
final routerProvider = Provider<GoRouter>((ref) {
  // keepAlive: prevent Riverpod from ever disposing/rebuilding this provider
  ref.keepAlive();

  // READ (not watch) — so routerProvider is never invalidated by notifier changes
  final notifier = ref.read(_routerNotifierProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: (context, state) => notifier.redirect(state),

    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const _SplashPage(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/profile-setup',
        builder: (context, state) {
          final isEditing =
              state.uri.queryParameters['editing'] == 'true';
          return ProfileSetupPage(isEditing: isEditing);
        },
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomePage(),
      ),
      // Need submission
      GoRoute(
        path: '/submit-need',
        builder: (context, state) {
          final requirePhoto =
              state.uri.queryParameters['requirePhoto'] == 'true';
          return SubmitNeedPage(isPhotoRequired: requirePhoto);
        },
      ),
      GoRoute(
        path: '/ai-processing',
        builder: (context, state) => const AiProcessingPage(),
      ),
      GoRoute(
        path: '/need-confirmation',
        builder: (context, state) => const NeedConfirmationPage(),
      ),
      // Coordinator Dashboard
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardPage(),
      ),
      // Super Admin
      GoRoute(
        path: '/super-admin',
        builder: (context, state) => const SuperAdminPage(),
      ),
      // NGO Admin
      GoRoute(
        path: '/ngo-admin/:id',
        builder: (context, state) {
          final ngoId = state.pathParameters['id']!;
          return NgoAdminPage(ngoId: ngoId);
        },
      ),
      // NGO Discovery & Registration
      GoRoute(
        path: '/discover-ngos',
        builder: (context, state) => const NgoDiscoveryPage(),
      ),
      GoRoute(
        path: '/register-ngo',
        builder: (context, state) => const RegisterNgoPage(),
      ),
      // Volunteer task flow
      GoRoute(
        path: '/my-tasks',
        builder: (context, state) => const MyTasksPage(),
      ),
      GoRoute(
        path: '/task/:id',
        builder: (context, state) {
          final taskId = state.pathParameters['id']!;
          return TaskDetailPage(taskId: taskId);
        },
      ),
      // Community User Flow
      GoRoute(
        path: '/cu-dashboard',
        builder: (context, state) => const CuDashboardPage(),
      ),
      GoRoute(
        path: '/submit-community-report',
        builder: (context, state) => const SubmitCommunityReportPage(),
      ),
    ],
  );
});


class _SplashPage extends StatefulWidget {
  const _SplashPage();

  @override
  State<_SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<_SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo in a Google-style rounded container
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Image.asset(
                      'assets/images/logo_sevak.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'SevakAI',
                  style: tt.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Volunteer Coordination Platform',
                  style: tt.bodyLarge?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: 200,
                  child: LinearProgressIndicator(
                    backgroundColor: cs.surfaceContainerHighest,
                    color: cs.primary,
                    minHeight: 4,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
