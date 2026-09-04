class AppConstants {
  static const appName = 'CampusToday';

  /// Override with --dart-define=API_BASE_URL=http://host/api/v1
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8080/v1',
  );

  static const primaryColor = 0xFF4154F1;
  static const navyColor = 0xFF012970;
}

typedef UserId = String;
