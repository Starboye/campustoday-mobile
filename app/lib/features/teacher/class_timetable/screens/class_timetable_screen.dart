import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../data/class_timetable_repository.dart';
import '../models/class_timetable_models.dart';
import '../providers/class_timetable_providers.dart';

class ClassTimetableScreen extends ConsumerStatefulWidget {
  const ClassTimetableScreen({super.key});

  @override
  ConsumerState<ClassTimetableScreen> createState() => _ClassTimetableScreenState();
}

class _ClassTimetableScreenState extends ConsumerState<ClassTimetableScreen> {
  List<ClassTimetableItem>? _editedItems;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final timetableAsync = ref.watch(classTimetableProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Class timetable'),
        actions: [
          timetableAsync.whenOrNull(
            data: (data) {
              if (data.status == 'approved') return null;
              return TextButton(
                onPressed: _busy ? null : () => _submit(data),
                child: const Text('Submit'),
              );
            },
          ) ?? const SizedBox.shrink(),
        ],
      ),
      body: timetableAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Could not load class timetable.\n$e', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.invalidate(classTimetableProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (data) {
          final items = _editedItems ?? data.items;
          final locked = data.status == 'approved';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    if (data.classLabel.isNotEmpty)
                      Expanded(
                        child: Text(
                          data.classLabel,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: const Color(AppConstants.navyColor),
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    Chip(
                      label: Text(data.status.toUpperCase()),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: items.isEmpty
                    ? Center(
                        child: Text(
                          locked
                              ? 'No timetable entries.'
                              : 'No slots yet. Add subjects to build the weekly grid.',
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          setState(() => _editedItems = null);
                          ref.invalidate(classTimetableProvider);
                        },
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final item = items[index];
                            final timeLabel = [
                              if (item.startTime != null) item.startTime,
                              if (item.endTime != null) item.endTime,
                            ].join(' – ');

                            return Card(
                              child: ListTile(
                                title: Text(
                                  item.subjectName.isEmpty ? 'Unassigned' : item.subjectName,
                                  style: const TextStyle(
                                    color: Color(AppConstants.navyColor),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  '${item.day} · Period ${item.period}'
                                  '${timeLabel.isNotEmpty ? ' · $timeLabel' : ''}',
                                ),
                                trailing: locked
                                    ? null
                                    : IconButton(
                                        icon: const Icon(Icons.edit_outlined),
                                        onPressed: () => _editItem(item, items, data),
                                      ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
              if (!locked)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: FilledButton(
                    onPressed: _busy || _editedItems == null ? null : () => _save(data),
                    child: _busy
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save draft'),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _editItem(
    ClassTimetableItem item,
    List<ClassTimetableItem> items,
    ClassTimetableResponse data,
  ) async {
    final subject = TextEditingController(text: item.subjectName);
    final teacherId = TextEditingController(text: item.teacherId);

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${item.day} · Period ${item.period}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: subject,
              decoration: const InputDecoration(
                labelText: 'Subject',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: teacherId,
              decoration: const InputDecoration(
                labelText: 'Teacher ID (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Apply')),
        ],
      ),
    );

    if (saved == true) {
      final updated = items.map((e) {
        if (e.slotId == item.slotId) {
          return ClassTimetableItem(
            assignmentId: e.assignmentId,
            slotId: e.slotId,
            day: e.day,
            period: e.period,
            subjectName: subject.text.trim(),
            teacherId: teacherId.text.trim(),
            startTime: e.startTime,
            endTime: e.endTime,
          );
        }
        return e;
      }).toList();
      setState(() => _editedItems = updated);
    }

    subject.dispose();
    teacherId.dispose();
  }

  Future<void> _save(ClassTimetableResponse data) async {
    final items = _editedItems ?? data.items;
    setState(() => _busy = true);
    try {
      await ref.read(classTimetableRepositoryProvider).updateTimetable(items);
      setState(() => _editedItems = null);
      ref.invalidate(classTimetableProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Timetable saved.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit(ClassTimetableResponse data) async {
    if (_editedItems != null) {
      await _save(data);
    }

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

    setState(() => _busy = true);
    try {
      await ref.read(classTimetableRepositoryProvider).submitTimetable();
      setState(() => _editedItems = null);
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
      if (mounted) setState(() => _busy = false);
    }
  }
}
