import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Admin pages
import 'package:smart_waste_app/features/admin/presentation/pages/admin_broadcast_screen.dart';
import 'package:smart_waste_app/features/admin/presentation/pages/admin_schedule_manage_screen.dart';
import 'package:smart_waste_app/features/admin/presentation/pages/admin_alert_form_screen.dart';
import 'package:smart_waste_app/features/admin/data/models/admin_alert_hive_model.dart';

// Alerts
import 'package:smart_waste_app/features/alerts/presentation/pages/alerts_hub_screen.dart';

// Reports
import 'package:smart_waste_app/features/reports/presentation/pages/report_form_screen.dart';
import 'package:smart_waste_app/features/reports/presentation/pages/reports_screen.dart';
import 'package:smart_waste_app/features/reports/data/models/report_hive_model.dart';

// Auth
import 'package:smart_waste_app/features/auth/presentation/pages/login_screen.dart';
import 'package:smart_waste_app/features/auth/presentation/pages/signup_screen.dart';
import 'package:smart_waste_app/features/auth/presentation/providers/auth_providers.dart';

// Dashboard
import 'package:smart_waste_app/features/dashboard/presentation/pages/dashboard_shell.dart';
import 'package:smart_waste_app/features/dashboard/presentation/pages/home_screen.dart';
import 'package:smart_waste_app/features/dashboard/presentation/pages/profile_screen.dart';
import 'package:smart_waste_app/features/dashboard/presentation/pages/schedule_screen.dart';
import 'package:smart_waste_app/features/dashboard/presentation/pages/splash_screen.dart';

// Onboarding + Settings
import 'package:smart_waste_app/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:smart_waste_app/features/settings/presentation/pages/settings_screen.dart';
import 'package:smart_waste_app/features/settings/presentation/providers/settings_providers.dart';

// ✅ App Router Provider
final appRouterProvider = Provider<GoRouter>((ref) {
  final authAsync = ref.watch(authStateProvider);
  final onboardedAsync = ref.watch(isOnboardedProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshNotifier(ref),
    redirect: (context, state) {
      final loc = state.matchedLocation;

      final isSplash = loc == '/splash';
      final isOnboarding = loc == '/onboarding';
      final isAuth = loc.startsWith('/auth');
      final isAdmin = loc.startsWith('/admin');
      final isAlertsCreate = loc == '/alerts/create';
      final isReportsCreate = loc == '/reports/create';
      final isReportsList = loc == '/reports';
      final isShell =
          loc == '/home' ||
          loc == '/schedule' ||
          loc == '/alerts' ||
          loc.startsWith('/profile');
      final isSettings = loc == '/settings';

      // ✅ 0) If auth OR onboarding still loading -> stay on splash
      final stillLoading = authAsync.isLoading || onboardedAsync.isLoading;
      if (stillLoading) {
        return isSplash ? null : '/splash';
      }

      // ✅ resolve actual values only AFTER loading is finished
      final onboarded = onboardedAsync.value ?? false;
      final auth = authAsync.valueOrNull;
      final loggedIn = auth?.isLoggedIn ?? false;
      final userIsAdmin = auth?.session?.role == 'admin_driver';

      // 1) Always allow splash (when not loading, splash can redirect away)
      // NOTE: we already handled loading above

      // 2) Not onboarded -> force onboarding
      if (!onboarded) {
        return isOnboarding ? null : '/onboarding';
      }

      // 3) Onboarded but not logged in -> force login
      if (!loggedIn) {
        return isAuth ? null : '/auth/login';
      }

      // 4) Logged in -> block onboarding/auth pages
      if (loggedIn && (isOnboarding || isAuth)) {
        return '/home';
      }

      // 5) Admin route protection
      if (isAdmin && !userIsAdmin) return '/home';
      if (isAlertsCreate && !userIsAdmin) return '/home';

      // 6) Allowed routes
      if (isShell ||
          isSettings ||
          isReportsList ||
          (isAdmin && userIsAdmin) ||
          isAlertsCreate ||
          isReportsCreate) {
        return null;
      }

      return '/home';
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingPage()),
      GoRoute(path: '/auth/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/auth/signup', builder: (_, __) => const SignupScreen()),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      GoRoute(path: '/reports', builder: (_, __) => const ReportsScreen()),

      // NOTE: Schedule is a bottom-tab route (see shell branches).

      GoRoute(
        path: '/admin/broadcast',
        builder: (_, __) => const AdminBroadcastScreen(),
      ),
      GoRoute(
        path: '/admin/schedule',
        builder: (_, __) => const AdminScheduleManageScreen(),
      ),

      GoRoute(
        path: '/alerts/create',
        builder: (context, state) {
          final extra = state.extra;
          return AdminAlertFormScreen(
            existing: extra is AdminAlertHiveModel ? extra : null,
          );
        },
      ),
      GoRoute(
        path: '/reports/create',
        builder: (context, state) {
          final extra = state.extra;
          return ReportFormScreen(
            existing: extra is ReportHiveModel ? extra : null,
          );
        },
      ),

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return DashboardShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/schedule',
                builder: (_, __) => const ScheduleScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/alerts', builder: (_, __) => const AlertsHubScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (_, __) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class GoRouterRefreshNotifier extends ChangeNotifier {
  GoRouterRefreshNotifier(this.ref) {
    _authSub = ref.listen<AsyncValue<AuthState>>(authStateProvider, (_, __) {
      notifyListeners();
    });

    _onboardSub = ref.listen<AsyncValue<bool>>(isOnboardedProvider, (_, __) {
      notifyListeners();
    });
  }

  final Ref ref;
  late final ProviderSubscription _authSub;
  late final ProviderSubscription _onboardSub;

  @override
  void dispose() {
    _authSub.close();
    _onboardSub.close();
    super.dispose();
  }
}
