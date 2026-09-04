import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'attendance_queue.dart';
import 'connectivity_service.dart';

final pendingAttendanceCountProvider = FutureProvider.autoDispose<int>((ref) {
  return ref.watch(attendanceQueueProvider).count();
});

final attendanceSyncListenerProvider = Provider<void>((ref) {
  final connectivity = ref.watch(connectivityServiceProvider);
  final sync = ref.watch(attendanceSyncServiceProvider);

  final sub = connectivity.onlineStream.listen((online) async {
    if (!online) return;
    final result = await sync.syncPending();
    if (result.synced > 0) {
      ref.invalidate(pendingAttendanceCountProvider);
    }
  });

  ref.onDispose(sub.cancel);
});
