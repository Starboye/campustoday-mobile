import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../attendance/data/attendance_repository.dart';
import '../../attendance/providers/attendance_providers.dart';
import '../../shared/models/allocation.dart';
import '../data/teacher_homework_repository.dart';
import '../models/teacher_homework_item.dart';
import '../providers/teacher_homework_providers.dart';

class TeacherHomeworkFormScreen extends ConsumerStatefulWidget {
  const TeacherHomeworkFormScreen({super.key, this.existing});

  final TeacherHomeworkItem? existing;

  @override
  ConsumerState<TeacherHomeworkFormScreen> createState() => _TeacherHomeworkFormScreenState();
}

class _TeacherHomeworkFormScreenState extends ConsumerState<TeacherHomeworkFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  TeacherAllocation? _allocation;
  DateTime _date = DateTime.now();
  String _targetType = 'class';
  String? _studentId;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleController = TextEditingController(text: e?.title ?? '');
    _descriptionController = TextEditingController(text: e?.description ?? '');
    if (e != null) {
      _date = DateTime.tryParse(e.date) ?? DateTime.now();
      _targetType = e.targetType;
      _studentId = e.studentId;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allocationsAsync = ref.watch(teacherAllocationsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit homework' : 'Add homework')),
      body: allocationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load allocations.\n$e')),
        data: (classes) async {
          final allocations = await ref.read(attendanceRepositoryProvider).fetchAllocations();
          if (_allocation == null && allocations.isNotEmpty) {
            final match = widget.existing;
            _allocation = match != null
                ? allocations.firstWhere(
                    (a) => a.standard == match.standard && a.section == match.section,
                    orElse: () => allocations.first,
                  )
                : allocations.first;
          }
          return _buildForm(allocations);
        }(),
      ),
    );
  }

  Widget _buildForm(List<TeacherAllocation> allocations) {
    if (allocations.isEmpty) {
      return const Center(child: Text('No class allocations.'));
    }

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<TeacherAllocation>(
            value: _allocation,
            decoration: const InputDecoration(
              labelText: 'Subject / Class',
              border: OutlineInputBorder(),
            ),
            items: allocations
                .map(
                  (a) => DropdownMenuItem(
                    value: a,
                    child: Text('${a.subjectName} · Class ${a.standard}${a.section}'),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _allocation = v),
            validator: (v) => v == null ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Date'),
            subtitle: Text(DateFormat('d MMM yyyy').format(_date)),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime(_date.year - 1),
                lastDate: DateTime(_date.year + 1),
              );
              if (picked != null) setState(() => _date = picked);
            },
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _targetType,
            decoration: const InputDecoration(
              labelText: 'Target',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'class', child: Text('Whole class')),
              DropdownMenuItem(value: 'student', child: Text('Individual student')),
            ],
            onChanged: (v) => setState(() {
              _targetType = v ?? 'class';
              if (_targetType == 'class') _studentId = null;
            }),
          ),
          if (_targetType == 'student') ...[
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _studentId,
              decoration: const InputDecoration(
                labelText: 'Student ID',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => _studentId = v.trim().isEmpty ? null : v.trim(),
              validator: (v) =>
                  _targetType == 'student' && (v == null || v.isEmpty) ? 'Required' : null,
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
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
            ),
            maxLines: 4,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_isEdit ? 'Save changes' : 'Create homework'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _allocation == null) return;
    setState(() => _saving = true);

    final item = TeacherHomeworkItem(
      id: widget.existing?.id ?? '',
      subjectId: _allocation!.subjectId,
      subjectName: _allocation!.subjectName,
      standard: _allocation!.standard,
      section: _allocation!.section,
      date: DateFormat('yyyy-MM-dd').format(_date),
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      targetType: _targetType,
      studentId: _targetType == 'student' ? _studentId : null,
    );

    try {
      final repo = ref.read(teacherHomeworkRepositoryProvider);
      if (_isEdit) {
        await repo.updateHomework(item);
      } else {
        await repo.createHomework(item);
      }
      ref.invalidate(teacherHomeworkListProvider);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
