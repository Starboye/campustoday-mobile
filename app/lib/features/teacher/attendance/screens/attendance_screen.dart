import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/offline/attendance_queue.dart';
import '../../../../core/offline/attendance_sync_listener.dart';
import '../data/attendance_repository.dart';
import '../models/attendance_models.dart';
import '../providers/attendance_providers.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  String? _errorMessage;
  String? _queuedMessage;

  @override
  Widget build(BuildContext context) {
    ref.watch(attendanceSyncListenerProvider);
    final pendingAsync = ref.watch(pendingAttendanceCountProvider);
    final allocationsAsync = ref.watch(teacherAllocationsProvider);
    final selected = ref.watch(selectedClassProvider);
    final selectedDate = ref.watch(attendanceDateProvider);
    final dateLabel = DateFormat('EEE, d MMM yyyy').format(selectedDate);

    ref.listen(selectedClassProvider, (_, next) {
      if (next != null) {
        ref.invalidate(attendanceSheetProvider);
      }
    });

    return Column(
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
              final effective = selected ?? classes.first;
              if (selected == null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ref.read(selectedClassProvider.notifier).state = classes.first;
                });
              }
              return DropdownButtonFormField<ClassSectionKey>(
                value: effective,
                decoration: const InputDecoration(
                  labelText: 'Class / Section',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: classes
                    .map(
                      (c) => DropdownMenuItem(value: c, child: Text(c.label)),
                    )
                    .toList(),
                onChanged: (v) => ref.read(selectedClassProvider.notifier).state = v,
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  ref.read(attendanceDateProvider.notifier).state =
                      selectedDate.subtract(const Duration(days: 1));
                },
              ),
              Expanded(
                child: InkWell(
                  onTap: () => _pickDate(context),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      dateLabel,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: const Color(AppConstants.navyColor),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  ref.read(attendanceDateProvider.notifier).state =
                      selectedDate.add(const Duration(days: 1));
                },
              ),
            ],
          ),
        ),
        pendingAsync.when(
          data: (count) {
            if (count == 0) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: MaterialBanner(
                content: Text(
                  count == 1
                      ? '1 attendance change is queued and will sync when you are back online.'
                      : '$count attendance changes are queued and will sync when you are back online.',
                ),
                leading: const Icon(Icons.cloud_upload_outlined, color: Colors.blue),
                actions: [
                  TextButton(
                    onPressed: _syncQueued,
                    child: const Text('Sync now'),
                  ),
                ],
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        if (_queuedMessage != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: MaterialBanner(
              content: Text(_queuedMessage!),
              leading: const Icon(Icons.cloud_off_outlined, color: Colors.blue),
              actions: [
                TextButton(
                  onPressed: () => setState(() => _queuedMessage = null),
                  child: const Text('Dismiss'),
                ),
              ],
            ),
          ),
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: MaterialBanner(
              content: Text(_errorMessage!),
              leading: const Icon(Icons.lock_outline, color: Colors.orange),
              actions: [
                TextButton(
                  onPressed: () => setState(() => _errorMessage = null),
                  child: const Text('Dismiss'),
                ),
              ],
            ),
          ),
        Expanded(child: _buildStudentList(selected)),
      ],
    );
  }

  Future<void> _syncQueued() async {
    final sync = ref.read(attendanceSyncServiceProvider);
    final result = await sync.syncPending();
    ref.invalidate(pendingAttendanceCountProvider);
    if (result.synced > 0) {
      ref.invalidate(attendanceSheetProvider);
    }
    if (!mounted) return;
    if (result.hasFailures) {
      setState(() => _errorMessage = result.lastError ?? 'Sync failed.');
    } else if (result.synced > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Synced ${result.synced} queued change(s).')),
      );
    }
  }

  Future<void> _pickDate(BuildContext context) async {
    final current = ref.read(attendanceDateProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(current.year - 1),
      lastDate: DateTime(current.year + 1),
    );
    if (picked != null) {
      ref.read(attendanceDateProvider.notifier).state = picked;
    }
  }

  Widget _buildStudentList(ClassSectionKey? selected) {
    if (selected == null) {
      return const Center(child: Text('Select a class to mark attendance.'));
    }

    final sheetAsync = ref.watch(attendanceSheetProvider);

    return sheetAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Could not load attendance.\n$e', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(attendanceSheetProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (sheet) {
        if (sheet.locked) {
          return Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.lock, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(child: Text('This day is locked. Attendance cannot be edited.')),
                  ],
                ),
              ),
              Expanded(child: _AttendanceList(sheet: sheet, readOnly: true, onToggle: null)),
            ],
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await _syncQueued();
            ref.invalidate(attendanceSheetProvider);
          },
          child: _AttendanceList(
            sheet: sheet,
            readOnly: false,
            onToggle: (studentId, session, status) async {
              ref.invalidate(attendanceLocalStateProvider);
              final repo = ref.read(attendanceRepositoryProvider);
              try {
                final student = sheet.students.firstWhere((s) => s.studentId == studentId);
                final existing = student.sessions[session];
                final newStatus = existing == status ? null : status;
                final result = await repo.updateAttendance(
                  standard: sheet.standard,
                  section: sheet.section,
                  date: sheet.date,
                  studentId: studentId,
                  session: session,
                  status: newStatus,
                );
                if (result == AttendanceUpdateResult.queued) {
                  ref.invalidate(pendingAttendanceCountProvider);
                  if (mounted) {
                    setState(
                      () => _queuedMessage =
                          'Saved offline. Changes will sync when you reconnect.',
                    );
                  }
                } else {
                  ref.invalidate(attendanceSheetProvider);
                }
              } catch (e) {
                if (mounted) {
                  final message = e.toString().contains('locked')
                      ? 'Attendance day is locked — changes cannot be saved.'
                      : e.toString();
                  setState(() => _errorMessage = message);
                }
              }
            },
          ),
        );
      },
    );
  }
}

