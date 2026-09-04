import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../attendance/models/attendance_models.dart';
import '../../attendance/providers/attendance_providers.dart';
import '../../students/data/students_repository.dart';
import '../../students/models/student_models.dart';
import '../data/announcements_repository.dart';

class AnnouncementComposeScreen extends ConsumerStatefulWidget {
  const AnnouncementComposeScreen({super.key});

  @override
  ConsumerState<AnnouncementComposeScreen> createState() =>
      _AnnouncementComposeScreenState();
}

class _AnnouncementComposeScreenState extends ConsumerState<AnnouncementComposeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  String _targetType = 'class';
  ClassSectionKey? _classKey;
  StudentSummary? _student;
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allocationsAsync = ref.watch(teacherAllocationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('New announcement')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<String>(
              value: _targetType,
              decoration: const InputDecoration(
                labelText: 'Audience',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'class', child: Text('A class')),
                DropdownMenuItem(value: 'student', child: Text('One student')),
                DropdownMenuItem(value: 'all', child: Text('All students')),
              ],
              onChanged: (v) => setState(() {
                _targetType = v ?? 'class';
                _student = null;
              }),
            ),
            const SizedBox(height: 16),
            if (_targetType == 'class')
              allocationsAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Could not load classes: $e'),
                data: (classes) {
                  if (classes.isEmpty) {
                    return const Text('No class allocations.');
                  }
                  final effective = _classKey ?? classes.first;
                  if (_classKey == null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      setState(() => _classKey = classes.first);
                    });
                  }
                  return DropdownButtonFormField<ClassSectionKey>(
                    value: effective,
                    decoration: const InputDecoration(
                      labelText: 'Class / Section',
                      border: OutlineInputBorder(),
                    ),
                    items: classes
                        .map((c) => DropdownMenuItem(value: c, child: Text(c.label)))
                        .toList(),
                    onChanged: (v) => setState(() => _classKey = v),
                    validator: (v) => v == null ? 'Required' : null,
                  );
                },
              ),
            if (_targetType == 'student') ...[
              _StudentPicker(
                selected: _student,
                onSelected: (s) => setState(() => _student = s),
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: 'Message',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Send announcement'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_targetType == 'student' && _student == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a student.')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      await ref.read(announcementsRepositoryProvider).createAnnouncement(
            AnnouncementPayload(
              title: _titleController.text.trim(),
              message: _messageController.text.trim(),
              targetType: _targetType,
              studentId: _student?.id,
              standard: _classKey?.standard,
              section: _classKey?.section,
            ),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Announcement sent.')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _StudentPicker extends ConsumerWidget {
  const _StudentPicker({required this.selected, required this.onSelected});

  final StudentSummary? selected;
  final ValueChanged<StudentSummary> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync = ref.watch(_announcementStudentsProvider);

    return studentsAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text('Could not load students: $e'),
      data: (students) {
        if (students.isEmpty) {
          return const Text('No students available.');
        }
        final effective = selected ?? students.first;
        if (selected == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) => onSelected(students.first));
        }
        return DropdownButtonFormField<StudentSummary>(
          value: effective,
          decoration: const InputDecoration(
            labelText: 'Student',
            border: OutlineInputBorder(),
          ),
          items: students
              .map(
                (s) => DropdownMenuItem(
                  value: s,
                  child: Text('${s.name} (${s.classLabel})'),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) onSelected(v);
          },
          validator: (v) => v == null ? 'Required' : null,
        );
      },
    );
  }
}

final _announcementStudentsProvider = FutureProvider.autoDispose<List<StudentSummary>>((ref) {
  return ref.watch(studentsRepositoryProvider).fetchStudents();
});
