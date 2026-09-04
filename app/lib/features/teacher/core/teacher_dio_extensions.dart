import 'package:dio/dio.dart';

import '../../../core/errors/api_exception.dart';

extension TeacherDioX on Dio {
  Future<T> putJson<T>(String path, {Object? data}) async {
    try {
      final response = await put<dynamic>(path, data: data);
      return response.data as T;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<T> deleteJson<T>(String path) async {
    try {
      final response = await delete<dynamic>(path);
      return response.data as T;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }
}

ApiException _mapError(DioException e) {
  final data = e.response?.data;
  if (data is Map && data['message'] is String) {
    return ApiException(data['message'] as String, statusCode: e.response?.statusCode);
  }
  return ApiException(
    e.message ?? 'Network error',
    statusCode: e.response?.statusCode,
  );
}
