import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/admin_permissions.dart';
import '../../core/permission.dart';
import '../../core/widgets/admin_edit_sheet.dart';
import '../../core/widgets/admin_states.dart';
import '../../../auth/providers/auth_controller.dart';
import '../data/exams_repository.dart';
import '../providers/exams_providers.dart';

class ExamsListScreen extends ConsumerWidget {
  const ExamsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    if (!can(user, AdminPermissions.exams)) {
      return const Scaffold(
        appBar: AppBar(title: Text('Exams')),
        body: AdminEmptyView(message: 'You do not have exams access.'),
      );
    }

    final listAsync = ref.watch(examsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exams'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _addExam(context, ref),
          ),
        ],
      ),
      body: listAsync.when(
        loading: () => const AdminLoadingView(),
        error: (e, _) => AdminErrorView(
          message: 'Could not load exams.\n$e',
          onRetry: () => ref.invalidate(examsListProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const AdminEmptyView(message: 'No exam windows.');
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(examsListProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final exam = items[index];
                return Card(
                  child: ListTile(
                    title: Text(exam.name),
                    subtitle: Text('${exam.term} · ${exam.startDate} – ${exam.endDate}'),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _addExam(BuildContext context, WidgetRef ref) async {
    final name = TextEditingController();
    final term = TextEditingController();
    final start = TextEditingController();
    final end = TextEditingController();

    await showAdminEditSheet(
      context: context,
      title: 'Add exam window',
      fields: [
        TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
        TextField(controller: term, decoration: const InputDecoration(labelText: 'Term')),
        TextField(controller: start, decoration: const InputDecoration(labelText: 'Start date')),
        TextField(controller: end, decoration: const InputDecoration(labelText: 'End date')),
      ],
      onSave: () async {
        await ref.read(examsRepositoryProvider).save({
          'name': name.text.trim(),
          'term': term.text.trim(),
          'start_date': start.text.trim(),
          'end_date': end.text.trim(),
        });
        ref.invalidate(examsListProvider);
      },
    );

    name.dispose();
    term.dispose();
    start.dispose();
    end.dispose();
  }
}
