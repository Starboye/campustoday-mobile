import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../models/fee_term.dart';

final feesRepositoryProvider = Provider<FeesRepository>((ref) {
  return FeesRepository(ref.watch(dioProvider));
});

class FeesRepository {
  FeesRepository(this._dio);

  final Dio _dio;

  Future<FeesResponse> fetchFees() async {
    final data = await _dio.getJson<Map<String, dynamic>>('/student/fees');
    return FeesResponse.fromJson(data);
  }
}
