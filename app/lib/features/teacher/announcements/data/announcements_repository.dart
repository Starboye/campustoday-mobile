import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';

final announcementsRepositoryProvider = Provider<AnnouncementsRepository>((ref) {
  return AnnouncementsRepository(ref.watch(dioProvider));
});

class AnnouncementPayload {
  const AnnouncementPayload({
    required this.title,
    required this.message,
    required this.targetType,
    this.studentId,
    this.standard,
    this.section,
  });

  final String title;
  final String message;
  final String targetType;
  final String? studentId;
  final int? standard;
  final String? section;

  Map<String, dynamic> toJson() => {
        'title': title,
        'message': message,
        'target_type': targetType,
        if (studentId != null) 'student_id': studentId,
        if (standard != null) 'standard': standard,
        if (section != null) 'section': section,
      };
}

class AnnouncementsRepository {
  AnnouncementsRepository(this._dio);

  final Dio _dio;

  Future<void> createAnnouncement(AnnouncementPayload payload) async {
    await _dio.postJson<Map<String, dynamic>>(
      '/teacher/announcements',
      data: payload.toJson(),
    );
  }
}
