import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../core/teacher_dio_extensions.dart';
import '../models/teacher_homework_item.dart';

final teacherHomeworkRepositoryProvider = Provider<TeacherHomeworkRepository>((ref) {
  return TeacherHomeworkRepository(ref.watch(dioProvider));
});

class TeacherHomeworkRepository {
  TeacherHomeworkRepository(this._dio);

  final Dio _dio;

  Future<TeacherHomeworkListResponse> fetchHomework() async {
    final data = await _dio.getJson<Map<String, dynamic>>('/teacher/homework');
    return TeacherHomeworkListResponse.fromJson(data);
  }

  Future<TeacherHomeworkItem> createHomework(TeacherHomeworkItem item) async {
    final data = await _dio.postJson<Map<String, dynamic>>(
      '/teacher/homework',
      data: item.toJson(),
    );
    return TeacherHomeworkItem.fromJson(data);
  }

  Future<TeacherHomeworkItem> updateHomework(TeacherHomeworkItem item) async {
    final data = await _dio.putJson<Map<String, dynamic>>(
      '/teacher/homework/${item.id}',
      data: item.toJson(),
    );
    return TeacherHomeworkItem.fromJson(data);
  }

  Future<void> deleteHomework(String id) async {
    await _dio.deleteJson<Map<String, dynamic>>('/teacher/homework/$id');
  }
}
