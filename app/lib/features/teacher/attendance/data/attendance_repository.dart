import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../core/teacher_dio_extensions.dart';
import '../../shared/models/allocation.dart';
import '../models/attendance_models.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepository(ref.watch(dioProvider));
});

class AttendanceRepository {
  AttendanceRepository(this._dio);

  final Dio _dio;

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

  Future<void> updateAttendance({
    required int standard,
    required String section,
    required String date,
    required String studentId,
    required AttendanceSession session,
    required AttendanceStatus? status,
  }) async {
    await _dio.putJson<Map<String, dynamic>>(
      '/teacher/attendance',
      data: {
        'standard': standard,
        'section': section,
        'date': date,
        'student_id': studentId,
        'session': session.apiValue,
        'status': status?.apiValue,
      },
    );
  }
}
