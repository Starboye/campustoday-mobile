import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/analytics/screens/analytics_screen.dart';
import '../../features/admin/approvals/screens/approvals_list_screen.dart';
import '../../features/admin/attendance/screens/attendance_list_screen.dart';
import '../../features/admin/attendance_locks/screens/attendance_locks_list_screen.dart';
import '../../features/admin/bulk/screens/bulk_upload_screen.dart';
import '../../features/admin/data_quality/screens/data_quality_list_screen.dart';
import '../../features/admin/exams/screens/exams_list_screen.dart';
import '../../features/admin/fees/screens/fees_screen.dart' as admin_fees;
import '../../features/admin/homework/screens/homework_list_screen.dart';
import '../../features/admin/marks/screens/marks_list_screen.dart';
import '../../features/admin/notifications/screens/notifications_screen.dart';
import '../../features/admin/planner/screens/planner_screen.dart';
import '../../features/admin/rbac/screens/assign_roles_screen.dart';
import '../../features/admin/rbac/screens/roles_list_screen.dart';
import '../../features/admin/security/screens/login_audit_screen.dart';
import '../../features/admin/security/screens/user_security_screen.dart';
import '../../features/admin/shell/admin_shell.dart';
import '../../features/admin/students/screens/student_detail_screen.dart';
import '../../features/admin/students/screens/students_list_screen.dart';
import '../../features/admin/teachers/screens/teacher_detail_screen.dart';
import '../../features/admin/teachers/screens/teachers_list_screen.dart';
import '../../features/auth/models/auth_user.dart';
import '../../features/auth/providers/auth_controller.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/student/fees/fees_screen.dart' as student_fees;
import '../../features/student/homework/homework_screen.dart';
import '../../features/student/profile/change_password_screen.dart';
import '../../features/student/report/report_screen.dart';
import '../../features/student/shell/student_shell.dart';
import '../../features/student/timetable/timetable_screen.dart';
import '../../features/teacher/announcements/screens/announcement_form_screen.dart';
import '../../features/teacher/class_timetable/screens/class_timetable_screen.dart';
import '../../features/teacher/exam_timetable/screens/exam_timetable_screen.dart';
import '../../features/teacher/homework/screens/teacher_homework_form_screen.dart';
import '../../features/teacher/homework/screens/teacher_homework_list_screen.dart';
import '../../features/teacher/marks/screens/marks_screen.dart';
import '../../features/teacher/announcements/screens/announcement_compose_screen.dart';
import '../../features/teacher/class_timetable/screens/class_timetable_screen.dart';
import '../../features/teacher/exam_timetable/screens/exam_timetable_screen.dart';
import '../../features/teacher/homework/models/teacher_homework_item.dart';
import '../../features/teacher/homework/screens/teacher_homework_form_screen.dart';
import '../../features/teacher/homework/screens/teacher_homework_list_screen.dart';
import '../../features/teacher/marks/screens/marks_screen.dart';
import '../../features/teacher/shell/teacher_shell.dart';
import '../../features/teacher/students/screens/student_detail_screen.dart';
import '../../features/teacher/students/screens/student_detail_screen.dart' as teacher_students;

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: _RouterRefresh(ref),
    redirect: (context, state) {
      final user = authState.valueOrNull;
      final loggingIn = state.matchedLocation == '/login';
      final onSplash = state.matchedLocation == '/splash';
      final onChangePassword = state.matchedLocation == '/student/change-password';

      if (authState.isLoading && onSplash) return null;
      if (authState.isLoading) return '/splash';

      if (user == null) {
        return loggingIn || onSplash ? (onSplash ? '/login' : null) : '/login';
      }

      if (user.isStudent && user.forcePasswordReset && !onChangePassword) {
        return '/student/change-password';
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
          GoRoute(
            path: 'change-password',
            builder: (_, state) {
              final requiredReset = state.uri.queryParameters['required'] != 'false';
              return ChangePasswordScreen(required: requiredReset);
            },
          ),
          GoRoute(
            path: 'timetable',
            builder: (_, __) => const TimetableScreen(),
          ),
          GoRoute(
            path: 'fees',
            builder: (_, __) => const student_fees.FeesScreen(),
          ),
          GoRoute(
            path: 'report',
            builder: (_, __) => const ReportScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/teacher',
        builder: (_, __) => const TeacherShell(),
        routes: [
          GoRoute(
            path: 'homework',
            builder: (_, __) => const TeacherHomeworkListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (_, __) => const TeacherHomeworkFormScreen(),
              ),
              GoRoute(
                path: ':id/edit',
                builder: (_, state) => TeacherHomeworkFormScreen(
                  homeworkId: int.tryParse(state.pathParameters['id'] ?? ''),
                ),
              ),
            ],
          ),
          GoRoute(
            path: 'marks',
            builder: (_, __) => const TeacherMarksScreen(),
          ),
          GoRoute(
            path: 'announcements',
            builder: (_, __) => const AnnouncementFormScreen(),
          ),
          GoRoute(
            path: 'exam-timetable',
            builder: (_, __) => const ExamTimetableScreen(),
          ),
          GoRoute(
            path: 'class-timetable',
            builder: (_, __) => const ClassTimetableScreen(),
          ),
          GoRoute(
            path: 'students/:id',
            builder: (_, state) => TeacherStudentDetailScreen(
              studentId: state.pathParameters['id']!,
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/admin',
        builder: (_, __) => const AdminShell(),
        routes: [
          GoRoute(
            path: 'home/approvals',
            builder: (_, __) => const ApprovalsListScreen(),
          ),
          GoRoute(
            path: 'people/students',
            builder: (_, __) => const StudentsListScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, state) => StudentDetailScreen(
                  studentId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: 'people/teachers',
            builder: (_, __) => const TeachersListScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, state) => TeacherDetailScreen(
                  teacherId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: 'people/rbac',
            builder: (_, __) => const RolesListScreen(),
            routes: [
              GoRoute(
                path: 'users/:userId',
                builder: (_, state) => AssignRolesScreen(
                  userId: state.pathParameters['userId']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: 'academics/attendance',
            builder: (_, __) => const AttendanceListScreen(),
          ),
          GoRoute(
            path: 'academics/attendance-locks',
            builder: (_, __) => const AttendanceLocksListScreen(),
          ),
          GoRoute(
            path: 'academics/homework',
            builder: (_, __) => const HomeworkListScreen(),
          ),
          GoRoute(
            path: 'academics/marks',
            builder: (_, __) => const MarksListScreen(),
          ),
          GoRoute(
            path: 'academics/exams',
            builder: (_, __) => const ExamsListScreen(),
          ),
          GoRoute(
            path: 'ops/approvals',
            builder: (_, __) => const ApprovalsListScreen(),
          ),
          GoRoute(
            path: 'ops/fees',
            builder: (_, __) => const admin_fees.FeesScreen(),
          ),
          GoRoute(
            path: 'ops/planner',
            builder: (_, __) => const PlannerScreen(),
          ),
          GoRoute(
            path: 'ops/notifications',
            builder: (_, __) => const NotificationsScreen(),
          ),
          GoRoute(
            path: 'ops/bulk',
            builder: (_, __) => const BulkUploadScreen(),
          ),
          GoRoute(
            path: 'ops/data-quality',
            builder: (_, __) => const DataQualityListScreen(),
          ),
          GoRoute(
            path: 'more/analytics',
            builder: (_, __) => const AnalyticsScreen(),
          ),
          GoRoute(
            path: 'more/security',
            builder: (_, __) => const LoginAuditScreen(),
            routes: [
              GoRoute(
                path: 'users/:userId',
                builder: (_, state) => UserSecurityScreen(
                  userId: state.pathParameters['userId']!,
                ),
              ),
            ],
          ),
        ],
      ),
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
