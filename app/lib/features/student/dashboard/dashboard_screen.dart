import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/async_content.dart';
import 'providers/dashboard_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);

    return dashboardAsync.when(
      loading: () => const LoadingContent(),
      error: (e, _) => ErrorContent(
        message: 'Could not load dashboard.\n$e',
        onRetry: () => ref.invalidate(dashboardProvider),
      ),
      data: (data) => RefreshIndicator(
        onRefresh: () async => ref.invalidate(dashboardProvider),
        child: ListView(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Text(
              'Welcome, ${data.profile.name.isNotEmpty ? data.profile.name : 'Student'}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: const Color(AppConstants.navyColor),
                    fontWeight: FontWeight.w700,
                  ),
            ),
            if (data.profile.classLabel.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                data.profile.classLabel,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(AppConstants.navyColor).withValues(alpha: 0.7),
                    ),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.event_available,
                    label: 'Present',
                    value: '${data.attendanceSummary.present}',
                    subtitle: data.attendanceSummary.totalDays > 0
                        ? '${data.attendanceSummary.percentage.toStringAsFixed(0)}% this month'
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.event_busy,
                    label: 'Absent',
                    value: '${data.attendanceSummary.absent}',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.notifications_active_outlined,
                    label: 'Alerts',
                    value: '${data.unreadNotifications}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Latest marks',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(AppConstants.navyColor),
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            if (data.latestMarks.isEmpty)
              const Card(
                child: ListTile(title: Text('No marks recorded yet.')),
              )
            else
              ...data.latestMarks.map(
                (mark) => Card(
                  child: ListTile(
                    title: Text(mark.subjectName),
                    subtitle: Text('Term ${mark.term}${mark.examType != null ? ' · ${mark.examType}' : ''}'),
                    trailing: Text(
                      mark.marks?.toString() ?? '—',
                      style: const TextStyle(
                        color: Color(AppConstants.primaryColor),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: const Color(AppConstants.primaryColor)),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: const Color(AppConstants.navyColor),
                    fontWeight: FontWeight.w700,
                  ),
            ),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            if (subtitle != null)
              Text(subtitle!, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
