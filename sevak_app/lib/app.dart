import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';
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

class SevakApp extends ConsumerWidget {
  const SevakApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'SevakAI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}

final splashDelayProvider = FutureProvider<void>((ref) async {
  await Future.delayed(const Duration(seconds: 2));
});

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final splashDelay = ref.watch(splashDelayProvider);
  final profileAsync = ref.watch(volunteerProfileProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      // Wait for auth + splash
      if (authState.isLoading || splashDelay.isLoading) return '/';

      final isLoggedIn = authState.value != null;
      final loc = state.matchedLocation;
      final isAuthRoute = loc == '/login' || loc == '/register';

      // Not logged in → force login (except splash)
      if (!isLoggedIn && !isAuthRoute) return '/login';

      // Logged in → redirect away from auth routes
      if (isLoggedIn && (isAuthRoute || loc == '/')) {
        return '/home';
      }

      // Route guards — block unauthorized access
      if (isLoggedIn) {
        final profile = profileAsync.value;
        final role = profile?.platformRole ?? 'CU';

        // SA-only routes
        if (loc == '/super-admin' && role != 'SA') return '/home';

        // Dashboard — CO, NA, SA only
        if (loc == '/dashboard' && !['CO', 'NA', 'SA'].contains(role)) {
          return '/home';
        }

        // NGO Admin — NA, SA only
        if (loc.startsWith('/ngo-admin') && !['NA', 'SA'].contains(role)) {
          return '/home';
        }
      }

      return null;
    },
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
        builder: (context, state) => const ProfileSetupPage(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomePage(),
      ),
      // Need submission
      GoRoute(
        path: '/submit-need',
        builder: (context, state) => const SubmitNeedPage(),
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
    ],
  );
});

// ── Splash Screen ────────────────────────────────────────────────────────────

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
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.bgBase,
                  Color(0xFF1E1C44),
                  AppColors.bgBase,
                ],
              ),
            ),
          ),
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryDark.withAlpha(76),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            right: -50,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withAlpha(38),
              ),
            ),
          ),
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/logo_sevak.png',
                      height: 120,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'SevakAI',
                      style:
                          Theme.of(context).textTheme.displayLarge?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                              ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Volunteer Coordination Platform',
                      style:
                          Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 16,
                              ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
