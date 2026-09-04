import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../models/homework_item.dart';

final homeworkRepositoryProvider = Provider<HomeworkRepository>((ref) {
  return HomeworkRepository(ref.watch(dioProvider));
});

class HomeworkRepository {
  HomeworkRepository(this._dio);

  final Dio _dio;

  Future<HomeworkListResponse> fetchHomework({required String date}) async {
    final data = await _dio.getJson<Map<String, dynamic>>(
      '/student/homework',
      queryParameters: {'date': date},
    );
    return HomeworkListResponse.fromJson(data);
  }
}
