class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.access,
    required this.permissions,
    this.forcePasswordReset = false,
  });

  final String id;
  final String name;
  final int access;
  final List<String> permissions;
  final bool forcePasswordReset;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String,
      name: json['name'] as String,
      access: json['access'] as int,
      permissions: (json['permissions'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      forcePasswordReset: json['force_password_reset'] as bool? ?? false,
    );
  }

  bool get isStudent => access == 0;
  bool get isTeacher => access == 1;
  bool get isAdmin => access == 2;
}

class LoginResponse {
  const LoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final AuthUser user;

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      expiresIn: json['expires_in'] as int,
      user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
