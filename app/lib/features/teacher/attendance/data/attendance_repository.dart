import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/offline/attendance_queue.dart';
import '../../../../core/offline/connectivity_service.dart';
import '../../core/teacher_dio_extensions.dart';
import '../../shared/models/allocation.dart';
import '../models/attendance_models.dart';

enum AttendanceUpdateResult { synced, queued }

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepository(
    ref.watch(dioProvider),
    queue: ref.watch(attendanceQueueProvider),
    connectivity: ref.watch(connectivityServiceProvider),
  );
});

class AttendanceRepository {
  AttendanceRepository(
    this._dio, {
    required AttendanceQueue queue,
    required ConnectivityService connectivity,
  })  : _queue = queue,
        _connectivity = connectivity;

  final Dio _dio;
  final AttendanceQueue _queue;
  final ConnectivityService _connectivity;

  Future<List<TeacherAllocation>> fetchAllocations() async {
    final data = await _dio.getJson<Map<String, dynamic>>('/teacher/allocations');
    return (data['items'] as List<dynamic>)
        .map((e) => TeacherAllocation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AttendanceSheet> fetchAttendance({
    required int standard,
    required String section,
    required String date,
  }) async {
    final data = await _dio.getJson<Map<String, dynamic>>(
      '/teacher/attendance',
      queryParameters: {
        'standard': standard,
        'section': section,
        'date': date,
      },
    );
    return AttendanceSheet.fromJson(data);
  }

  Future<AttendanceUpdateResult> updateAttendance({
    required int standard,
    required String section,
    required String date,
    required String studentId,
    required AttendanceSession session,
    required AttendanceStatus? status,
  }) async {
    final payload = {
      'standard': standard,
      'section': section,
      'date': date,
      'student_id': studentId,
      'session': session.apiValue,
      'status': status?.apiValue,
    };

    if (!await _connectivity.isOnline()) {
      await _queue.enqueue(
        standard: standard,
        section: section,
        date: date,
        studentId: studentId,
        session: session,
        status: status,
      );
      return AttendanceUpdateResult.queued;
    }

    try {
      await _dio.putJson<Map<String, dynamic>>('/teacher/attendance', data: payload);
      return AttendanceUpdateResult.synced;
    } catch (e) {
      if (isOfflineDioError(e)) {
        await _queue.enqueue(
          standard: standard,
          section: section,
          date: date,
          studentId: studentId,
          session: session,
          status: status,
        );
        return AttendanceUpdateResult.queued;
      }
      rethrow;
    }
  }
}
