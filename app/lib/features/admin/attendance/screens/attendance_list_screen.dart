import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/admin_permissions.dart';
import '../../core/permission.dart';
import '../../core/widgets/admin_states.dart';
import '../../../auth/providers/auth_controller.dart';
import '../data/attendance_repository.dart';
import '../providers/attendance_providers.dart';

class AttendanceListScreen extends ConsumerWidget {
  const AttendanceListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    if (!can(user, AdminPermissions.attendance)) {
      return const Scaffold(
        appBar: AppBar(title: Text('Attendance')),
        body: AdminEmptyView(message: 'You do not have attendance access.'),
      );
    }

    final date = ref.watch(attendanceDateProvider);
    final classFilter = ref.watch(attendanceClassProvider);
    final listAsync = ref.watch(attendanceListProvider);
    final dateLabel = DateFormat('EEE, d MMM yyyy').format(date);

    return Scaffold(
      appBar: AppBar(title: const Text('Attendance')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => ref.read(attendanceDateProvider.notifier).state =
                      date.subtract(const Duration(days: 1)),
                ),
                Expanded(child: Text(dateLabel, textAlign: TextAlign.center)),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => ref.read(attendanceDateProvider.notifier).state =
                      date.add(const Duration(days: 1)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              decoration: const InputDecoration(labelText: 'Filter by class'),
              onSubmitted: (v) => ref.read(attendanceClassProvider.notifier).state =
                  v.trim().isEmpty ? null : v.trim(),
            ),
          ),
          if (classFilter != null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Chip(
                label: Text('Class: $classFilter'),
                onDeleted: () => ref.read(attendanceClassProvider.notifier).state = null,
              ),
            ),
          Expanded(
            child: listAsync.when(
              loading: () => const AdminLoadingView(),
              error: (e, _) => AdminErrorView(
                message: 'Could not load attendance.\n$e',
                onRetry: () => ref.invalidate(attendanceListProvider),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return const AdminEmptyView(message: 'No attendance records.');
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(attendanceListProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final record = items[index];
                      return Card(
                        child: ListTile(
                          title: Text(record.studentName),
                          subtitle: Text('${record.className} · ${record.status}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              await ref.read(attendanceRepositoryProvider).delete(record.id);
                              ref.invalidate(attendanceListProvider);
                            },
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
