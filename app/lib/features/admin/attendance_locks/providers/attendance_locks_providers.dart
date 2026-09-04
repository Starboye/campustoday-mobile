import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/attendance_locks_repository.dart';

final attendanceLocksListProvider = FutureProvider.autoDispose<List<AttendanceLock>>((ref) {
  return ref.watch(attendanceLocksRepositoryProvider).list();
});
