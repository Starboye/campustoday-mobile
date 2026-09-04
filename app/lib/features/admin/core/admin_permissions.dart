/// Permission keys for admin modules (aligned with API RequirePermission middleware).
abstract final class AdminPermissions {
  static const dashboard = 'dashboard.view';
  static const students = 'students.manage';
  static const teachers = 'teachers.manage';
  static const attendance = 'attendance.manage';
  static const attendanceLocks = 'attendance_locks.manage';
  static const homework = 'homework.moderate';
  static const marks = 'marks.manage';
  static const fees = 'fees.manage';
  static const planner = 'planner.manage';
  static const approvals = 'approvals.manage';
  static const notifications = 'notifications.manage';
  static const exams = 'exams.manage';
  static const analytics = 'analytics.view';
  static const security = 'security.manage';
  static const rbac = 'rbac.manage';
  static const bulk = 'bulk.import';
  static const dataQuality = 'data_quality.manage';
}
