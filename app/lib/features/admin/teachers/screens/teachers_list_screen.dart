import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/admin_permissions.dart';
import '../../core/permission.dart';
import '../../core/widgets/admin_edit_sheet.dart';
import '../../core/widgets/admin_search_bar.dart';
import '../../core/widgets/admin_states.dart';
import '../../../auth/providers/auth_controller.dart';
import '../data/teachers_repository.dart';
import '../models/teacher.dart';
import '../providers/teachers_providers.dart';

class TeachersListScreen extends ConsumerStatefulWidget {
  const TeachersListScreen({super.key});

  @override
  ConsumerState<TeachersListScreen> createState() => _TeachersListScreenState();
}

class _TeachersListScreenState extends ConsumerState<TeachersListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).value;
    if (!can(user, AdminPermissions.teachers)) {
      return const Scaffold(
        appBar: AppBar(title: Text('Teachers')),
        body: AdminEmptyView(message: 'You do not have teachers access.'),
      );
    }

    final listAsync = ref.watch(teachersListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Teachers'),
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
            hint: 'Search teachers',
            controller: _searchController,
            onChanged: (v) => ref.read(teacherSearchProvider.notifier).state = v,
          ),
          Expanded(
            child: listAsync.when(
              loading: () => const AdminLoadingView(),
              error: (e, _) => AdminErrorView(
                message: 'Could not load teachers.\n$e',
                onRetry: () => ref.invalidate(teachersListProvider),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return const AdminEmptyView(message: 'No teachers found.');
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(teachersListProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final teacher = items[index];
                      return Card(
                        child: ListTile(
                          title: Text(teacher.name),
                          subtitle: Text('${teacher.employeeId} · ${teacher.subjects}'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.push('/admin/people/teachers/${teacher.id}'),
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

  Future<void> _openEditSheet(BuildContext context, WidgetRef ref, {Teacher? teacher}) async {
    final name = TextEditingController(text: teacher?.name ?? '');
    final employeeId = TextEditingController(text: teacher?.employeeId ?? '');
    final subjects = TextEditingController(text: teacher?.subjects ?? '');
    final email = TextEditingController(text: teacher?.email ?? '');
    final phone = TextEditingController(text: teacher?.phone ?? '');

    await showAdminEditSheet(
      context: context,
      title: teacher == null ? 'Add teacher' : 'Edit teacher',
      fields: [
        TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
        TextField(controller: employeeId, decoration: const InputDecoration(labelText: 'Employee ID')),
        TextField(controller: subjects, decoration: const InputDecoration(labelText: 'Subjects')),
        TextField(controller: email, decoration: const InputDecoration(labelText: 'Email')),
        TextField(controller: phone, decoration: const InputDecoration(labelText: 'Phone')),
      ],
      onSave: () async {
        final body = {
          'name': name.text.trim(),
          'employee_id': employeeId.text.trim(),
          'subjects': subjects.text.trim(),
          'email': email.text.trim(),
          'phone': phone.text.trim(),
        };
        final repo = ref.read(teachersRepositoryProvider);
        if (teacher == null) {
          await repo.create(body);
        } else {
          await repo.update(teacher.id, body);
        }
        ref.invalidate(teachersListProvider);
        if (teacher != null) ref.invalidate(teacherDetailProvider(teacher.id));
      },
    );

    name.dispose();
    employeeId.dispose();
    subjects.dispose();
    email.dispose();
    phone.dispose();
  }
}
