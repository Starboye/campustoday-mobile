import '../../auth/models/auth_user.dart';

/// Mirrors web `require_permission`: empty permissions = full access.
bool can(AuthUser? user, String key) {
  if (user == null) return false;
  final permissions = user.permissions;
  if (permissions.isEmpty) return true;
  return permissions.contains(key);
}
