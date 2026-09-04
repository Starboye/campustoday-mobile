import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../models/exam_timetable_models.dart';

final examTimetableRepositoryProvider = Provider<ExamTimetableRepository>((ref) {
  return ExamTimetableRepository(ref.watch(dioProvider));
});

class ExamTimetableRepository {
  ExamTimetableRepository(this._dio);

  final Dio _dio;

  Future<List<ExamTimetableSlot>> fetchExamTimetable() async {
    final data = await _dio.getJson<Map<String, dynamic>>('/teacher/exam-timetable');
    return (data['items'] as List<dynamic>)
        .map((e) => ExamTimetableSlot.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
