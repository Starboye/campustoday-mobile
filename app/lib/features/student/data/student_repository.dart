import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';

final studentRepositoryProvider = Provider<StudentRepository>((ref) {
  return StudentRepository(ref.watch(dioProvider));
});

class StudentRepository {
  StudentRepository(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> fetchDashboard() async {
    return _dio.getJson<Map<String, dynamic>>('/student/dashboard');
  }

  Future<List<Map<String, dynamic>>> fetchAnnouncements() async {
    final data = await _dio.getJson<Map<String, dynamic>>('/student/announcements');
    return (data['items'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
  }

  Future<void> markAnnouncementRead(int id) async {
    await _dio.patchJson<Map<String, dynamic>>('/student/announcements/$id/read');
  }

  Future<Map<String, dynamic>> fetchTimetable() async {
    return _dio.getJson<Map<String, dynamic>>('/student/timetable');
  }

  Future<List<Map<String, dynamic>>> fetchFees() async {
    final data = await _dio.getJson<Map<String, dynamic>>('/student/fees');
    return (data['items'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> fetchReportCard() async {
    return _dio.getJson<Map<String, dynamic>>('/student/report-card');
  }

  Future<List<int>> downloadReportPdf() async {
    final response = await _dio.get<List<int>>(
      '/student/report-card.pdf',
      options: Options(responseType: ResponseType.bytes),
    );
    return response.data ?? [];
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _dio.postJson('/auth/change-password', data: {
      'current_password': currentPassword,
      'new_password': newPassword,
    });
  }
}
