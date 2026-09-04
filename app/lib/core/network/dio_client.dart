import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';
import '../errors/api_exception.dart';
import '../storage/token_storage.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final dioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await storage.readAccessToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401 &&
            error.requestOptions.extra['retried'] != true) {
          final refresh = await storage.readRefreshToken();
          if (refresh != null && refresh.isNotEmpty) {
            try {
              final refreshDio = Dio(BaseOptions(baseUrl: AppConstants.apiBaseUrl));
              final response = await refreshDio.post<Map<String, dynamic>>(
                '/auth/refresh',
                data: {'refresh_token': refresh},
              );
              final data = response.data!;
              await storage.saveTokens(
                accessToken: data['access_token'] as String,
                refreshToken: data['refresh_token'] as String,
              );
              final opts = error.requestOptions;
              opts.extra['retried'] = true;
              opts.headers['Authorization'] = 'Bearer ${data['access_token']}';
              final clone = await dio.fetch(opts);
              return handler.resolve(clone);
            } catch (_) {
              await storage.clear();
            }
          }
        }
        handler.next(error);
      },
    ),
  );

  return dio;
});

extension DioResponseX on Dio {
  Future<T> getJson<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await get<dynamic>(path, queryParameters: queryParameters);
      return response.data as T;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<T> postJson<T>(String path, {Object? data}) async {
    try {
      final response = await post<dynamic>(path, data: data);
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
