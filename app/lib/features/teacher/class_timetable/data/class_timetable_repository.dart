import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../core/teacher_dio_extensions.dart';
import '../models/class_timetable_models.dart';

final classTimetableRepositoryProvider = Provider<ClassTimetableRepository>((ref) {
  return ClassTimetableRepository(ref.watch(dioProvider));
});

class ClassTimetableRepository {
  ClassTimetableRepository(this._dio);

  final Dio _dio;

  Future<ClassTimetableResponse> fetchTimetable() async {
    final data = await _dio.getJson<Map<String, dynamic>>('/teacher/class-timetable');
    return ClassTimetableResponse.fromJson(data);
  }

  Future<ClassTimetableResponse> updateTimetable(List<ClassTimetableItem> items) async {
    final data = await _dio.putJson<Map<String, dynamic>>(
      '/teacher/class-timetable',
      data: {
        'items': items.map((e) => e.toUpdateJson()).toList(),
      },
    );
    return ClassTimetableResponse.fromJson(data);
  }

  Future<ClassTimetableResponse> submitTimetable() async {
    final data = await _dio.postJson<Map<String, dynamic>>('/teacher/class-timetable/submit');
    return ClassTimetableResponse.fromJson(data);
  }
}
