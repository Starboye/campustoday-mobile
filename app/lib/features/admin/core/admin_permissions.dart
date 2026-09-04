/// Permission keys aligned with API RequirePermission middleware and SchoolCRM web RBAC.
abstract final class AdminPermissions {
  static const students = 'can_manage_users';
  static const teachers = 'can_manage_users';
  static const homework = 'can_manage_users';
  static const approvals = 'can_manage_users';
  static const bulk = 'can_manage_users';
  static const attendance = 'can_delete_attendance';
  static const attendanceLocks = 'can_delete_attendance';
  static const marks = 'can_edit_marks';
  static const fees = 'can_manage_fees';
  static const planner = 'can_manage_planner';
  static const notifications = 'can_manage_notifications';
  static const exams = 'can_manage_exams';
  static const analytics = 'can_view_analytics';
  static const security = 'can_manage_security';
  static const rbac = 'can_manage_delegation';
  static const delegation = 'can_manage_delegation';
  static const dataQuality = 'can_manage_data_quality';
}
