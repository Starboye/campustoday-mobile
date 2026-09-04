import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/providers/auth_controller.dart';
import '../attendance/screens/attendance_screen.dart';
import '../dashboard/screens/teacher_dashboard_screen.dart';
import '../students/screens/students_screen.dart';
import '../work/screens/work_hub_screen.dart';

class TeacherShell extends ConsumerStatefulWidget {
  const TeacherShell({super.key});

  @override
  ConsumerState<TeacherShell> createState() => _TeacherShellState();
}

class _TeacherShellState extends ConsumerState<TeacherShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = const [
      TeacherDashboardScreen(),
      AttendanceScreen(),
      WorkHubScreen(),
      StudentsScreen(),
      _TeacherMeTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/brand/icon-48.png', height: 32),
            const SizedBox(width: 8),
            Text(_titles[_index]),
          ],
        ),
        actions: [
          if (_index != 4)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => ref.read(authControllerProvider.notifier).logout(),
            ),
        ],
      ),
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.fact_check_outlined),
            selectedIcon: Icon(Icons.fact_check),
            label: 'Attendance',
          ),
          NavigationDestination(
            icon: Icon(Icons.work_outline),
            selectedIcon: Icon(Icons.work),
            label: 'Work',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Students',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Me',
          ),
        ],
      ),
    );
  }

  static const _titles = ['Home', 'Attendance', 'Work', 'Students', 'Me'];
}

class _TeacherMeTab extends ConsumerWidget {
  const _TeacherMeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          title: Text(user?.name ?? 'Teacher'),
          subtitle: Text('ID: ${user?.id ?? ''}'),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.calendar_month_outlined),
          title: const Text('Exam timetable'),
          onTap: () => context.push('/teacher/exam-timetable'),
        ),
        ListTile(
          leading: const Icon(Icons.table_chart_outlined),
          title: const Text('Class timetable'),
          onTap: () => context.push('/teacher/class-timetable'),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Sign out'),
          onTap: () => ref.read(authControllerProvider.notifier).logout(),
        ),
      ],
    );
  }
}
