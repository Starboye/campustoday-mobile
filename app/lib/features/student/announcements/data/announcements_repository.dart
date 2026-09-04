import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/api_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../models/announcement_item.dart';

final announcementsRepositoryProvider = Provider<AnnouncementsRepository>((ref) {
  return AnnouncementsRepository(ref.watch(dioProvider));
});

class AnnouncementsRepository {
  AnnouncementsRepository(this._dio);

  final Dio _dio;

  Future<AnnouncementsResponse> fetchAnnouncements() async {
    final data = await _dio.getJson<Map<String, dynamic>>('/student/announcements');
    return AnnouncementsResponse.fromJson(data);
  }

  Future<void> markRead(int id) async {
    try {
      await _dio.patch<dynamic>('/student/announcements/$id/read');
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map && data['message'] is String) {
        throw ApiException(data['message'] as String, statusCode: e.response?.statusCode);
      }
      throw ApiException(e.message ?? 'Network error', statusCode: e.response?.statusCode);
    }
  }
}
