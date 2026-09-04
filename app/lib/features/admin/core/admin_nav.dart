import 'admin_module_entry.dart';
import 'admin_permissions.dart';

const peopleModules = [
  AdminModuleEntry(
    title: 'Students',
    subtitle: 'Search, enroll, and edit student records',
    icon: Icons.school_outlined,
    permission: AdminPermissions.students,
    route: '/admin/people/students',
  ),
  AdminModuleEntry(
    title: 'Teachers',
    subtitle: 'Manage teacher profiles and assignments',
    icon: Icons.person_outline,
    permission: AdminPermissions.teachers,
    route: '/admin/people/teachers',
  ),
  AdminModuleEntry(
    title: 'Roles & Access',
    subtitle: 'Assign roles and permissions',
    icon: Icons.admin_panel_settings_outlined,
    permission: AdminPermissions.rbac,
    route: '/admin/people/rbac',
  ),
  AdminModuleEntry(
    title: 'Delegation',
    subtitle: 'Delegate admin roles to users',
    icon: Icons.assignment_ind_outlined,
    permission: AdminPermissions.delegation,
    route: '/admin/people/delegation',
  ),
];

const academicsModules = [
  AdminModuleEntry(
    title: 'Attendance',
    subtitle: 'Filter by date and class, override entries',
    icon: Icons.fact_check_outlined,
    permission: AdminPermissions.attendance,
    route: '/admin/academics/attendance',
  ),
  AdminModuleEntry(
    title: 'Attendance Locks',
    subtitle: 'Lock or unlock days for editing',
    icon: Icons.lock_outline,
    permission: AdminPermissions.attendanceLocks,
    route: '/admin/academics/attendance-locks',
  ),
  AdminModuleEntry(
    title: 'Homework',
    subtitle: 'Moderate homework posts',
    icon: Icons.assignment_outlined,
    permission: AdminPermissions.homework,
    route: '/admin/academics/homework',
  ),
  AdminModuleEntry(
    title: 'Marks',
    subtitle: 'Enter marks per student and term',
    icon: Icons.grade_outlined,
    permission: AdminPermissions.marks,
    route: '/admin/academics/marks',
  ),
  AdminModuleEntry(
    title: 'Exams',
    subtitle: 'Manage exam windows',
    icon: Icons.quiz_outlined,
    permission: AdminPermissions.exams,
    route: '/admin/academics/exams',
  ),
];

const opsModules = [
  AdminModuleEntry(
    title: 'Approvals',
    subtitle: 'Review and action pending requests',
    icon: Icons.approval_outlined,
    permission: AdminPermissions.approvals,
    route: '/admin/ops/approvals',
  ),
  AdminModuleEntry(
    title: 'Fees',
    subtitle: 'Fee structures and payment status',
    icon: Icons.payments_outlined,
    permission: AdminPermissions.fees,
    route: '/admin/ops/fees',
  ),
  AdminModuleEntry(
    title: 'Planner',
    subtitle: 'Slots, assignments, and timetables',
    icon: Icons.calendar_month_outlined,
    permission: AdminPermissions.planner,
    route: '/admin/ops/planner',
  ),
  AdminModuleEntry(
    title: 'Notifications',
    subtitle: 'Templates, schedules, send now',
    icon: Icons.notifications_outlined,
    permission: AdminPermissions.notifications,
    route: '/admin/ops/notifications',
  ),
  AdminModuleEntry(
    title: 'Bulk Import',
    subtitle: 'Upload CSV files with progress',
    icon: Icons.upload_file_outlined,
    permission: AdminPermissions.bulk,
    route: '/admin/ops/bulk',
  ),
  AdminModuleEntry(
    title: 'Data Quality',
    subtitle: 'Review and resolve data issues',
    icon: Icons.fact_check_outlined,
    permission: AdminPermissions.dataQuality,
    route: '/admin/ops/data-quality',
  ),
];

const moreModules = [
  AdminModuleEntry(
    title: 'Analytics',
    subtitle: 'Charts and school-wide metrics',
    icon: Icons.insights_outlined,
    permission: AdminPermissions.analytics,
    route: '/admin/more/analytics',
  ),
  AdminModuleEntry(
    title: 'Security',
    subtitle: 'Login audit and user lock controls',
    icon: Icons.security_outlined,
    permission: AdminPermissions.security,
    route: '/admin/more/security',
  ),
];
