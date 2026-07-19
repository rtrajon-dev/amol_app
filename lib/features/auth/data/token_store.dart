import '../../../app/services/secure_storage_service.dart';

/// Holds the token pair, in secure storage and in memory.
///
/// The in-memory copy exists so the request interceptor does not hit the
/// platform keystore on every single call — that is a channel round-trip and
/// it shows up on low-end devices.
class TokenStore {
  TokenStore(this._storage);

  final SecureStore _storage;

  String? _accessToken;
  String? _refreshToken;
  bool _loaded = false;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    _accessToken = await _storage.read(SecureKeys.accessToken);
    _refreshToken = await _storage.read(SecureKeys.refreshToken);
    _loaded = true;
  }

  Future<String?> accessToken() async {
    await _ensureLoaded();
    return _accessToken;
  }

  Future<String?> refreshToken() async {
    await _ensureLoaded();
    return _refreshToken;
  }

  /// True when a session exists locally — the basis of offline entry to Home
  /// (FR-A-06). Deliberately does not validate the token: validation needs the
  /// network, and needing the network is exactly what we are avoiding.
  Future<bool> hasSession() async {
    await _ensureLoaded();
    return (_refreshToken ?? '').isNotEmpty;
  }

  Future<void> save({required String accessToken, required String refreshToken}) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _loaded = true;
    await _storage.write(SecureKeys.accessToken, accessToken);
    await _storage.write(SecureKeys.refreshToken, refreshToken);
  }

  Future<void> saveAccessToken(String accessToken) async {
    _accessToken = accessToken;
    await _storage.write(SecureKeys.accessToken, accessToken);
  }

  Future<void> clear() async {
    _accessToken = null;
    _refreshToken = null;
    _loaded = true;
    await _storage.delete(SecureKeys.accessToken);
    await _storage.delete(SecureKeys.refreshToken);
  }
}
