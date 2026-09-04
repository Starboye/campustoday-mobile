import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/async_content.dart';
import '../data/class_timetable_repository.dart';
import '../models/class_timetable_models.dart';
import '../providers/class_timetable_providers.dart';

class ClassTimetableScreen extends ConsumerStatefulWidget {
  const ClassTimetableScreen({super.key});

  @override
  ConsumerState<ClassTimetableScreen> createState() => _ClassTimetableScreenState();
}

class _ClassTimetableScreenState extends ConsumerState<ClassTimetableScreen> {
  final Map<int, TextEditingController> _controllers = {};
  bool _saving = false;
  bool _submitting = false;

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerFor(ClassTimetableItem item) {
    return _controllers.putIfAbsent(
      item.slotId,
      () => TextEditingController(text: item.subjectName),
    );
  }

  @override
  Widget build(BuildContext context) {
    final timetableAsync = ref.watch(classTimetableProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Class timetable')),
      body: timetableAsync.when(
        loading: () => const LoadingContent(),
        error: (e, _) => ErrorContent(
          message: 'Could not load class timetable.\n$e',
          onRetry: () => ref.invalidate(classTimetableProvider),
        ),
        data: (response) => _buildContent(response),
      ),
      bottomNavigationBar: timetableAsync.maybeWhen(
        data: (response) {
          if (!response.isEditable || response.items.isEmpty) return null;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : () => _saveDraft(response),
                      child: _saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save draft'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _submitting ? null : () => _submit(response),
                      child: _submitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Submit'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        orElse: () => null,
      ),
    );
  }

  Widget _buildContent(ClassTimetableResponse response) {
    final byDay = response.itemsByDay;

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(classTimetableProvider),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              title: Text(response.classLabel),
              subtitle: Text('Status: ${response.status}'),
              trailing: response.isEditable
                  ? const Icon(Icons.edit_outlined)
                  : const Icon(Icons.lock_outline),
            ),
          ),
          if (response.items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: EmptyContent(
                message: 'No timetable slots assigned yet. Contact admin to set up slots.',
                icon: Icons.table_chart_outlined,
              ),
            )
          else
            ...byDay.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    entry.key,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: const Color(AppConstants.navyColor),
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  ...entry.value.map((item) => _SlotRow(
                        item: item,
                        editable: response.isEditable,
                        controller: _controllerFor(item),
                      )),
                ],
              );
            }),
        ],
      ),
    );
  }

  List<ClassTimetableItem> _collectItems(ClassTimetableResponse response) {
    return response.items.map((item) {
      final controller = _controllers[item.slotId];
      final subject = controller?.text.trim() ?? item.subjectName;
      return item.copyWith(subjectName: subject);
    }).toList();
  }

  Future<void> _saveDraft(ClassTimetableResponse response) async {
    setState(() => _saving = true);
    try {
      await ref.read(classTimetableRepositoryProvider).updateTimetable(_collectItems(response));
      ref.invalidate(classTimetableProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Draft saved.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _submit(ClassTimetableResponse response) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Submit timetable?'),
        content: const Text('Submit this timetable for admin approval?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Submit')),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _submitting = true);
    try {
      await ref.read(classTimetableRepositoryProvider).updateTimetable(_collectItems(response));
      await ref.read(classTimetableRepositoryProvider).submitTimetable();
      ref.invalidate(classTimetableProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Timetable submitted for approval.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

class _SlotRow extends StatelessWidget {
  const _SlotRow({
    required this.item,
    required this.editable,
    required this.controller,
  });

  final ClassTimetableItem item;
  final bool editable;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final timeLabel = item.startTime != null && item.endTime != null
        ? '${item.startTime} – ${item.endTime}'
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(AppConstants.primaryColor).withValues(alpha: 0.12),
              child: Text(
                '${item.period}',
                style: const TextStyle(
                  color: Color(AppConstants.primaryColor),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (timeLabel != null)
                    Text(timeLabel, style: Theme.of(context).textTheme.bodySmall),
                  editable
                      ? TextField(
                          controller: controller,
                          decoration: const InputDecoration(
                            labelText: 'Subject',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        )
                      : Text(
                          item.subjectName.isNotEmpty ? item.subjectName : '—',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
