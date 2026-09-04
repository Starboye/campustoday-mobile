import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../attendance/models/attendance_models.dart';
import '../../attendance/providers/attendance_providers.dart';
import '../data/announcements_repository.dart';

class AnnouncementFormScreen extends ConsumerStatefulWidget {
  const AnnouncementFormScreen({super.key});

  @override
  ConsumerState<AnnouncementFormScreen> createState() => _AnnouncementFormScreenState();
}

class _AnnouncementFormScreenState extends ConsumerState<AnnouncementFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  String _targetType = 'class';
  ClassSectionKey? _classSection;
  final _studentIdController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _studentIdController.dispose();
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
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _targetType,
              decoration: const InputDecoration(
                labelText: 'Audience',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'class', child: Text('A class')),
                DropdownMenuItem(value: 'student', child: Text('Individual student')),
                DropdownMenuItem(value: 'all', child: Text('All students')),
              ],
              onChanged: (v) => setState(() => _targetType = v ?? 'class'),
            ),
            if (_targetType == 'class') ...[
              const SizedBox(height: 16),
              allocationsAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Could not load classes: $e'),
                data: (classes) {
                  if (classes.isEmpty) {
                    return const Text('No class allocations.');
                  }
                  if (_classSection == null) {
                    _classSection = classes.first;
                  }
                  return DropdownButtonFormField<ClassSectionKey>(
                    value: _classSection,
                    decoration: const InputDecoration(
                      labelText: 'Class',
                      border: OutlineInputBorder(),
                    ),
                    items: classes
                        .map((c) => DropdownMenuItem(value: c, child: Text(c.label)))
                        .toList(),
                    onChanged: (v) => setState(() => _classSection = v),
                    validator: (v) => _targetType == 'class' && v == null ? 'Required' : null,
                  );
                },
              ),
            ],
            if (_targetType == 'student') ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _studentIdController,
                decoration: const InputDecoration(
                  labelText: 'Student ID',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    _targetType == 'student' && (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
            ],
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
    setState(() => _saving = true);

    try {
      await ref.read(announcementsRepositoryProvider).createAnnouncement(
            title: _titleController.text.trim(),
            message: _messageController.text.trim(),
            targetType: _targetType,
            studentId: _targetType == 'student' ? _studentIdController.text.trim() : null,
            standard: _targetType == 'class' ? _classSection?.standard : null,
            section: _targetType == 'class' ? _classSection?.section : null,
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
