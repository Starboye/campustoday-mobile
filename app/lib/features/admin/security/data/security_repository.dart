import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../core/admin_api.dart';

final securityRepositoryProvider = Provider<SecurityRepository>((ref) {
  return SecurityRepository(ref.watch(dioProvider));
});

class SecurityRepository {
  SecurityRepository(this._dio);

  final Dio _dio;

  Future<List<LoginAuditEntry>> loginAudit({String? userId, String? status}) async {
    final data = await _dio.adminGet<dynamic>(
      '/admin/security/login-audit',
      queryParameters: {
        if (userId != null && userId.isNotEmpty) 'user_id': userId,
        if (status != null && status.isNotEmpty) 'status': status,
      },
    );
    return parseListData(data, key: 'items').map(LoginAuditEntry.fromJson).toList();
  }

  Future<UserSecurityState> updateUserSecurity(
    String userId, {
    DateTime? lockedUntil,
    bool? forcePasswordReset,
    bool clearLock = false,
  }) async {
    final body = <String, dynamic>{};
    if (clearLock) {
      body['locked_until'] = null;
    } else if (lockedUntil != null) {
      body['locked_until'] = lockedUntil.toIso8601String();
    }
    if (forcePasswordReset != null) {
      body['force_password_reset'] = forcePasswordReset;
    }
    final data = await _dio.adminPut<dynamic>('/admin/security/users/$userId', data: body);
    return UserSecurityState.fromJson(parseItemData(data));
  }
}

class LoginAuditEntry {
  const LoginAuditEntry({
    required this.id,
    required this.userId,
    required this.username,
    required this.status,
    required this.ipAddress,
    required this.userAgent,
    required this.createdAt,
  });

  final String? id;
  final String userId;
  final String? username;
  final String status;
  final String? ipAddress;
  final String? userAgent;
  final String? createdAt;

  factory LoginAuditEntry.fromJson(Map<String, dynamic> json) {
    return LoginAuditEntry(
      id: json['id']?.toString(),
      userId: json['user_id']?.toString() ?? '',
      username: json['username']?.toString(),
      status: json['status']?.toString() ?? '',
      ipAddress: json['ip_address']?.toString(),
      userAgent: json['user_agent']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }
}

class UserSecurityState {
  const UserSecurityState({
    required this.userId,
    this.lockedUntil,
    this.forcePasswordReset = false,
  });

  final String userId;
  final DateTime? lockedUntil;
  final bool forcePasswordReset;

  factory UserSecurityState.fromJson(Map<String, dynamic> json) {
    final locked = json['locked_until']?.toString();
    return UserSecurityState(
      userId: json['user_id']?.toString() ?? '',
      lockedUntil: locked != null && locked.isNotEmpty ? DateTime.tryParse(locked) : null,
      forcePasswordReset: json['force_password_reset'] == true ||
          json['force_password_reset'] == 1,
    );
  }
}
