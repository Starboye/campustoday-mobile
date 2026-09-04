import 'package:dio/dio.dart';

import '../../../core/errors/api_exception.dart';

extension AdminDioX on Dio {
  Future<T> adminGet<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await get<dynamic>(path, queryParameters: queryParameters);
      return response.data as T;
    } on DioException catch (e) {
      throw _mapAdminError(e);
    }
  }

  Future<T> adminPost<T>(String path, {Object? data}) async {
    try {
      final response = await post<dynamic>(path, data: data);
      return response.data as T;
    } on DioException catch (e) {
      throw _mapAdminError(e);
    }
  }

  Future<T> adminPut<T>(String path, {Object? data}) async {
    try {
      final response = await put<dynamic>(path, data: data);
      return response.data as T;
    } on DioException catch (e) {
      throw _mapAdminError(e);
    }
  }

  Future<void> adminDelete(String path) async {
    try {
      await delete<dynamic>(path);
    } on DioException catch (e) {
      throw _mapAdminError(e);
    }
  }
}

ApiException _mapAdminError(DioException e) {
  final data = e.response?.data;
  if (data is Map && data['message'] is String) {
    return ApiException(data['message'] as String, statusCode: e.response?.statusCode);
  }
  return ApiException(
    e.message ?? 'Network error',
    statusCode: e.response?.statusCode,
  );
}

List<Map<String, dynamic>> parseListData(dynamic data, {String key = 'data'}) {
  if (data is List) {
    return data.cast<Map<String, dynamic>>();
  }
  if (data is Map && data[key] is List) {
    return (data[key] as List).cast<Map<String, dynamic>>();
  }
  return [];
}

Map<String, dynamic> parseItemData(dynamic data, {String key = 'data'}) {
  if (data is Map<String, dynamic>) {
    if (data.containsKey(key) && data[key] is Map) {
      return data[key] as Map<String, dynamic>;
    }
    return data;
  }
  return {};
}
