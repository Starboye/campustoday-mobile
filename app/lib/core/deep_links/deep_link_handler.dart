import 'package:flutter/foundation.dart';

/// Parses incoming deep links into in-app routes.
///
/// Production: integrate `uni_links` / `app_links` and map URIs such as
/// `campustoday://student/homework` to GoRouter paths. Firebase Dynamic Links
/// are optional; this stub only defines the contract.
class DeepLinkHandler {
  const DeepLinkHandler();

  /// Stub — returns a GoRouter location or `null` when unknown.
  String? routeForUri(Uri uri) {
    if (uri.scheme != 'campustoday') {
      debugPrint('DeepLinkHandler: unsupported scheme ${uri.scheme}');
      return null;
    }

    final path = uri.path.isEmpty ? uri.host : uri.path;
    switch (path) {
      case '/login':
      case 'login':
        return '/login';
      case '/student/homework':
      case 'student/homework':
        return '/student/homework';
      default:
        debugPrint('DeepLinkHandler: unhandled path $path');
        return null;
    }
  }
}
