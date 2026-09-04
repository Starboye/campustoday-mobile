import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/shell/admin_shell.dart';
import '../../features/auth/models/auth_user.dart';
import '../../features/auth/providers/auth_controller.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/student/homework/homework_screen.dart';
import '../../features/student/shell/student_shell.dart';
import '../../features/teacher/shell/teacher_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: _RouterRefresh(ref),
    redirect: (context, state) {
      final user = authState.valueOrNull;
      final loggingIn = state.matchedLocation == '/login';
      final onSplash = state.matchedLocation == '/splash';

      if (authState.isLoading && onSplash) return null;
      if (authState.isLoading) return '/splash';

      if (user == null) {
        return loggingIn || onSplash ? (onSplash ? '/login' : null) : '/login';
      }

      if (loggingIn || onSplash) {
        return _homeFor(user);
      }

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(
        path: '/student',
        builder: (_, __) => const StudentShell(),
        routes: [
          GoRoute(
            path: 'homework',
            builder: (_, __) => const HomeworkScreen(),
          ),
        ],
      ),
      GoRoute(path: '/teacher', builder: (_, __) => const TeacherShell()),
      GoRoute(path: '/admin', builder: (_, __) => const AdminShell()),
    ],
  );
});

String _homeFor(AuthUser user) {
  return switch (user.access) {
    1 => '/teacher',
    2 => '/admin',
    _ => '/student',
  };
}

class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(this.ref) {
    ref.listen<AsyncValue<AuthUser?>>(authControllerProvider, (_, __) {
      notifyListeners();
    });
  }

  final Ref ref;
}
