import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../models/timetable_data.dart';

final timetableRepositoryProvider = Provider<TimetableRepository>((ref) {
  return TimetableRepository(ref.watch(dioProvider));
});

class TimetableRepository {
  TimetableRepository(this._dio);

  final Dio _dio;

  Future<TimetableResponse> fetchTimetable() async {
    final data = await _dio.getJson<Map<String, dynamic>>('/student/timetable');
    return TimetableResponse.fromJson(data);
  }
}
