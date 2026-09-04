import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/admin_permissions.dart';
import '../../core/permission.dart';
import '../../core/widgets/admin_edit_sheet.dart';
import '../../core/widgets/admin_states.dart';
import '../../../auth/providers/auth_controller.dart';
import '../data/students_repository.dart';
import '../models/student.dart';
import '../providers/students_providers.dart';

class StudentDetailScreen extends ConsumerWidget {
  const StudentDetailScreen({super.key, required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    if (!can(user, AdminPermissions.students)) {
      return const Scaffold(
        appBar: AppBar(title: Text('Student')),
        body: AdminEmptyView(message: 'You do not have students access.'),
      );
    }

    final studentAsync = ref.watch(studentDetailProvider(studentId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student'),
        actions: [
          studentAsync.whenOrNull(
            data: (student) => PopupMenuButton<String>(
              onSelected: (action) async {
                if (action == 'edit') {
                  await _edit(context, ref, student);
                } else if (action == 'delete') {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete student?'),
                      content: Text('Remove ${student.name}?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    await ref.read(studentsRepositoryProvider).delete(student.id);
                    ref.invalidate(studentsListProvider);
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
      body: studentAsync.when(
        loading: () => const AdminLoadingView(),
        error: (e, _) => AdminErrorView(
          message: 'Could not load student.\n$e',
          onRetry: () => ref.invalidate(studentDetailProvider(studentId)),
        ),
        data: (student) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(student.name, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            _DetailRow(label: 'Admission', value: student.admissionNo),
            _DetailRow(label: 'Class', value: student.className),
            _DetailRow(label: 'Email', value: student.email),
            _DetailRow(label: 'Phone', value: student.phone),
            _DetailRow(label: 'Status', value: student.status),
          ],
        ),
      ),
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, Student student) async {
    final name = TextEditingController(text: student.name);
    final admission = TextEditingController(text: student.admissionNo);
    final className = TextEditingController(text: student.className);
    final email = TextEditingController(text: student.email);
    final phone = TextEditingController(text: student.phone);

    await showAdminEditSheet(
      context: context,
      title: 'Edit student',
      fields: [
        TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
        TextField(controller: admission, decoration: const InputDecoration(labelText: 'Admission no.')),
        TextField(controller: className, decoration: const InputDecoration(labelText: 'Class')),
        TextField(controller: email, decoration: const InputDecoration(labelText: 'Email')),
        TextField(controller: phone, decoration: const InputDecoration(labelText: 'Phone')),
      ],
      onSave: () async {
        await ref.read(studentsRepositoryProvider).update(student.id, {
          'name': name.text.trim(),
          'admission_no': admission.text.trim(),
          'class_name': className.text.trim(),
          'email': email.text.trim(),
          'phone': phone.text.trim(),
        });
        ref.invalidate(studentDetailProvider(student.id));
        ref.invalidate(studentsListProvider);
      },
    );

    name.dispose();
    admission.dispose();
    className.dispose();
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
