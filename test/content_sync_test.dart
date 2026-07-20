import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:amol365/app/network/api_client.dart';
import 'package:amol365/app/services/content_service.dart';
import 'package:amol365/app/services/content_sync_service.dart';
import 'package:amol365/app/services/secure_storage_service.dart';
import 'package:amol365/app/services/storage_service.dart';
import 'package:amol365/features/auth/data/token_store.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeSecureStore implements SecureStore {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}

class FakeConnectivity implements Connectivity {
  FakeConnectivity([this.result = const [ConnectivityResult.wifi]]);

  List<ConnectivityResult> result;

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => result;

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      Stream.value(result);
}

/// Serves the manifest envelope for `/content/manifest`.
class ManifestAdapter implements HttpClientAdapter {
  ManifestAdapter(this.body, {this.status = 200, this.fail = false});

  Map<String, dynamic> body;
  int status;
  bool fail;
  int calls = 0;

  @override
  Future<ResponseBody> fetch(RequestOptions options, _, _) async {
    calls++;
    if (fail) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    }
    return ResponseBody.fromString(
      jsonEncode({'ok': true, 'data': body}),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Serves raw file bytes keyed by URL path.
class FileAdapter implements HttpClientAdapter {
  FileAdapter(this.files);

  /// path → bytes. A missing path yields 404.
  final Map<String, List<int>> files;
  final List<String> requested = [];

  @override
  Future<ResponseBody> fetch(RequestOptions options, _, _) async {
    requested.add(options.uri.path);
    final bytes = files[options.uri.path];
    if (bytes == null) {
      return ResponseBody.fromBytes(Uint8List(0), 404);
    }
    return ResponseBody.fromBytes(Uint8List.fromList(bytes), 200);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late StorageService storage;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('content_sync_test');
    SharedPreferences.setMockInitialValues({});
    storage = StorageService.instance;
    await storage.init();
    ContentService.instance.invalidate();
  });

  tearDown(() async {
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  ApiClient buildApi(HttpClientAdapter adapter) {
    final dio = Dio();
    dio.httpClientAdapter = adapter;
    return ApiClient(
      tokenStore: TokenStore(FakeSecureStore()),
      deviceId: 'test-device',
      appVersion: '0.0.0-test',
      dio: dio,
    );
  }

  ContentSyncService buildService({
    required ManifestAdapter manifest,
    required FileAdapter fileAdapter,
    Connectivity? connectivity,
  }) {
    final downloadDio = Dio();
    downloadDio.httpClientAdapter = fileAdapter;

    return ContentSyncService(
      api: buildApi(manifest),
      storage: storage,
      downloader: downloadDio,
      connectivity: connectivity ?? FakeConnectivity(),
      documentsDirectory: () async => tempDir,
    );
  }

  String digestOf(List<int> bytes) => sha256.convert(bytes).toString();

  /// A well-formed manifest entry for [key] served at [path].
  Map<String, dynamic> entry({
    required int version,
    required String path,
    required List<int> bytes,
    String? sha,
  }) =>
      {
        'version': version,
        'url': 'https://cdn.example/$path',
        'sha256': sha ?? digestOf(bytes),
        'bytes': bytes.length,
        'premium': false,
      };

  File installed(String filename) => File('${tempDir.path}/content/$filename');

  final citiesJson = utf8.encode(jsonEncode([
    {'bn': 'ঢাকা', 'en': 'Dhaka'},
  ]));

  group('schedule (FR-C-07)', () {
    test('skips when a sync ran less than 24h ago', () async {
      await storage.setInt(
        StorageKeys.lastContentSyncAt,
        DateTime.now().millisecondsSinceEpoch,
      );

      final manifest = ManifestAdapter({'files': {}});
      final service = buildService(
        manifest: manifest,
        fileAdapter: FileAdapter({}),
      );

      final result = await service.maybeSync();

      expect(result.skippedReason, 'not-due');
      expect(manifest.calls, 0, reason: 'must not contact the server');
    });

    test('runs when the last sync is older than 24h', () async {
      await storage.setInt(
        StorageKeys.lastContentSyncAt,
        DateTime.now()
            .subtract(const Duration(hours: 25))
            .millisecondsSinceEpoch,
      );

      final manifest = ManifestAdapter({'files': {}});
      final service = buildService(
        manifest: manifest,
        fileAdapter: FileAdapter({}),
      );

      expect((await service.maybeSync()).didRun, isTrue);
      expect(manifest.calls, 1);
    });

    test('force overrides the interval', () async {
      await storage.setInt(
        StorageKeys.lastContentSyncAt,
        DateTime.now().millisecondsSinceEpoch,
      );

      final manifest = ManifestAdapter({'files': {}});
      final service = buildService(
        manifest: manifest,
        fileAdapter: FileAdapter({}),
      );

      expect((await service.maybeSync(force: true)).didRun, isTrue);
    });

    test('skips when offline without contacting the server', () async {
      final manifest = ManifestAdapter({'files': {}});
      final service = buildService(
        manifest: manifest,
        fileAdapter: FileAdapter({}),
        connectivity: FakeConnectivity([ConnectivityResult.none]),
      );

      final result = await service.maybeSync();

      expect(result.skippedReason, 'offline');
      expect(manifest.calls, 0);
    });

    test('stamps the clock even when nothing needed downloading', () async {
      final service = buildService(
        manifest: ManifestAdapter({'files': {}}),
        fileAdapter: FileAdapter({}),
      );

      await service.maybeSync();

      expect(storage.getInt(StorageKeys.lastContentSyncAt), greaterThan(0));
    });

    test('a failed manifest fetch does not stamp the clock', () async {
      final service = buildService(
        manifest: ManifestAdapter({}, fail: true),
        fileAdapter: FileAdapter({}),
      );

      final result = await service.maybeSync();

      expect(result.skippedReason, 'manifest-unavailable');
      expect(storage.getInt(StorageKeys.lastContentSyncAt), 0,
          reason: 'an unreachable server must be retried, not deferred 24h');
    });
  });

  group('differential download (FR-C-03)', () {
    test('downloads a file the client does not have', () async {
      final service = buildService(
        manifest: ManifestAdapter({
          'files': {
            'cities': entry(version: 2, path: 'cities.json', bytes: citiesJson),
          }
        }),
        fileAdapter: FileAdapter({'/cities.json': citiesJson}),
      );

      final result = await service.maybeSync();

      expect(result.updated, ['cities']);
      expect(installed(ContentFiles.cities).existsSync(), isTrue);
      expect(
        jsonDecode(installed(ContentFiles.cities).readAsStringSync()),
        isA<List<dynamic>>(),
      );
    });

    test('skips a file already at the manifest version', () async {
      await storage.setString(
        StorageKeys.contentVersions,
        jsonEncode({'cities': 2}),
      );

      final files = FileAdapter({'/cities.json': citiesJson});
      final service = buildService(
        manifest: ManifestAdapter({
          'files': {
            'cities': entry(version: 2, path: 'cities.json', bytes: citiesJson),
          }
        }),
        fileAdapter: files,
      );

      final result = await service.maybeSync();

      expect(result.updated, isEmpty);
      expect(files.requested, isEmpty, reason: 'no bytes should move');
    });

    test('skips a file whose manifest version is older than local', () async {
      await storage.setString(
        StorageKeys.contentVersions,
        jsonEncode({'cities': 5}),
      );

      final files = FileAdapter({'/cities.json': citiesJson});
      final service = buildService(
        manifest: ManifestAdapter({
          'files': {
            'cities': entry(version: 3, path: 'cities.json', bytes: citiesJson),
          }
        }),
        fileAdapter: files,
      );

      expect((await service.maybeSync()).updated, isEmpty);
      expect(files.requested, isEmpty);
    });

    test('records the installed version so the next run is a no-op', () async {
      final service = buildService(
        manifest: ManifestAdapter({
          'files': {
            'cities': entry(version: 7, path: 'cities.json', bytes: citiesJson),
          }
        }),
        fileAdapter: FileAdapter({'/cities.json': citiesJson}),
      );

      await service.maybeSync();

      final versions =
          jsonDecode(storage.getString(StorageKeys.contentVersions));
      expect(versions['cities'], 7);
    });

    test('ignores manifest keys this client does not know', () async {
      final service = buildService(
        manifest: ManifestAdapter({
          'files': {
            'someFutureContent':
                entry(version: 1, path: 'future.json', bytes: citiesJson),
          }
        }),
        fileAdapter: FileAdapter({'/future.json': citiesJson}),
      );

      final result = await service.maybeSync();

      expect(result.updated, isEmpty);
      expect(result.failed, isEmpty, reason: 'unknown is not a failure');
      expect(Directory('${tempDir.path}/content').listSync(), isEmpty);
    });
  });

  group('integrity (FR-C-04)', () {
    test('discards a file whose digest does not match the manifest', () async {
      final service = buildService(
        manifest: ManifestAdapter({
          'files': {
            'cities': entry(
              version: 2,
              path: 'cities.json',
              bytes: citiesJson,
              sha: digestOf(utf8.encode('something else entirely')),
            ),
          }
        }),
        fileAdapter: FileAdapter({'/cities.json': citiesJson}),
      );

      final result = await service.maybeSync();

      expect(result.updated, isEmpty);
      expect(result.failed, ['cities']);
      expect(installed(ContentFiles.cities).existsSync(), isFalse);
    });

    test('a digest mismatch leaves the previous version in place', () async {
      // Install v2 cleanly.
      await buildService(
        manifest: ManifestAdapter({
          'files': {
            'cities': entry(version: 2, path: 'cities.json', bytes: citiesJson),
          }
        }),
        fileAdapter: FileAdapter({'/cities.json': citiesJson}),
      ).maybeSync(force: true);

      final good = installed(ContentFiles.cities).readAsStringSync();

      // v3 arrives corrupted.
      final corrupt = utf8.encode(jsonEncode([
        {'bn': 'corrupt'}
      ]));
      await buildService(
        manifest: ManifestAdapter({
          'files': {
            'cities': entry(
              version: 3,
              path: 'cities.json',
              bytes: corrupt,
              sha: digestOf(utf8.encode('wrong')),
            ),
          }
        }),
        fileAdapter: FileAdapter({'/cities.json': corrupt}),
      ).maybeSync(force: true);

      expect(installed(ContentFiles.cities).readAsStringSync(), good);

      final versions =
          jsonDecode(storage.getString(StorageKeys.contentVersions));
      expect(versions['cities'], 2, reason: 'version must not advance');
    });

    test('rejects a payload that is not valid JSON', () async {
      final garbage = utf8.encode('<html>captive portal login</html>');
      final service = buildService(
        manifest: ManifestAdapter({
          'files': {
            'cities': entry(version: 2, path: 'cities.json', bytes: garbage),
          }
        }),
        fileAdapter: FileAdapter({'/cities.json': garbage}),
      );

      final result = await service.maybeSync();

      expect(result.failed, ['cities'],
          reason: 'a correct digest over garbage is still garbage');
      expect(installed(ContentFiles.cities).existsSync(), isFalse);
    });

    test('treats a 404 as a failure, not an install', () async {
      final service = buildService(
        manifest: ManifestAdapter({
          'files': {
            'cities': entry(version: 2, path: 'cities.json', bytes: citiesJson),
          }
        }),
        fileAdapter: FileAdapter({}), // nothing served
      );

      final result = await service.maybeSync();

      expect(result.failed, ['cities']);
      expect(installed(ContentFiles.cities).existsSync(), isFalse);
    });
  });

  group('atomic replacement (FR-C-05)', () {
    test('leaves no temp file behind on success', () async {
      await buildService(
        manifest: ManifestAdapter({
          'files': {
            'cities': entry(version: 2, path: 'cities.json', bytes: citiesJson),
          }
        }),
        fileAdapter: FileAdapter({'/cities.json': citiesJson}),
      ).maybeSync();

      final names = Directory('${tempDir.path}/content')
          .listSync()
          .map((e) => e.path.split('/').last)
          .toList();

      expect(names, [ContentFiles.cities]);
    });

    test('leaves no temp file behind on a rejected download', () async {
      await buildService(
        manifest: ManifestAdapter({
          'files': {
            'cities': entry(
              version: 2,
              path: 'cities.json',
              bytes: citiesJson,
              sha: digestOf(utf8.encode('mismatch')),
            ),
          }
        }),
        fileAdapter: FileAdapter({'/cities.json': citiesJson}),
      ).maybeSync();

      expect(Directory('${tempDir.path}/content').listSync(), isEmpty);
    });
  });

  group('malformed input', () {
    test('a manifest without a files map is skipped', () async {
      final service = buildService(
        manifest: ManifestAdapter({'files': 'not-a-map'}),
        fileAdapter: FileAdapter({}),
      );

      expect((await service.maybeSync()).skippedReason, 'manifest-malformed');
    });

    test('an entry missing required fields is a failure, not a crash',
        () async {
      final service = buildService(
        manifest: ManifestAdapter({
          'files': {
            'cities': {'version': 2}, // no url, no sha256
          }
        }),
        fileAdapter: FileAdapter({}),
      );

      final result = await service.maybeSync();

      expect(result.failed, ['cities']);
      expect(result.didRun, isTrue);
    });

    test('one bad file does not stop a good one in the same manifest',
        () async {
      final namesJson = utf8.encode(jsonEncode([
        {'name': 'আর-রحمান'}
      ]));

      final service = buildService(
        manifest: ManifestAdapter({
          'files': {
            'cities': entry(
              version: 2,
              path: 'cities.json',
              bytes: citiesJson,
              sha: digestOf(utf8.encode('wrong')),
            ),
            'names': entry(version: 2, path: 'names.json', bytes: namesJson),
          }
        }),
        fileAdapter: FileAdapter({
          '/cities.json': citiesJson,
          '/names.json': namesJson,
        }),
      );

      final result = await service.maybeSync();

      expect(result.updated, ['names']);
      expect(result.failed, ['cities']);
      expect(installed(ContentFiles.namesOfAllah).existsSync(), isTrue);
    });
  });
}