class _AttendanceList extends StatelessWidget {
  const _AttendanceList({
    required this.sheet,
    required this.readOnly,
    required this.onToggle,
  });

  final AttendanceSheet sheet;
  final bool readOnly;
  final Future<void> Function(String studentId, AttendanceSession session, AttendanceStatus status)?
      onToggle;

  @override
  Widget build(BuildContext context) {
    if (sheet.students.isEmpty) {
      return const Center(child: Text('No students in this class.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: sheet.students.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final student = sheet.students[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (student.rollNo.isNotEmpty)
                      Container(
                        width: 32,
                        alignment: Alignment.center,
                        child: Text(
                          student.rollNo,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    Expanded(
                      child: Text(
                        student.name,
                        style: const TextStyle(
                          color: Color(AppConstants.navyColor),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: AttendanceSession.values.map((session) {
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: _SessionChipRow(
                          label: session.label,
                          status: student.sessions[session],
                          readOnly: readOnly,
                          onSelect: (status) =>
                              onToggle?.call(student.studentId, session, status),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SessionChipRow extends StatelessWidget {
  const _SessionChipRow({
    required this.label,
    required this.status,
    required this.readOnly,
    required this.onSelect,
  });

  final String label;
  final AttendanceStatus? status;
  final bool readOnly;
  final void Function(AttendanceStatus status)? onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: AttendanceStatus.values.map((s) {
            final selected = status == s;
            final color = switch (s) {
              AttendanceStatus.present => Colors.green,
              AttendanceStatus.absent => Colors.red,
              AttendanceStatus.leave => Colors.orange,
            };
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: ChoiceChip(
                label: Text(
                  switch (s) {
                    AttendanceStatus.present => 'P',
                    AttendanceStatus.absent => 'A',
                    AttendanceStatus.leave => 'L',
                  },
                  style: TextStyle(
                    fontSize: 11,
                    color: selected ? Colors.white : color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                selected: selected,
                showCheckmark: false,
                visualDensity: VisualDensity.compact,
                selectedColor: color,
                backgroundColor: color.withValues(alpha: 0.1),
                onSelected: readOnly
                    ? null
                    : (_) => onSelect?.call(s),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
