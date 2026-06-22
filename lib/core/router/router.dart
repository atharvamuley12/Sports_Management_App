// GoRouter Configuration
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/controllers/auth_controller.dart';
import '../../features/auth/screens/auth_screen.dart';
import '../../features/auth/screens/change_password_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/students/screens/student_list_screen.dart';
import '../../features/students/screens/student_form_screen.dart';
import '../../shared/models/student.dart';
import '../../features/attendance/screens/attendance_screen.dart';
import '../../features/fees/screens/fees_screen.dart';
import '../../features/expenses/screens/expenses_screen.dart';
import '../../features/reports/screens/reports_screen.dart';
import '../../features/users/screens/coaches_screen.dart';

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

final authRefreshListenableProvider = Provider<AuthRefreshListenable>((ref) {
  return AuthRefreshListenable(ref);
});

final routerProvider = Provider<GoRouter>((ref) {
  final refreshListenable = ref.watch(authRefreshListenableProvider);

  return GoRouter(
    initialLocation: '/auth',
    refreshListenable: refreshListenable,
    routes: [
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/change-password',
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/students',
        builder: (context, state) => const StudentListScreen(),
      ),
      GoRoute(
        path: '/students/new',
        builder: (context, state) => const StudentFormScreen(),
      ),
      GoRoute(
        path: '/students/edit',
        builder: (context, state) {
          final student = state.extra as Student?;
          return StudentFormScreen(student: student);
        },
      ),
      GoRoute(
        path: '/attendance',
        builder: (context, state) => const AttendanceScreen(),
      ),
      GoRoute(
        path: '/fees',
        builder: (context, state) => const FeesScreen(),
      ),
      GoRoute(
        path: '/expenses',
        builder: (context, state) => const ExpensesScreen(),
      ),
      GoRoute(
        path: '/reports',
        builder: (context, state) => const ReportsScreen(),
      ),
      GoRoute(
        path: '/users',
        builder: (context, state) => const CoachesScreen(),
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
        final adminOnlyPaths = ['/fees', '/expenses', '/reports', '/users'];
        if (adminOnlyPaths.contains(state.matchedLocation)) {
          return '/dashboard';
        }
      }

      return null;
    },
  );
});

