import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:amol365/app/network/api_client.dart';
import 'package:amol365/app/network/api_exception.dart';
import 'package:amol365/app/services/secure_storage_service.dart';
import 'package:amol365/features/auth/data/token_store.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory SecureStore — no platform channels.
class FakeSecureStore implements SecureStore {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}

/// Scripted HTTP adapter. Each entry is a function producing the response for
/// the next call to that path, so we can make the first call 401 and the
/// retry succeed.
class ScriptedAdapter implements HttpClientAdapter {
  ScriptedAdapter(this.handlers);

  final Map<String, List<Map<String, dynamic>>> handlers;
  final List<String> calls = [];

  /// Artificial latency, so concurrent requests genuinely overlap.
  Duration delay = Duration.zero;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls.add(options.path);
    if (delay > Duration.zero) await Future<void>.delayed(delay);

    final queue = handlers[options.path];
    if (queue == null || queue.isEmpty) {
      return ResponseBody.fromString(
        jsonEncode({'ok': false, 'error': {'code': 'NOT_FOUND', 'message': 'নেই'}}),
        404,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
      );
    }

    final spec = queue.length == 1 ? queue.first : queue.removeAt(0);

    if (spec['throw'] == true) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
        error: 'simulated offline',
      );
    }

    return ResponseBody.fromString(
      jsonEncode(spec['body']),
      spec['status'] as int? ?? 200,
      headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
    );
  }

  @override
  void close({bool force = false}) {}
}

Map<String, dynamic> okBody(Map<String, dynamic> data) => {'ok': true, 'data': data};

Map<String, dynamic> errBody(String code, String message) => {
      'ok': false,
      'error': {'code': code, 'message': message},
    };

