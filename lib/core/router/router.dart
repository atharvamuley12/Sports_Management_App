import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/controllers/auth_controller.dart';
import '../../features/auth/screens/auth_screen.dart';
import '../../features/auth/screens/change_password_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/dashboard/screens/actions_hub_screen.dart';
import '../../features/students/screens/student_list_screen.dart';
import '../../features/students/screens/student_form_screen.dart';
import '../../features/students/screens/student_profile_screen.dart';
import '../../shared/models/student.dart';
import '../../shared/models/batch.dart';
import '../../features/attendance/screens/attendance_screen.dart';
import '../../features/fees/screens/fees_screen.dart';
import '../../features/expenses/screens/expenses_screen.dart';
import '../../features/reports/screens/reports_screen.dart';
import '../../features/users/screens/coaches_screen.dart';
import '../../features/batches/screens/batch_list_screen.dart';
import '../../features/batches/screens/batch_form_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../shared/widgets/main_navigation_layout.dart';

class AuthRefreshListenable extends ChangeNotifier {
  AuthRefreshListenable(Ref ref) {
    ref.listen<AuthStateData>(
      authControllerProvider,
          (previous, next) {
        if (previous?.user != next.user || previous?.profile != next.profile) {
          notifyListeners();
        }
      },
    );
  }
}

final rootNavigatorKey = GlobalKey<NavigatorState>();

final authRefreshListenableProvider = Provider<AuthRefreshListenable>((ref) {
  return AuthRefreshListenable(ref);
});

// ─── Premium Page Transitions ───────────────────────────────────────

/// Fade transition for tab/shell routes — smooth but instant-feeling
CustomTransitionPage<void> _fadeTransition(Widget child, GoRouterState state) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 200),
    reverseTransitionDuration: const Duration(milliseconds: 150),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
        child: child,
      );
    },
  );
}

/// Slide from right + fade for push routes — iOS-style premium feel
CustomTransitionPage<void> _slideTransition(Widget child, GoRouterState state) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 250),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.25, 0),
          end: Offset.zero,
        ).animate(curved),
        child: FadeTransition(
          opacity: curved,
          child: child,
        ),
      );
    },
  );
}

/// Scale + fade for auth → dashboard entrance — dramatic first impression
CustomTransitionPage<void> _scaleTransition(Widget child, GoRouterState state) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return ScaleTransition(
        scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
        child: FadeTransition(
          opacity: curved,
          child: child,
        ),
      );
    },
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  final refreshListenable = ref.watch(authRefreshListenableProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/auth',
    refreshListenable: refreshListenable,
    routes: [
      GoRoute(
        path: '/auth',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => _scaleTransition(const AuthScreen(), state),
      ),
      GoRoute(
        path: '/change-password',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => _slideTransition(const ChangePasswordScreen(), state),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return MainNavigationLayout(child: child);
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            pageBuilder: (context, state) => _fadeTransition(const DashboardScreen(), state),
          ),
          GoRoute(
            path: '/students',
            pageBuilder: (context, state) => _fadeTransition(const StudentListScreen(), state),
          ),
          GoRoute(
            path: '/batches',
            pageBuilder: (context, state) => _fadeTransition(const BatchListScreen(), state),
          ),
          GoRoute(
            path: '/hub',
            pageBuilder: (context, state) => _fadeTransition(const ActionsHubScreen(), state),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => _fadeTransition(const SettingsScreen(), state),
          ),
          GoRoute(
            path: '/attendance',
            pageBuilder: (context, state) => _fadeTransition(const AttendanceScreen(), state),
          ),
        ],
      ),
      // Subpages outside Shell (they slide over the bottom nav bar)
      GoRoute(
        path: '/students/new',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => _slideTransition(const StudentFormScreen(), state),
      ),
      GoRoute(
        path: '/students/edit',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) {
          final student = state.extra as Student?;
          return _slideTransition(StudentFormScreen(student: student), state);
        },
      ),
      GoRoute(
        path: '/students/profile',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) {
          final student = state.extra as Student;
          return _slideTransition(StudentProfileScreen(student: student), state);
        },
      ),
      GoRoute(
        path: '/batches/new',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => _slideTransition(const BatchFormScreen(), state),
      ),
      GoRoute(
        path: '/batches/edit',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) {
          final batch = state.extra as Batch?;
          return _slideTransition(BatchFormScreen(batch: batch), state);
        },
      ),
      GoRoute(
        path: '/fees',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => _slideTransition(const FeesScreen(), state),
      ),
      GoRoute(
        path: '/expenses',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => _slideTransition(const ExpensesScreen(), state),
      ),
      GoRoute(
        path: '/reports',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => _slideTransition(const ReportsScreen(), state),
      ),
      GoRoute(
        path: '/users',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => _slideTransition(const CoachesScreen(), state),
      ),
    ],
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      final isLoggedIn = authState.user != null;
      final profile = authState.profile;
      final isGoingToAuth = state.matchedLocation == '/auth';
      final isGoingToChangePassword = state.matchedLocation == '/change-password';

      // 1. Not logged in -> force to auth
      if (!isLoggedIn) {
        return isGoingToAuth ? null : '/auth';
      }

      // 2. Logged in, profile not loaded yet
      if (profile == null) {
        if (authState.isLoading || isGoingToAuth) {
          return null; // Wait for profile fetch or stay on auth page
        }
        return '/auth'; // Fallback if profile load failed
      }

      // 3. User must change password -> force to password-change page
      if (profile.mustChangePassword) {
        return isGoingToChangePassword ? null : '/change-password';
      }

      // 4. Logged in & changed password -> cannot visit auth or change-password
      if (isGoingToAuth || isGoingToChangePassword) {
        return '/dashboard';
      }

      // 5. Role restrictions: Coaches cannot access admin routes
      if (profile.isCoach) {
        final adminOnlyPaths = ['/fees', '/expenses', '/reports', '/users', '/batches'];
        if (adminOnlyPaths.contains(state.matchedLocation)) {
          return '/dashboard';
        }
      }

      return null;
    },
  );
});