import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/rbac_repository.dart';

final rolesListProvider = FutureProvider.autoDispose<List<AdminRole>>((ref) {
  return ref.watch(rbacRepositoryProvider).listRoles();
});

final userRolesProvider = FutureProvider.autoDispose.family<UserRoles, String>((ref, userId) {
  return ref.watch(rbacRepositoryProvider).getUserRoles(userId);
});
