import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/offline/student_read_cache.dart';
import '../models/fee_term.dart';

final feesRepositoryProvider = Provider<FeesRepository>((ref) {
  return FeesRepository(ref.watch(dioProvider));
});

class FeesRepository {
  FeesRepository(this._dio);

  final Dio _dio;
  final _cache = StudentReadCache.instance;

  Future<FeesResponse> fetchFees() async {
    const cacheKey = 'fees';
    final cached = _cache.getJson(cacheKey);
    if (cached != null) {
      return FeesResponse.fromJson(cached);
    }

    final data = await _dio.getJson<Map<String, dynamic>>('/student/fees');
    _cache.put(cacheKey, data);
    return FeesResponse.fromJson(data);
  }
}
