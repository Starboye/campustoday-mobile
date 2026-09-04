import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../core/admin_api.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepository(ref.watch(dioProvider));
});

class AttendanceRepository {
  AttendanceRepository(this._dio);

  final Dio _dio;

  Future<List<AttendanceRecord>> list({required String date, String? className}) async {
    final data = await _dio.adminGet<dynamic>(
      '/admin/attendance',
      queryParameters: {'date': date, if (className != null) 'class': className},
    );
    return parseListData(data).map(AttendanceRecord.fromJson).toList();
  }

  Future<void> delete(String id) async {
    await _dio.adminDelete('/admin/attendance/$id');
  }
}

class AttendanceRecord {
  const AttendanceRecord({
    required this.id,
    required this.studentName,
    required this.className,
    required this.status,
    required this.date,
  });

  final String id;
  final String studentName;
  final String className;
  final String status;
  final String date;

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: '${json['id']}',
      studentName: json['student_name']?.toString() ?? '',
      className: json['class_name']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
    );
  }
}
