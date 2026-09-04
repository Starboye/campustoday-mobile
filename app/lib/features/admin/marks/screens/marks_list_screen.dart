import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/admin_permissions.dart';
import '../../core/permission.dart';
import '../../core/widgets/admin_edit_sheet.dart';
import '../../core/widgets/admin_states.dart';
import '../../../auth/providers/auth_controller.dart';
import '../data/marks_repository.dart';
import '../providers/marks_providers.dart';

class MarksListScreen extends ConsumerWidget {
  const MarksListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    if (!can(user, AdminPermissions.marks)) {
      return const Scaffold(
        appBar: AppBar(title: Text('Marks')),
        body: AdminEmptyView(message: 'You do not have marks access.'),
      );
    }

    final listAsync = ref.watch(marksListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Marks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _addMark(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(labelText: 'Student ID'),
                    onSubmitted: (v) => ref.read(marksStudentProvider.notifier).state = v,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(labelText: 'Term'),
                    onSubmitted: (v) => ref.read(marksTermProvider.notifier).state = v,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: listAsync.when(
              loading: () => const AdminLoadingView(),
              error: (e, _) => AdminErrorView(
                message: 'Could not load marks.\n$e',
                onRetry: () => ref.invalidate(marksListProvider),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return const AdminEmptyView(message: 'No marks found.');
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(marksListProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final entry = items[index];
                      return Card(
                        child: ListTile(
                          title: Text(entry.studentName),
                          subtitle: Text('${entry.subject} · ${entry.term}'),
                          trailing: Text(entry.score.toStringAsFixed(1)),
                          onTap: () => _editMark(context, ref, entry),
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

  Future<void> _addMark(BuildContext context, WidgetRef ref) async {
    final studentId = TextEditingController();
    final subject = TextEditingController();
    final term = TextEditingController();
    final score = TextEditingController();

    await showAdminEditSheet(
      context: context,
      title: 'Add marks',
      fields: [
        TextField(controller: studentId, decoration: const InputDecoration(labelText: 'Student ID')),
        TextField(controller: subject, decoration: const InputDecoration(labelText: 'Subject')),
        TextField(controller: term, decoration: const InputDecoration(labelText: 'Term')),
        TextField(controller: score, decoration: const InputDecoration(labelText: 'Score'), keyboardType: TextInputType.number),
      ],
      onSave: () async {
        await ref.read(marksRepositoryProvider).save({
          'student_id': studentId.text.trim(),
          'subject': subject.text.trim(),
          'term': term.text.trim(),
          'score': double.tryParse(score.text.trim()) ?? 0,
        });
        ref.invalidate(marksListProvider);
      },
    );

    studentId.dispose();
    subject.dispose();
    term.dispose();
    score.dispose();
  }

  Future<void> _editMark(BuildContext context, WidgetRef ref, MarksEntry entry) async {
    final subject = TextEditingController(text: entry.subject);
    final term = TextEditingController(text: entry.term);
    final score = TextEditingController(text: entry.score.toString());

    await showAdminEditSheet(
      context: context,
      title: 'Edit marks',
      fields: [
        TextField(controller: subject, decoration: const InputDecoration(labelText: 'Subject')),
        TextField(controller: term, decoration: const InputDecoration(labelText: 'Term')),
        TextField(controller: score, decoration: const InputDecoration(labelText: 'Score'), keyboardType: TextInputType.number),
      ],
      onSave: () async {
        await ref.read(marksRepositoryProvider).update(entry.id, {
          'subject_name': subject.text.trim(),
          'term': term.text.trim(),
          'marks': double.tryParse(score.text.trim()) ?? entry.score,
        });
        ref.invalidate(marksListProvider);
      },
    );

    subject.dispose();
    term.dispose();
    score.dispose();
  }
}
