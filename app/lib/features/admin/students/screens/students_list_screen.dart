import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/admin_permissions.dart';
import '../../core/permission.dart';
import '../../core/widgets/admin_edit_sheet.dart';
import '../../core/widgets/admin_search_bar.dart';
import '../../core/widgets/admin_states.dart';
import '../../../auth/providers/auth_controller.dart';
import '../data/students_repository.dart';
import '../models/student.dart';
import '../providers/students_providers.dart';

class StudentsListScreen extends ConsumerStatefulWidget {
  const StudentsListScreen({super.key});

  @override
  ConsumerState<StudentsListScreen> createState() => _StudentsListScreenState();
}

class _StudentsListScreenState extends ConsumerState<StudentsListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).value;
    if (!can(user, AdminPermissions.students)) {
      return const Scaffold(
        appBar: AppBar(title: Text('Students')),
        body: AdminEmptyView(message: 'You do not have students access.'),
      );
    }

    final listAsync = ref.watch(studentsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Students'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _openEditSheet(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          AdminSearchBar(
            hint: 'Search students',
            controller: _searchController,
            onChanged: (v) => ref.read(studentSearchProvider.notifier).state = v,
          ),
          Expanded(
            child: listAsync.when(
              loading: () => const AdminLoadingView(),
              error: (e, _) => AdminErrorView(
                message: 'Could not load students.\n$e',
                onRetry: () => ref.invalidate(studentsListProvider),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return const AdminEmptyView(message: 'No students found.');
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(studentsListProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final student = items[index];
                      return Card(
                        child: ListTile(
                          title: Text(student.name),
                          subtitle: Text('${student.admissionNo} · ${student.className}'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.push('/admin/people/students/${student.id}'),
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

  Future<void> _openEditSheet(BuildContext context, WidgetRef ref, {Student? student}) async {
    final name = TextEditingController(text: student?.name ?? '');
    final admission = TextEditingController(text: student?.admissionNo ?? '');
    final className = TextEditingController(text: student?.className ?? '');
    final email = TextEditingController(text: student?.email ?? '');
    final phone = TextEditingController(text: student?.phone ?? '');

    final saved = await showAdminEditSheet(
      context: context,
      title: student == null ? 'Add student' : 'Edit student',
      fields: [
        TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
        TextField(controller: admission, decoration: const InputDecoration(labelText: 'Admission no.')),
        TextField(controller: className, decoration: const InputDecoration(labelText: 'Class')),
        TextField(controller: email, decoration: const InputDecoration(labelText: 'Email')),
        TextField(controller: phone, decoration: const InputDecoration(labelText: 'Phone')),
      ],
      onSave: () async {
        final body = {
          'name': name.text.trim(),
          'admission_no': admission.text.trim(),
          'class_name': className.text.trim(),
          'email': email.text.trim(),
          'phone': phone.text.trim(),
        };
        final repo = ref.read(studentsRepositoryProvider);
        if (student == null) {
          await repo.create(body);
        } else {
          await repo.update(student.id, body);
        }
        ref.invalidate(studentsListProvider);
        if (student != null) ref.invalidate(studentDetailProvider(student.id));
      },
    );

    name.dispose();
    admission.dispose();
    className.dispose();
    email.dispose();
    phone.dispose();

    if (saved == true && student == null) {
      ref.invalidate(studentsListProvider);
    }
  }
}
