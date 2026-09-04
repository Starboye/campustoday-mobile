import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';

final announcementsRepositoryProvider = Provider<AnnouncementsRepository>((ref) {
  return AnnouncementsRepository(ref.watch(dioProvider));
});

class AnnouncementsRepository {
  AnnouncementsRepository(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> createAnnouncement({
    required String title,
    required String message,
    required String targetType,
    String? studentId,
    int? standard,
    String? section,
  }) async {
    return _dio.postJson<Map<String, dynamic>>(
      '/teacher/announcements',
      data: {
        'title': title,
        'message': message,
        'target_type': targetType,
        if (studentId != null) 'student_id': studentId,
        if (standard != null) 'standard': standard,
        if (section != null) 'section': section,
      },
    );
  }
}
