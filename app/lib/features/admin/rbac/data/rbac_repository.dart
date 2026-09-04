import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../core/admin_api.dart';

final rbacRepositoryProvider = Provider<RbacRepository>((ref) {
  return RbacRepository(ref.watch(dioProvider));
});

class RbacRepository {
  RbacRepository(this._dio);

  final Dio _dio;

  Future<List<AdminRole>> listRoles() async {
    final data = await _dio.adminGet<dynamic>('/admin/rbac/roles');
    return parseListData(data, key: 'items').map(AdminRole.fromJson).toList();
  }

  Future<UserRoles> getUserRoles(String userId) async {
    final data = await _dio.adminGet<dynamic>('/admin/rbac/users/$userId');
    return UserRoles.fromJson(parseItemData(data));
  }

  Future<UserRoles> updateUserRoles(String userId, List<int> roleIds) async {
    final data = await _dio.adminPut<dynamic>(
      '/admin/rbac/users/$userId',
      data: {'role_ids': roleIds},
    );
    return UserRoles.fromJson(parseItemData(data));
  }
}

class AdminRole {
  const AdminRole({
    required this.id,
    required this.name,
    required this.permissions,
  });

  final int id;
  final String name;
  final List<String> permissions;

  factory AdminRole.fromJson(Map<String, dynamic> json) {
    final perms = json['permissions'];
    return AdminRole(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      permissions: perms is List ? perms.map((e) => e.toString()).toList() : [],
    );
  }
}

class UserRoles {
  const UserRoles({
    required this.userId,
    required this.roleIds,
  });

  final String userId;
  final List<int> roleIds;

  factory UserRoles.fromJson(Map<String, dynamic> json) {
    final ids = json['role_ids'];
    return UserRoles(
      userId: json['user_id']?.toString() ?? '',
      roleIds: ids is List ? ids.map((e) => (e as num).toInt()).toList() : [],
    );
  }
}
