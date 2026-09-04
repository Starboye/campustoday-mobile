import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../auth/providers/auth_controller.dart';
import '../data/student_repository.dart';

final studentDashboardProvider = FutureProvider.autoDispose((ref) async {
  return ref.watch(studentRepositoryProvider).fetchDashboard();
});

class StudentDashboardScreen extends ConsumerWidget {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(studentDashboardProvider);
    final user = ref.watch(authControllerProvider).value;

    return dashboard.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Could not load dashboard.\n$e')),
      data: (data) {
        final profile = data['profile'] as Map<String, dynamic>? ?? {};
        final attendance = data['attendance_summary'] as Map<String, dynamic>? ?? {};
        final unread = data['unread_notifications'] as int? ?? 0;
        final marks = data['latest_marks'] as List<dynamic>? ?? [];

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(studentDashboardProvider),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Welcome, ${profile['name'] ?? user?.name ?? ''}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if (profile['standard'] != null)
                Text('Class ${profile['standard']}-${profile['section']}'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Present',
                      value: '${attendance['present'] ?? 0}',
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Absent',
                      value: '${attendance['absent'] ?? 0}',
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Alerts',
                      value: '$unread',
                      color: const Color(AppConstants.primaryColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text('Latest marks', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (marks.isEmpty)
                const Card(
                  child: ListTile(title: Text('No marks recorded yet.')),
                )
              else
                ...marks.map((m) {
                  final row = m as Map<String, dynamic>;
                  return Card(
                    child: ListTile(
                      title: Text(row['subject_name']?.toString() ?? ''),
                      subtitle: Text('Term ${row['term']}'),
                      trailing: Text(
                        row['marks']?.toString() ?? '—',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
