import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/offline/student_read_cache.dart';
import '../models/timetable_data.dart';

final timetableRepositoryProvider = Provider<TimetableRepository>((ref) {
  return TimetableRepository(ref.watch(dioProvider));
});

class TimetableRepository {
  TimetableRepository(this._dio);

  final Dio _dio;
  final _cache = StudentReadCache.instance;

  Future<TimetableResponse> fetchTimetable() async {
    const cacheKey = 'timetable';
    final cached = _cache.getJson(cacheKey);
    if (cached != null) {
      return TimetableResponse.fromJson(cached);
    }

    final data = await _dio.getJson<Map<String, dynamic>>('/student/timetable');
    _cache.put(cacheKey, data);
    return TimetableResponse.fromJson(data);
  }
}
