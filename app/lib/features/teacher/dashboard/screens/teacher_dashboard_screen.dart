import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../providers/dashboard_providers.dart';

class TeacherDashboardScreen extends ConsumerWidget {
  const TeacherDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);

    return dashboardAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Could not load dashboard.\n$e', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(dashboardProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (summary) {
        final attendance = summary.attendanceCompleteness;
        final dateLabel = DateFormat('d MMM yyyy').format(
          DateTime.tryParse(attendance.date) ?? DateTime.now(),
        );

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(dashboardProvider),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Today\'s overview',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: const Color(AppConstants.navyColor),
                    ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.fact_check_outlined,
                      label: 'Attendance',
                      value: '${attendance.completedSections}/${attendance.totalSections}',
                      subtitle: '${attendance.percent.toStringAsFixed(0)}% · $dateLabel',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.assignment_outlined,
                      label: 'Homework',
                      value: '${summary.homeworkCount}',
                      subtitle: 'active items',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Your allocations',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(AppConstants.navyColor),
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              if (summary.allocations.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No class allocations yet.'),
                  ),
                )
              else
                ...summary.allocations.map(
                  (a) => Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            const Color(AppConstants.primaryColor).withValues(alpha: 0.12),
                        child: Text(
                          '${a.standard}',
                          style: const TextStyle(
                            color: Color(AppConstants.primaryColor),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      title: Text(a.classLabel),
                      subtitle: Text(a.subjectName),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.subtitle,
  });

  final IconData icon;
  final String label;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(AppConstants.primaryColor)),
            const SizedBox(height: 8),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: const Color(AppConstants.navyColor),
                    fontWeight: FontWeight.w700,
                  ),
            ),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