void main() {
  late FakeSecureStore store;
  late TokenStore tokens;

  ApiClient build(ScriptedAdapter adapter) {
    final dio = Dio();
    dio.httpClientAdapter = adapter;
    return ApiClient(
      tokenStore: tokens,
      deviceId: 'test-device',
      appVersion: '1.0.0',
      dio: dio,
    );
  }

  setUp(() async {
    store = FakeSecureStore();
    tokens = TokenStore(store);
    await tokens.save(accessToken: 'access-1', refreshToken: 'refresh-1');
  });

  group('envelope', () {
    test('unwraps ok:true into data', () async {
      final client = build(ScriptedAdapter({
        '/auth/me': [
          {'body': okBody({'user': {'id': 7}})}
        ],
      }));

      final data = await client.get('/auth/me');
      expect(data['user'], {'id': 7});
    });

    test('throws ApiException carrying the server Bangla message', () async {
      final client = build(ScriptedAdapter({
        '/auth/login': [
          {'status': 401, 'body': errBody('INVALID_CREDENTIALS', 'ইমেইল বা পাসওয়ার্ড সঠিক নয়।')}
        ],
      }));

      await expectLater(
        client.post('/auth/login'),
        throwsA(isA<ApiException>()
            .having((e) => e.code, 'code', 'INVALID_CREDENTIALS')
            .having((e) => e.message, 'message', 'ইমেইল বা পাসওয়ার্ড সঠিক নয়।')),
      );
    });

    test('non-JSON body never leaks to the user', () async {
      final adapter = ScriptedAdapter({});
      final dio = Dio()
        ..httpClientAdapter = _HtmlAdapter()
        ..options = BaseOptions(validateStatus: (_) => true);
      final client = ApiClient(
        tokenStore: tokens,
        deviceId: 'd',
        appVersion: '1',
        dio: dio,
      );
      expect(adapter.calls, isEmpty);

      await expectLater(
        client.get('/auth/me'),
        throwsA(isA<ApiException>()
            .having((e) => e.code, 'code', ApiException.codeUnexpected)),
      );
    });
  });

  group('token refresh (FR-A-05)', () {
    test('refreshes on TOKEN_EXPIRED and retries the original request once', () async {
      final adapter = ScriptedAdapter({
        '/auth/me': [
          {'status': 401, 'body': errBody('TOKEN_EXPIRED', 'মেয়াদ শেষ')},
          {'body': okBody({'user': {'id': 7}})},
        ],
        '/auth/refresh': [
          {'body': okBody({'accessToken': 'access-2', 'refreshToken': 'refresh-2'})}
        ],
      });
      final client = build(adapter);

      final data = await client.get('/auth/me');

      expect(data['user'], {'id': 7});
      expect(adapter.calls, ['/auth/me', '/auth/refresh', '/auth/me']);
      expect(await tokens.accessToken(), 'access-2');
      expect(await tokens.refreshToken(), 'refresh-2', reason: 'rotation persisted');
    });

    test('concurrent 401s trigger exactly ONE refresh (NFR-A-03)', () async {
      final adapter = ScriptedAdapter({
        '/auth/me': [
          {'status': 401, 'body': errBody('TOKEN_EXPIRED', 'মেয়াদ শেষ')},
          {'status': 401, 'body': errBody('TOKEN_EXPIRED', 'মেয়াদ শেষ')},
          {'status': 401, 'body': errBody('TOKEN_EXPIRED', 'মেয়াদ শেষ')},
          {'body': okBody({'user': {'id': 7}})},
        ],
        '/auth/refresh': [
          {'body': okBody({'accessToken': 'access-2', 'refreshToken': 'refresh-2'})}
        ],
      })..delay = const Duration(milliseconds: 20);
      final client = build(adapter);

      await Future.wait([
        client.get('/auth/me'),
        client.get('/auth/me'),
        client.get('/auth/me'),
      ]);

      final refreshCalls = adapter.calls.where((c) => c == '/auth/refresh').length;
      expect(refreshCalls, 1,
          reason: 'a second refresh would present a rotated token and burn the chain');
    });

    test('failed refresh ends the session exactly once', () async {
      var sessionEndedCount = 0;
      final client = build(ScriptedAdapter({
        '/auth/me': [
          {'status': 401, 'body': errBody('TOKEN_EXPIRED', 'মেয়াদ শেষ')}
        ],
        '/auth/refresh': [
          {'status': 401, 'body': errBody('TOKEN_REVOKED', 'বাতিল')}
        ],
      }))
        ..onSessionEnded = () => sessionEndedCount++;

      await expectLater(client.get('/auth/me'), throwsA(isA<ApiException>()));
      expect(sessionEndedCount, 1);
    });

    test('TOKEN_REVOKED ends the session', () async {
      var ended = false;
      final client = build(ScriptedAdapter({
        '/auth/me': [
          {'status': 401, 'body': errBody('TOKEN_REVOKED', 'বাতিল')}
        ],
      }))
        ..onSessionEnded = () => ended = true;

      await expectLater(client.get('/auth/me'), throwsA(isA<ApiException>()));
      expect(ended, isTrue);
    });
  });

  group('offline tolerance (FR-A-06)', () {
    test('network failure surfaces as NO_NETWORK and does NOT end the session', () async {
      var ended = false;
      final client = build(ScriptedAdapter({
        '/auth/me': [
          {'throw': true}
        ],
      }))
        ..onSessionEnded = () => ended = true;

      await expectLater(
        client.get('/auth/me'),
        throwsA(isA<ApiException>()
            .having((e) => e.code, 'code', ApiException.codeNoNetwork)
            .having((e) => e.isNetworkFailure, 'isNetworkFailure', isTrue)),
      );

      expect(ended, isFalse,
          reason: 'being offline must never log a user out of an offline-first app');
      expect(await tokens.hasSession(), isTrue, reason: 'tokens survive');
    });
  });

  group('headers (FR-BE-08)', () {
    test('sends X-Device-Id, X-App-Version, X-Platform and Bearer', () async {
      final capture = _HeaderCaptureAdapter();
      final dio = Dio()..httpClientAdapter = capture;
      final client = ApiClient(
        tokenStore: tokens,
        deviceId: 'device-abc',
        appVersion: '2.3.4',
        dio: dio,
      );

      await client.get('/auth/me');

      expect(capture.headers['X-Device-Id'], 'device-abc');
      expect(capture.headers['X-App-Version'], '2.3.4');
      expect(capture.headers['X-Platform'], anyOf('android', 'ios'));
      expect(capture.headers['Authorization'], 'Bearer access-1');
    });

    test('does NOT attach Bearer to login (auth-free path)', () async {
      final capture = _HeaderCaptureAdapter();
      final dio = Dio()..httpClientAdapter = capture;
      final client = ApiClient(
        tokenStore: tokens,
        deviceId: 'd',
        appVersion: '1',
        dio: dio,
      );

      await client.post('/auth/login');

      expect(capture.headers.containsKey('Authorization'), isFalse);
    });
  });
}

class _HtmlAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<Uint8List>? s, Future<void>? c) async =>
      ResponseBody.fromString('<html><body>502 Bad Gateway</body></html>', 502);

  @override
  void close({bool force = false}) {}
}

class _HeaderCaptureAdapter implements HttpClientAdapter {
  Map<String, dynamic> headers = {};

  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<Uint8List>? s, Future<void>? c) async {
    headers = o.headers;
    return ResponseBody.fromString(
      jsonEncode(okBody({})),
      200,
      headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
    );
  }

  @override
  void close({bool force = false}) {}
}
