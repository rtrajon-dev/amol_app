import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../../features/auth/data/token_store.dart';
import 'api_exception.dart';

/// Signature the auth layer supplies so the client can end a session it has
/// discovered is dead, without importing the auth feature (keeps the
/// dependency pointing one way).
typedef OnSessionEnded = void Function();

/// The single HTTP entry point for the app.
///
/// Responsibilities:
///  - attach the identifying headers required by FR-BE-08
///  - attach the Bearer token
///  - unwrap the `{ok, data|error}` envelope into values or [ApiException]
///  - refresh transparently on 401 and retry once (FR-A-05)
///  - collapse concurrent 401s into ONE refresh (NFR-A-03)
class ApiClient {
  ApiClient({
    required TokenStore tokenStore,
    required String deviceId,
    required String appVersion,
    Dio? dio,
  })  : _tokenStore = tokenStore,
        _deviceId = deviceId,
        _appVersion = appVersion,
        _dio = dio ?? Dio() {
    _dio.options = _dio.options.copyWith(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      contentType: Headers.jsonContentType,
      // We inspect the envelope ourselves, so let every status through rather
      // than letting Dio throw before we can read `error.message`.
      validateStatus: (_) => true,
    );
    _dio.interceptors.add(_headerInterceptor());
  }

  final Dio _dio;
  final TokenStore _tokenStore;
  final String _deviceId;
  final String _appVersion;

  OnSessionEnded? onSessionEnded;

  /// The in-flight refresh, if any. Concurrent 401s await this same future
  /// instead of each firing their own refresh — otherwise the first refresh
  /// rotates the token and the rest present a now-revoked one, which the
  /// server treats as theft and burns the whole chain (FR-A-07).
  Future<bool>? _refreshInFlight;

  Interceptor _headerInterceptor() => InterceptorsWrapper(
        onRequest: (options, handler) async {
          options.headers['X-Device-Id'] = _deviceId;
          options.headers['X-App-Version'] = _appVersion;
          options.headers['X-Platform'] = Platform.isIOS ? 'ios' : 'android';

          if (!_isAuthFree(options.path)) {
            final token = await _tokenStore.accessToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          handler.next(options);
        },
      );

  bool _isAuthFree(String path) =>
      AppConfig.authFreePaths.any((p) => path.startsWith(p));

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? query}) =>
      _send(() => _dio.get(path, queryParameters: query), path);

  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? body}) =>
      _send(() => _dio.post(path, data: body), path);

  Future<Map<String, dynamic>> _send(
    Future<Response<dynamic>> Function() request,
    String path, {
    bool allowRefresh = true,
  }) async {
    late Response<dynamic> response;

    try {
      response = await request();
    } on DioException catch (e) {
      throw _fromDioException(e);
    } catch (_) {
      throw const ApiException.unexpected();
    }

    final body = response.data;
    if (body is! Map) {
      // A non-JSON body means something in front of the app answered — a host
      // error page, a captive portal. Never surface that markup to the user.
      throw const ApiException.unexpected();
    }

    final map = Map<String, dynamic>.from(body);

    if (map['ok'] == true) {
      final data = map['data'];
      return data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
    }

    final error = map['error'] is Map
        ? Map<String, dynamic>.from(map['error'] as Map)
        : const <String, dynamic>{};

    final failure = ApiException(
      code: (error['code'] ?? ApiException.codeUnexpected).toString(),
      message: (error['message'] ?? 'কিছু একটা সমস্যা হয়েছে।').toString(),
      statusCode: response.statusCode,
      retryAfterSeconds: error['retryAfterSeconds'] is int
          ? error['retryAfterSeconds'] as int
          : null,
    );

    // FR-A-05 — an expired access token is refreshed transparently and the
    // original request retried exactly once. The user sees no interruption.
    final shouldRefresh = allowRefresh &&
        failure.code == ApiException.codeTokenExpired &&
        !_isAuthFree(path);

    if (shouldRefresh) {
      final refreshed = await _refreshOnce();
      if (refreshed) {
        return _send(request, path, allowRefresh: false);
      }
      onSessionEnded?.call();
      throw const ApiException(
        code: ApiException.codeTokenRevoked,
        message: 'সেশনের মেয়াদ শেষ। আবার লগইন করুন।',
        statusCode: 401,
      );
    }

    if (failure.isSessionEnded) {
      onSessionEnded?.call();
    }

    throw failure;
  }

  /// Runs at most one refresh at a time; every caller awaits the same result.
  Future<bool> _refreshOnce() {
    return _refreshInFlight ??= _performRefresh().whenComplete(() {
      _refreshInFlight = null;
    });
  }

  Future<bool> _performRefresh() async {
    final refreshToken = await _tokenStore.refreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;

    try {
      final response = await _dio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      final body = response.data;
      if (body is! Map || body['ok'] != true) return false;

      final data = Map<String, dynamic>.from(body['data'] as Map);
      final newAccess = data['accessToken'] as String?;
      final newRefresh = data['refreshToken'] as String?;
      if (newAccess == null || newRefresh == null) return false;

      await _tokenStore.save(accessToken: newAccess, refreshToken: newRefresh);
      return true;
    } on DioException {
      // Network failure during refresh is NOT a revoked session (FR-A-06).
      // Rethrow as a network error so the caller does not log the user out.
      rethrow;
    } catch (_) {
      return false;
    }
  }

  ApiException _fromDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException.timeout();
      case DioExceptionType.connectionError:
        return const ApiException.noNetwork();
      case DioExceptionType.badCertificate:
        return const ApiException(
          code: 'BAD_CERTIFICATE',
          message: 'নিরাপদ সংযোগ যাচাই করা যায়নি।',
        );
      case DioExceptionType.cancel:
        return const ApiException.unexpected();
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        if (e.error is SocketException) return const ApiException.noNetwork();
        return const ApiException.unexpected();
    }
  }
}
