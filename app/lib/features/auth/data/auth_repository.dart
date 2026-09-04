import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/storage/token_storage.dart';
import '../models/auth_user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    dio: ref.watch(dioProvider),
    storage: ref.watch(tokenStorageProvider),
  );
});

class AuthRepository {
  AuthRepository({required Dio dio, required TokenStorage storage})
      : _dio = dio,
        _storage = storage;

  final Dio _dio;
  final TokenStorage _storage;

  Future<AuthUser> login({
    required String username,
    required String password,
    required int access,
  }) async {
    final data = await _dio.postJson<Map<String, dynamic>>(
      '/auth/login',
      data: {
        'username': username,
        'password': password,
        'access': access,
      },
    );
    final response = LoginResponse.fromJson(data);
    await _storage.saveTokens(
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
    );
    return response.user;
  }

  Future<AuthUser?> restoreSession() async {
    final token = await _storage.readAccessToken();
    if (token == null || token.isEmpty) return null;

    try {
      final data = await _dio.getJson<Map<String, dynamic>>('/me');
      return AuthUser(
        id: data['id'] as String,
        name: data['name'] as String,
        access: data['access'] as int,
        permissions: (data['permissions'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
      );
    } catch (_) {
      await _storage.clear();
      return null;
    }
  }

  Future<void> logout() async {
    final refresh = await _storage.readRefreshToken();
    if (refresh != null) {
      try {
        await _dio.postJson('/auth/logout', data: {'refresh_token': refresh});
      } catch (_) {}
    }
    await _storage.clear();
  }
}
