import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/dio_client.dart';

class AnnouncementFormScreen extends ConsumerStatefulWidget {
  const AnnouncementFormScreen({super.key});

  @override
  ConsumerState<AnnouncementFormScreen> createState() => _AnnouncementFormScreenState();
}

class _AnnouncementFormScreenState extends ConsumerState<AnnouncementFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _message = TextEditingController();
  String _targetType = 'class';
  final _studentId = TextEditingController();
  final _standard = TextEditingController();
  final _section = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _message.dispose();
    _studentId.dispose();
    _standard.dispose();
    _section.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final dio = ref.read(dioProvider);
      await dio.postJson('/teacher/announcements', data: {
        'title': _title.text.trim(),
        'message': _message.text.trim(),
        'target_type': _targetType,
        if (_targetType == 'student') 'student_id': _studentId.text.trim(),
        if (_targetType == 'class') ...{
          'standard': int.parse(_standard.text.trim()),
          'section': _section.text.trim(),
        },
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Announcement sent')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New announcement')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _message,
              decoration: const InputDecoration(labelText: 'Message'),
              maxLines: 4,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _targetType,
              decoration: const InputDecoration(labelText: 'Target'),
              items: const [
                DropdownMenuItem(value: 'class', child: Text('Class')),
                DropdownMenuItem(value: 'student', child: Text('Student')),
                DropdownMenuItem(value: 'all', child: Text('All')),
              ],
              onChanged: (v) => setState(() => _targetType = v ?? 'class'),
            ),
            if (_targetType == 'student') ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _studentId,
                decoration: const InputDecoration(labelText: 'Student ID'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
            ],
            if (_targetType == 'class') ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _standard,
                decoration: const InputDecoration(labelText: 'Standard'),
                keyboardType: TextInputType.number,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _section,
                decoration: const InputDecoration(labelText: 'Section'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
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
                  : const Text('Send'),
            ),
          ],
        ),
      ),
    );
  }
}
