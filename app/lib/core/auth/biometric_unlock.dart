import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

/// Optional biometric gate before restoring a stored session.
///
/// Production: ensure `NSFaceIDUsageDescription` (iOS) and
/// `USE_BIOMETRIC`/`USE_FINGERPRINT` (Android) are set. Firebase is not
/// required for biometrics, but app signing and store policies must allow
/// `local_auth` on target devices.
class BiometricUnlock {
  BiometricUnlock({LocalAuthentication? auth})
      : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  Future<bool> isSupported() async {
    try {
      return await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
    } catch (e) {
      debugPrint('BiometricUnlock.isSupported failed: $e');
      return false;
    }
  }

  /// Returns `true` when the user passed biometric auth, `false` when cancelled
  /// or unavailable. Stub-friendly: failures are treated as "not unlocked".
  Future<bool> unlock({String reason = 'Unlock CampusToday'}) async {
    try {
      if (!await isSupported()) return false;
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      debugPrint('BiometricUnlock.unlock failed: $e');
      return false;
    }
  }
}
