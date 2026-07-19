import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Minimal key/value contract so callers (and tests) do not depend on the
/// platform keystore directly.
abstract class SecureStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

/// Keystore / Keychain implementation.
///
/// FR-A-04 — access and refresh tokens live here, never in
/// `SharedPreferences`, which is trivially readable on a rooted device.
/// FR-S-13 will add the entitlement cache here for the same reason.
class SecureStorageService implements SecureStore {
  SecureStorageService._();
  static final instance = SecureStorageService._();

  // Android: v10+ encrypts by default and migrates existing data on first
  // access, so no aOptions are needed. iOS: first_unlock rather than the
  // default, so a token can be refreshed while the phone is locked.
  static const _storage = FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  @override
  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (_) {
      // A corrupted keystore entry (common after a restore-from-backup on
      // Android) must not crash startup — treat it as "no value".
      return null;
    }
  }

  @override
  Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (_) {
      // Ignored deliberately: failing to persist a token degrades the session
      // to single-use, which is far better than crashing the app.
    }
  }

  @override
  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (_) {}
  }
}

abstract class SecureKeys {
  static const accessToken = 'auth_access_token';
  static const refreshToken = 'auth_refresh_token';
  static const entitlementCache = 'entitlement_cache'; // reserved for M-3

  static const all = [accessToken, refreshToken, entitlementCache];
}
