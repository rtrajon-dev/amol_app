/// Build-time configuration.
///
/// The base URL is the ONLY place the client knows where the server lives
/// (C-BE-03). Everything else speaks to `ApiClient`.
abstract class AppConfig {
  /// SRS-Backend FR-BE-01 — the `v1` segment is pinned at build time. A
  /// released APK keeps talking to `/appbackend/v1` even after `/v2` exists.
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://amol.patawise.com/appbackend/v1',
  );

  /// FR-BE-11 — the server times out at 20 s, so the client must wait longer;
  /// otherwise the client gives up first and reports a generic timeout instead
  /// of the server's typed, Bangla error.
  static const connectTimeout = Duration(seconds: 15);
  static const receiveTimeout = Duration(seconds: 30);

  /// Requests that must never be retried or refreshed against.
  static const authFreePaths = <String>{
    '/auth/login',
    '/auth/register',
    '/auth/refresh',
    '/auth/forgot-password',
    '/auth/reset-password',
  };
}
