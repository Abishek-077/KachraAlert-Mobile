import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Admin pages
import 'package:smart_waste_app/features/admin/presentation/pages/admin_broadcast_screen.dart';
import 'package:smart_waste_app/features/admin/presentation/pages/admin_schedule_manage_screen.dart';
import 'package:smart_waste_app/features/admin/presentation/pages/admin_alert_form_screen.dart';
import 'package:smart_waste_app/features/admin/data/models/admin_alert_hive_model.dart';
import 'package:smart_waste_app/features/admin/presentation/pages/admin_users_screen.dart';
import 'package:smart_waste_app/features/admin/presentation/pages/admin_user_form_screen.dart';
import 'package:smart_waste_app/features/admin/data/models/admin_user_model.dart';

// Alerts
import 'package:smart_waste_app/features/alerts/presentation/pages/alerts_hub_screen.dart';

// Reports
import 'package:smart_waste_app/features/reports/presentation/pages/report_form_screen.dart';
import 'package:smart_waste_app/features/reports/presentation/pages/report_success_screen.dart';
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
import 'package:smart_waste_app/features/messages/presentation/pages/messages_screen.dart';
import 'package:smart_waste_app/features/payments/presentation/pages/payments_screen.dart';

// Onboarding + Settings
import 'package:smart_waste_app/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:smart_waste_app/features/settings/presentation/pages/settings_screen.dart';
import 'package:smart_waste_app/features/settings/presentation/providers/settings_providers.dart';
import 'package:smart_waste_app/core/extensions/async_value_extensions.dart';

/// App Router Provider
final appRouterProvider = Provider<GoRouter>((ref) {
  final authAsync = ref.watch(authStateProvider);
  final onboardedAsync = ref.watch(isOnboardedProvider);
  final splashDelayAsync = ref.watch(splashDelayProvider);
  final startupTimeoutAsync = ref.watch(startupTimeoutProvider);

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
      final isReportsSuccess = loc.startsWith('/reports/success/');

      final isShell = loc == '/home' ||
          loc == '/schedule' ||
          loc == '/messages' ||
          loc.startsWith('/messages/') ||
          loc == '/alerts' ||
          loc == '/profile' ||
          loc.startsWith('/profile/');

      final isSettings = loc == '/settings';
      final isPayments = loc == '/payments';

      // 0) Gate startup: if auth/onboarding/splash-delay are still loading,
      // keep the user on splash unless timeout has been reached.
      final timeoutReached =
          startupTimeoutAsync.hasValue || startupTimeoutAsync.hasError;
      final stillLoading = (authAsync.isLoading ||
              onboardedAsync.isLoading ||
              splashDelayAsync.isLoading) &&
          !timeoutReached;

      if (stillLoading) {
        return isSplash ? null : '/splash';
      }

      // Resolve values only after loading gate.
      final onboarded = onboardedAsync.value ?? false;
      final auth = authAsync.valueOrNull;

      final token = (auth?.session?.accessToken ?? '').trim();
      final loggedIn = (auth?.isLoggedIn ?? false) && token.isNotEmpty;
      final userIsAdmin = auth?.session?.role == 'admin_driver';

      // Splash is a transient handoff page.
      if (isSplash) {
        if (!onboarded) return '/onboarding';
        if (!loggedIn) return '/auth/login';
        return '/home';
      }

      // 1) Not onboarded -> force onboarding (and block everything else)
      if (!onboarded) {
        return isOnboarding ? null : '/onboarding';
      }

      // 2) Onboarded but not logged in -> force login
      if (!loggedIn) {
        return isAuth ? null : '/auth/login';
      }

      // 3) Logged in -> block onboarding/auth pages
      if (isOnboarding || isAuth) {
        return '/home';
      }

      // 4) Admin route protection
      if (isAdmin && !userIsAdmin) return '/home';
      if (isAlertsCreate && !userIsAdmin) return '/home';

      // 5) Allowed routes
      final allowed = isShell ||
          isSettings ||
          isPayments ||
          isReportsList ||
          isReportsCreate ||
          isReportsSuccess ||
          (isAdmin && userIsAdmin) ||
          isAlertsCreate;

      if (allowed) return null;

      // 6) Unknown route fallback
      return '/home';
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingPage()),
      GoRoute(path: '/auth/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/auth/signup', builder: (_, __) => const SignupScreen()),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      GoRoute(path: '/payments', builder: (_, __) => const PaymentsScreen()),
      GoRoute(path: '/reports', builder: (_, __) => const ReportsScreen()),
      GoRoute(
        path: '/reports/success/:reportId',
        builder: (_, state) {
          final reportId = state.pathParameters['reportId'] ?? '';
          return ReportSuccessScreen(reportId: reportId);
        },
      ),
      GoRoute(
        path: '/admin/broadcast',
        builder: (_, __) => const AdminBroadcastScreen(),
      ),
      GoRoute(
        path: '/admin/schedule',
        builder: (_, __) => const AdminScheduleManageScreen(),
      ),
      GoRoute(
        path: '/admin/users',
        builder: (_, __) => const AdminUsersScreen(),
      ),
      GoRoute(
        path: '/admin/users/form',
        builder: (context, state) {
          final extra = state.extra;
          return AdminUserFormScreen(
            existing: extra is AdminUser ? extra : null,
          );
        },
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
          final isUrgent = state.uri.queryParameters['urgent'] == 'true';
          return ReportFormScreen(
            existing: extra is ReportHiveModel ? extra : null,
            isUrgent: isUrgent,
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
              GoRoute(
                path: '/messages',
                builder: (_, __) => const MessagesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/alerts',
                builder: (_, __) => const AlertsHubScreen(),
              ),
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

/// Notifies GoRouter to re-run redirect logic when relevant providers change.
class GoRouterRefreshNotifier extends ChangeNotifier {
  GoRouterRefreshNotifier(this.ref) {
    _authSub = ref.listen<AsyncValue<AuthState>>(authStateProvider, (_, __) {
      notifyListeners();
    });

    _onboardSub = ref.listen<AsyncValue<bool>>(isOnboardedProvider, (_, __) {
      notifyListeners();
    });

    _splashDelaySub =
        ref.listen<AsyncValue<void>>(splashDelayProvider, (_, __) {
      notifyListeners();
    });

    _startupTimeoutSub =
        ref.listen<AsyncValue<void>>(startupTimeoutProvider, (_, __) {
      notifyListeners();
    });
  }

  final Ref ref;

  late final ProviderSubscription<AsyncValue<AuthState>> _authSub;
  late final ProviderSubscription<AsyncValue<bool>> _onboardSub;
  late final ProviderSubscription<AsyncValue<void>> _splashDelaySub;
  late final ProviderSubscription<AsyncValue<void>> _startupTimeoutSub;

  @override
  void dispose() {
    _authSub.close();
    _onboardSub.close();
    _splashDelaySub.close();
    _startupTimeoutSub.close();
    super.dispose();
  }
}

/// Ensures the splash screen can't block forever if a provider hangs.
final startupTimeoutProvider = FutureProvider<void>((ref) async {
  await Future<void>.delayed(const Duration(seconds: 3));
});
