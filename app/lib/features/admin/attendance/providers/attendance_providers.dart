import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/attendance_repository.dart';

final attendanceDateProvider = StateProvider.autoDispose<DateTime>((ref) => DateTime.now());
final attendanceClassProvider = StateProvider.autoDispose<String?>((ref) => null);

final attendanceListProvider = FutureProvider.autoDispose<List<AttendanceRecord>>((ref) {
  final date = ref.watch(attendanceDateProvider);
  final className = ref.watch(attendanceClassProvider);
  return ref.watch(attendanceRepositoryProvider).list(
        date: DateFormat('yyyy-MM-dd').format(date),
        className: className,
      );
});
