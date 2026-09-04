import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../core/admin_api.dart';

final attendanceLocksRepositoryProvider = Provider<AttendanceLocksRepository>((ref) {
  return AttendanceLocksRepository(ref.watch(dioProvider));
});

class AttendanceLocksRepository {
  AttendanceLocksRepository(this._dio);

  final Dio _dio;

  Future<List<AttendanceLock>> list() async {
    final data = await _dio.adminGet<dynamic>('/admin/attendance-locks');
    return parseListData(data).map(AttendanceLock.fromJson).toList();
  }

  Future<void> lock(String date) async {
    await _dio.adminPost('/admin/attendance-locks', data: {'date': date});
  }

  Future<void> unlock(String id) async {
    await _dio.adminDelete('/admin/attendance-locks/$id');
  }
}

class AttendanceLock {
  const AttendanceLock({required this.id, required this.date, required this.lockedBy});

  final String id;
  final String date;
  final String lockedBy;

  factory AttendanceLock.fromJson(Map<String, dynamic> json) {
    return AttendanceLock(
      id: '${json['id']}',
      date: json['date']?.toString() ?? '',
      lockedBy: json['locked_by']?.toString() ?? '',
    );
  }
}
