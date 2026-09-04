import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/offline/student_read_cache.dart';
import '../models/homework_item.dart';

final homeworkRepositoryProvider = Provider<HomeworkRepository>((ref) {
  return HomeworkRepository(ref.watch(dioProvider));
});

class HomeworkRepository {
  HomeworkRepository(this._dio);

  final Dio _dio;
  final _cache = StudentReadCache.instance;

  Future<HomeworkListResponse> fetchHomework({required String date}) async {
    final cacheKey = 'homework:$date';
    final cached = _cache.getJson(cacheKey);
    if (cached != null) {
      return HomeworkListResponse.fromJson(cached);
    }

    final data = await _dio.getJson<Map<String, dynamic>>(
      '/student/homework',
      queryParameters: {'date': date},
    );
    _cache.put(cacheKey, data);
    return HomeworkListResponse.fromJson(data);
  }
}
