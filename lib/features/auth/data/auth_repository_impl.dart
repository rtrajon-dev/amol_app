import '../../../app/network/api_exception.dart';
import '../domain/app_user.dart';
import '../domain/auth_repository.dart';
import 'auth_api.dart';
import 'token_store.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required AuthApi api, required TokenStore tokenStore})
      : _api = api,
        _tokenStore = tokenStore;

  final AuthApi _api;
  final TokenStore _tokenStore;

  @override
  Future<AppUser> register({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final data = await _api.register(
      email: email.trim(),
      password: password,
      displayName: displayName?.trim(),
    );
    return _persistSession(data);
  }

  @override
  Future<AppUser> login({required String email, required String password}) async {
    final data = await _api.login(email: email.trim(), password: password);
    return _persistSession(data);
  }

  @override
  Future<void> logout() async {
    final refreshToken = await _tokenStore.refreshToken();
    try {
      await _api.logout(refreshToken: refreshToken);
    } on ApiException {
      // The server call is best-effort. If it fails — offline, expired token —
      // the local session is still cleared below. A logout that leaves the user
      // logged in because the network was down would be worse than useless.
    }
    await _tokenStore.clear();
  }

  @override
  Future<void> forgotPassword(String email) async {
    await _api.forgotPassword(email.trim());
  }

  @override
  Future<AppUser> me() async {
    final data = await _api.me();
    final user = data['user'];
    if (user is! Map) throw const ApiException.unexpected();
    return AppUser.fromJson(Map<String, dynamic>.from(user));
  }

  @override
  Future<bool> hasLocalSession() => _tokenStore.hasSession();

  @override
  Future<void> deleteAccount(String password) async {
    await _api.deleteAccount(password);
    await _tokenStore.clear();
  }

  /// Store the token pair, then return the user. Tokens are saved BEFORE the
  /// user is returned so that any request triggered by the resulting UI already
  /// has a credential to send.
  Future<AppUser> _persistSession(Map<String, dynamic> data) async {
    final accessToken = data['accessToken'] as String?;
    final refreshToken = data['refreshToken'] as String?;
    final user = data['user'];

    if (accessToken == null || refreshToken == null || user is! Map) {
      throw const ApiException.unexpected();
    }

    await _tokenStore.save(accessToken: accessToken, refreshToken: refreshToken);
    return AppUser.fromJson(Map<String, dynamic>.from(user));
  }
}
