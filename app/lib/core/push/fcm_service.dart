import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Registers the device FCM token with `PUT /me/device`.
///
/// Production requires Firebase project configuration (`google-services.json`,
/// `GoogleService-Info.plist`, and initialized `FirebaseMessaging`). This stub
/// only documents the API contract until Firebase is wired up.
class FcmService {
  FcmService({required Dio dio}) : _dio = dio;

  final Dio _dio;

  /// Stub: call after Firebase yields a token. Pass `null` to clear registration.
  Future<void> registerDevice({
    required String platform,
    String? fcmToken,
  }) async {
    assert(platform == 'ios' || platform == 'android');
    try {
      await _dio.put<dynamic>(
        '/me/device',
        data: {
          'platform': platform,
          'fcm_token': fcmToken,
        },
      );
    } catch (e, st) {
      debugPrint('FcmService.registerDevice failed: $e\n$st');
    }
  }

  /// Stub entry point — no-op until Firebase Messaging is configured.
  Future<void> initialize() async {
    debugPrint(
      'FcmService.initialize stub: configure Firebase Messaging for production.',
    );
  }
}

/// Riverpod-friendly factory using the shared authenticated [Dio] client.
FcmService createFcmService(Dio dio) => FcmService(dio: dio);
