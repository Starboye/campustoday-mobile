import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/attendance_repository.dart';
import '../models/attendance_models.dart';

final attendanceDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

final teacherAllocationsProvider = FutureProvider.autoDispose<List<ClassSectionKey>>((ref) async {
  final allocations = await ref.watch(attendanceRepositoryProvider).fetchAllocations();
  final keys = <ClassSectionKey>{};
  for (final a in allocations) {
    keys.add(ClassSectionKey.fromAllocation(a));
  }
  return keys.toList()
    ..sort((a, b) {
      final std = a.standard.compareTo(b.standard);
      return std != 0 ? std : a.section.compareTo(b.section);
    });
});

final selectedClassProvider = StateProvider<ClassSectionKey?>((ref) => null);

final attendanceSheetProvider =
    FutureProvider.autoDispose<AttendanceSheet>((ref) async {
  final selected = ref.watch(selectedClassProvider);
  if (selected == null) {
    throw StateError('No class selected');
  }
  final date = ref.watch(attendanceDateProvider);
  final formatted = DateFormat('yyyy-MM-dd').format(date);
  return ref.watch(attendanceRepositoryProvider).fetchAttendance(
        standard: selected.standard,
        section: selected.section,
        date: formatted,
      );
});

/// Optimistic local state for attendance edits.
final attendanceLocalStateProvider =
    StateNotifierProvider.autoDispose<AttendanceLocalNotifier, AsyncValue<AttendanceSheet>>(
  (ref) => AttendanceLocalNotifier(ref),
);

class AttendanceLocalNotifier extends StateNotifier<AsyncValue<AttendanceSheet>> {
  AttendanceLocalNotifier(this._ref) : super(const AsyncValue.loading()) {
    _load();
    _ref.listen(attendanceSheetProvider, (_, next) {
      next.whenData((sheet) {
        if (!state.hasValue || state.requireValue.date != sheet.date) {
          state = AsyncValue.data(sheet);
        }
      });
    });
  }

  final Ref _ref;

  Future<void> _load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _ref.read(attendanceSheetProvider.future));
  }

  Future<void> refresh() async {
    _ref.invalidate(attendanceSheetProvider);
    await _load();
  }

  Future<String?> toggleStatus({
    required String studentId,
    required AttendanceSession session,
    required AttendanceStatus status,
  }) async {
    final current = state.valueOrNull;
    if (current == null) return 'No data loaded';
    if (current.locked) return 'Attendance is locked for this day';

    final studentIndex = current.students.indexWhere((s) => s.studentId == studentId);
    if (studentIndex < 0) return 'Student not found';

    final student = current.students[studentIndex];
    final existing = student.sessions[session];
    final newStatus = existing == status ? null : status;

    final updatedStudents = List<StudentAttendanceRow>.from(current.students);
    updatedStudents[studentIndex] = student.copyWithSession(session, newStatus);
    final optimistic = current.copyWithStudents(updatedStudents);
    state = AsyncValue.data(optimistic);

    try {
      await _ref.read(attendanceRepositoryProvider).updateAttendance(
            standard: current.standard,
            section: current.section,
            date: current.date,
            studentId: studentId,
            session: session,
            status: newStatus,
          );
      return null;
    } catch (e) {
      state = AsyncValue.data(current);
      return e.toString();
    }
  }
}
