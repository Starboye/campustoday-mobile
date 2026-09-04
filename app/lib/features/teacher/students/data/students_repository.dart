import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../models/student_models.dart';

final studentsRepositoryProvider = Provider<StudentsRepository>((ref) {
  return StudentsRepository(ref.watch(dioProvider));
});

class StudentsRepository {
  StudentsRepository(this._dio);

  final Dio _dio;

  Future<List<StudentSummary>> fetchStudents({
    int? standard,
    String? section,
  }) async {
    final data = await _dio.getJson<Map<String, dynamic>>(
      '/teacher/students',
      queryParameters: {
        if (standard != null) 'class': standard,
        if (section != null) 'section': section,
      },
    );
    return (data['items'] as List<dynamic>)
        .map((e) => StudentSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<StudentDossier> fetchStudent(String id) async {
    final data = await _dio.getJson<Map<String, dynamic>>('/teacher/students/$id');
    return StudentDossier.fromJson(data);
  }
}
