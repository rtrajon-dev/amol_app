import '../../../app/network/api_client.dart';

/// Thin transport layer: endpoint paths and payload shapes, nothing else.
///
/// Keeping the paths in one class means the `/appbackend/v1` surface is
/// described in exactly one place on the client.
class AuthApi {
  AuthApi(this._client);

  final ApiClient _client;

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    String? displayName,
  }) =>
      _client.post('/auth/register', body: {
        'email': email,
        'password': password,
        if (displayName != null && displayName.isNotEmpty)
          'displayName': displayName,
      });

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) =>
      _client.post('/auth/login', body: {'email': email, 'password': password});

  Future<Map<String, dynamic>> logout({String? refreshToken}) =>
      _client.post('/auth/logout', body: {'refreshToken': ?refreshToken});

  Future<Map<String, dynamic>> forgotPassword(String email) =>
      _client.post('/auth/forgot-password', body: {'email': email});

  Future<Map<String, dynamic>> me() => _client.get('/auth/me');

  Future<Map<String, dynamic>> deleteAccount(String password) =>
      _client.post('/auth/delete-account', body: {'password': password});
}
