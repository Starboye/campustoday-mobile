import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../core/teacher_dio_extensions.dart';
import '../models/marks_models.dart';

final teacherMarksRepositoryProvider = Provider<TeacherMarksRepository>((ref) {
  return TeacherMarksRepository(ref.watch(dioProvider));
});

class TeacherMarksRepository {
  TeacherMarksRepository(this._dio);

  final Dio _dio;

  Future<TeacherMarksListResponse> fetchMarks({
    int? standard,
    String? section,
    String? subjectName,
    int? term,
  }) async {
    final data = await _dio.getJson<Map<String, dynamic>>(
      '/teacher/marks',
      queryParameters: {
        if (standard != null) 'class': standard,
        if (section != null) 'section': section,
        if (subjectName != null) 'subject_name': subjectName,
        if (term != null) 'term': term,
      },
    );
    return TeacherMarksListResponse.fromJson(data);
  }

  Future<void> saveMark(TeacherMarkUpdate update) async {
    await _dio.putJson<Map<String, dynamic>>(
      '/teacher/marks',
      data: update.toJson(),
    );
  }
}
