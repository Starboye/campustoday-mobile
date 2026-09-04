import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/admin_permissions.dart';
import '../../core/permission.dart';
import '../../core/widgets/admin_edit_sheet.dart';
import '../../core/widgets/admin_states.dart';
import '../../../auth/providers/auth_controller.dart';
import '../data/attendance_locks_repository.dart';
import '../providers/attendance_locks_providers.dart';

class AttendanceLocksListScreen extends ConsumerWidget {
  const AttendanceLocksListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    if (!can(user, AdminPermissions.attendanceLocks)) {
      return const Scaffold(
        appBar: AppBar(title: Text('Attendance Locks')),
        body: AdminEmptyView(message: 'You do not have attendance lock access.'),
      );
    }

    final listAsync = ref.watch(attendanceLocksListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Locks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.lock_outline),
            onPressed: () => _lockDay(context, ref),
          ),
        ],
      ),
      body: listAsync.when(
        loading: () => const AdminLoadingView(),
        error: (e, _) => AdminErrorView(
          message: 'Could not load locks.\n$e',
          onRetry: () => ref.invalidate(attendanceLocksListProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const AdminEmptyView(message: 'No locked days.');
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(attendanceLocksListProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final lock = items[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.lock),
                    title: Text(lock.date),
                    subtitle: Text('Locked by ${lock.lockedBy}'),
                    trailing: TextButton(
                      onPressed: () async {
                        await ref.read(attendanceLocksRepositoryProvider).unlock(lock.id);
                        ref.invalidate(attendanceLocksListProvider);
                      },
                      child: const Text('Unlock'),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _lockDay(BuildContext context, WidgetRef ref) async {
    final dateController = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );
    await showAdminEditSheet(
      context: context,
      title: 'Lock day',
      fields: [
        TextField(
          controller: dateController,
          decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD)'),
        ),
      ],
      onSave: () async {
        await ref.read(attendanceLocksRepositoryProvider).lock(dateController.text.trim());
        ref.invalidate(attendanceLocksListProvider);
      },
    );
    dateController.dispose();
  }
}
