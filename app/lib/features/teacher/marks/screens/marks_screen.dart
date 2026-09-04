import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../attendance/models/attendance_models.dart';
import '../../attendance/providers/attendance_providers.dart';
import '../data/marks_repository.dart';
import '../models/marks_models.dart';
import '../providers/marks_providers.dart';

class MarksScreen extends ConsumerWidget {
  const MarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allocationsAsync = ref.watch(teacherAllocationsProvider);
    final selected = ref.watch(marksClassFilterProvider);
    final marksAsync = ref.watch(teacherMarksListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Marks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Enter marks',
            onPressed: () => _showMarkEditor(context, ref),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: allocationsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Could not load classes: $e'),
              data: (classes) {
                if (classes.isEmpty) {
                  return const Text('No class allocations.');
                }
                return DropdownButtonFormField<ClassSectionKey?>(
                  value: selected,
                  decoration: const InputDecoration(
                    labelText: 'Filter by class',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem<ClassSectionKey?>(
                      value: null,
                      child: Text('All classes'),
                    ),
                    ...classes.map(
                      (c) => DropdownMenuItem(value: c, child: Text(c.label)),
                    ),
                  ],
                  onChanged: (v) => ref.read(marksClassFilterProvider.notifier).state = v,
                );
              },
            ),
          ),
          Expanded(
            child: marksAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Could not load marks.\n$e', textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => ref.invalidate(teacherMarksListProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (response) {
                if (response.items.isEmpty) {
                  return const Center(child: Text('No marks found.'));
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(teacherMarksListProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: response.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final row = response.items[index];
                      return Card(
                        child: ListTile(
                          title: Text(
                            row.studentName,
                            style: const TextStyle(
                              color: Color(AppConstants.navyColor),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            '${row.subjectName} · ${row.classLabel}'
                            '${row.term != null ? ' · Term ${row.term}' : ''}',
                          ),
                          trailing: Text(
                            '${row.marks ?? '—'}${row.maxMarks != null ? ' / ${row.maxMarks}' : ''}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          onTap: () => _showMarkEditor(context, ref, existing: row),
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

  Future<void> _showMarkEditor(
    BuildContext context,
    WidgetRef ref, {
    TeacherMarkRow? existing,
  }) async {
    final studentId = TextEditingController(text: existing?.studentId ?? '');
    final subject = TextEditingController(text: existing?.subjectName ?? '');
    final marks = TextEditingController(text: existing?.marks?.toString() ?? '');
    final term = TextEditingController(text: existing?.term?.toString() ?? '');
    final examType = TextEditingController(text: existing?.examType ?? '');
    final grade = TextEditingController(text: existing?.grade ?? '');
    final maxMarks = TextEditingController(text: existing?.maxMarks?.toString() ?? '');
    var saving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: StatefulBuilder(
          builder: (ctx, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                existing == null ? 'Enter marks' : 'Edit marks',
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: studentId,
                decoration: const InputDecoration(
                  labelText: 'Student ID',
                  border: OutlineInputBorder(),
                ),
                enabled: existing == null,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: subject,
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: marks,
                decoration: const InputDecoration(
                  labelText: 'Marks',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: term,
                decoration: const InputDecoration(
                  labelText: 'Term (optional)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: examType,
                decoration: const InputDecoration(
                  labelText: 'Exam type (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: grade,
                decoration: const InputDecoration(
                  labelText: 'Grade (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: maxMarks,
                decoration: const InputDecoration(
                  labelText: 'Max marks (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        if (studentId.text.trim().isEmpty ||
                            subject.text.trim().isEmpty ||
                            marks.text.trim().isEmpty) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(content: Text('Student ID, subject, and marks are required.')),
                          );
                          return;
                        }
                        setState(() => saving = true);
                        try {
                          await ref.read(teacherMarksRepositoryProvider).saveMark(
                                TeacherMarkUpdate(
                                  studentId: studentId.text.trim(),
                                  subjectName: subject.text.trim(),
                                  marks: marks.text.trim(),
                                  term: int.tryParse(term.text.trim()),
                                  examType: examType.text.trim().isEmpty ? null : examType.text.trim(),
                                  grade: grade.text.trim().isEmpty ? null : grade.text.trim(),
                                  maxMarks: maxMarks.text.trim().isEmpty ? null : maxMarks.text.trim(),
                                ),
                              );
                          ref.invalidate(teacherMarksListProvider);
                          if (ctx.mounted) Navigator.pop(ctx);
                        } catch (e) {
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('$e')));
                          }
                        } finally {
                          if (ctx.mounted) setState(() => saving = false);
                        }
                      },
                child: saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );

    studentId.dispose();
    subject.dispose();
    marks.dispose();
    term.dispose();
    examType.dispose();
    grade.dispose();
    maxMarks.dispose();
  }
}
