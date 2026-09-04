import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';

class WorkHubScreen extends StatelessWidget {
  const WorkHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      _WorkItem(
        icon: Icons.assignment_outlined,
        title: 'Homework',
        subtitle: 'Create and manage assignments',
        route: '/teacher/homework',
      ),
      _WorkItem(
        icon: Icons.grade_outlined,
        title: 'Marks',
        subtitle: 'Enter marks for your subjects',
        route: '/teacher/marks',
      ),
      _WorkItem(
        icon: Icons.campaign_outlined,
        title: 'Announcements',
        subtitle: 'Send messages to classes',
        route: '/teacher/announcements',
      ),
      _WorkItem(
        icon: Icons.calendar_month_outlined,
        title: 'Exam timetable',
        subtitle: 'View exam schedule',
        route: '/teacher/exam-timetable',
      ),
      _WorkItem(
        icon: Icons.table_chart_outlined,
        title: 'Class timetable',
        subtitle: 'Edit and submit weekly grid',
        route: '/teacher/class-timetable',
      ),
    ];

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          child: ListTile(
            leading: Icon(item.icon, color: const Color(AppConstants.primaryColor)),
            title: Text(
              item.title,
              style: const TextStyle(
                color: Color(AppConstants.navyColor),
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(item.subtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(item.route),
          ),
        );
      },
    );
  }
}

class _WorkItem {
  const _WorkItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
}
