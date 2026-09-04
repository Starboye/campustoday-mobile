import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/admin_permissions.dart';
import '../../core/permission.dart';
import '../../core/widgets/admin_edit_sheet.dart';
import '../../core/widgets/admin_states.dart';
import '../../../auth/providers/auth_controller.dart';
import '../data/teachers_repository.dart';
import '../models/teacher.dart';
import '../providers/teachers_providers.dart';

class TeacherDetailScreen extends ConsumerWidget {
  const TeacherDetailScreen({super.key, required this.teacherId});

  final String teacherId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    if (!can(user, AdminPermissions.teachers)) {
      return const Scaffold(
        appBar: AppBar(title: Text('Teacher')),
        body: AdminEmptyView(message: 'You do not have teachers access.'),
      );
    }

    final teacherAsync = ref.watch(teacherDetailProvider(teacherId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher'),
        actions: [
          teacherAsync.whenOrNull(
            data: (teacher) => PopupMenuButton<String>(
              onSelected: (action) async {
                if (action == 'edit') {
                  await _edit(context, ref, teacher);
                } else if (action == 'delete') {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete teacher?'),
                      content: Text('Remove ${teacher.name}?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    await ref.read(teachersRepositoryProvider).delete(teacher.id);
                    ref.invalidate(teachersListProvider);
                    if (context.mounted) Navigator.pop(context);
                  }
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ),
        ],
      ),
      body: teacherAsync.when(
        loading: () => const AdminLoadingView(),
        error: (e, _) => AdminErrorView(
          message: 'Could not load teacher.\n$e',
          onRetry: () => ref.invalidate(teacherDetailProvider(teacherId)),
        ),
        data: (teacher) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(teacher.name, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            _DetailRow(label: 'Employee ID', value: teacher.employeeId),
            _DetailRow(label: 'Subjects', value: teacher.subjects),
            _DetailRow(label: 'Email', value: teacher.email),
            _DetailRow(label: 'Phone', value: teacher.phone),
            _DetailRow(label: 'Status', value: teacher.status),
          ],
        ),
      ),
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, Teacher teacher) async {
    final name = TextEditingController(text: teacher.name);
    final employeeId = TextEditingController(text: teacher.employeeId);
    final subjects = TextEditingController(text: teacher.subjects);
    final email = TextEditingController(text: teacher.email);
    final phone = TextEditingController(text: teacher.phone);

    await showAdminEditSheet(
      context: context,
      title: 'Edit teacher',
      fields: [
        TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
        TextField(controller: employeeId, decoration: const InputDecoration(labelText: 'Employee ID')),
        TextField(controller: subjects, decoration: const InputDecoration(labelText: 'Subjects')),
        TextField(controller: email, decoration: const InputDecoration(labelText: 'Email')),
        TextField(controller: phone, decoration: const InputDecoration(labelText: 'Phone')),
      ],
      onSave: () async {
        await ref.read(teachersRepositoryProvider).update(teacher.id, {
          'name': name.text.trim(),
          'employee_id': employeeId.text.trim(),
          'subjects': subjects.text.trim(),
          'email': email.text.trim(),
          'phone': phone.text.trim(),
        });
        ref.invalidate(teacherDetailProvider(teacher.id));
        ref.invalidate(teachersListProvider);
      },
    );

    name.dispose();
    employeeId.dispose();
    subjects.dispose();
    email.dispose();
    phone.dispose();
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
