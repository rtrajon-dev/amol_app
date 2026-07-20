import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import '../network/api_client.dart';
import 'content_service.dart';
import 'storage_service.dart';

/// One entry of `GET /content/manifest` (FR-C-02).
class ContentFileEntry {
  const ContentFileEntry({
    required this.key,
    required this.version,
    required this.url,
    required this.sha256,
    required this.bytes,
    required this.premium,
  });

  /// Logical name in the manifest (`hadiths`, `names`, `surahsFull`, …).
  final String key;
  final int version;
  final String url;
  final String sha256;
  final int bytes;
  final bool premium;

  static ContentFileEntry? tryParse(String key, Object? raw) {
    if (raw is! Map) return null;

    final version = raw['version'];
    final url = raw['url'];
    final digest = raw['sha256'];
    if (version is! int || url is! String || digest is! String) return null;
    if (url.isEmpty || digest.isEmpty) return null;

    return ContentFileEntry(
      key: key,
      version: version,
      url: url,
      sha256: digest.toLowerCase(),
      bytes: raw['bytes'] is int ? raw['bytes'] as int : 0,
      premium: raw['premium'] == true,
    );
  }
}

/// Outcome of a sync attempt. Reported for telemetry and tests; the user is
/// never shown any of it (FR-C-06).
class ContentSyncResult {
  const ContentSyncResult({
    this.updated = const [],
    this.skippedReason,
    this.failed = const [],
  });

  /// Logical keys written this run.
  final List<String> updated;

  /// Set when the run was declined before contacting the server.
  final String? skippedReason;

  /// Keys that were attempted and rejected — download error, integrity
  /// mismatch, or a bad write.
  final List<String> failed;

  bool get didRun => skippedReason == null;
}

/// Downloads updated content files and installs them beside the bundled copy.
///
/// The app never depends on this succeeding. [ContentService] resolves
/// downloaded → bundled (FR-C-06), so every failure path here simply leaves
/// the previous content in place.
class ContentSyncService {
  ContentSyncService({
    required ApiClient api,
    required StorageService storage,
    ContentService? content,
    Dio? downloader,
    Connectivity? connectivity,
    Future<Directory?> Function()? documentsDirectory,
  })  : _api = api,
        _storage = storage,
        _content = content ?? ContentService.instance,
        _downloader = downloader ?? Dio(),
        _connectivity = connectivity ?? Connectivity(),
        _documentsDirectory = documentsDirectory ?? _defaultDocumentsDirectory;

  final ApiClient _api;
  final StorageService _storage;
  final ContentService _content;
  final Dio _downloader;
  final Connectivity _connectivity;
  final Future<Directory?> Function() _documentsDirectory;

  static const _manifestPath = '/content/manifest';

  /// FR-C-07 — the floor between attempts. The server may raise it per
  /// response but never lower it below this.
  static const minInterval = Duration(hours: 24);

  /// Manifest key → the filename [ContentService] reads.
  ///
  /// A key absent here is ignored rather than guessed at: a future server-side
  /// content type must not be written to an arbitrary local path by an old
  /// client.
  ///
  /// FR-PH-12 — that same behaviour withholds Phase 2 content. `hadiths`,
  /// `surahs` and `surahsFull` are commented out rather than deleted so
  /// Phase 2 is three uncommented lines. The server keeps advertising all of
  /// them, which is what lets one manifest serve Phase 1 and Phase 2 clients
  /// at the same time — both will be in the field together.
  static const fileNames = <String, String>{
    'names': ContentFiles.namesOfAllah,
    'cities': ContentFiles.cities,
    // Phase 2 (docs/SRS-Release-Phasing.md):
    // 'hadiths': ContentFiles.hadiths,
    // 'surahs': ContentFiles.surahs,
    // 'surahsFull': ContentFiles.surahsFull,
  };

  static Future<Directory?> _defaultDocumentsDirectory() async {
    try {
      return await getApplicationDocumentsDirectory();
    } catch (_) {
      return null;
    }
  }

  /// Runs a sync if one is due (FR-C-07). Safe to call on every app resume.
  ///
  /// MUST NOT be called during startup — FR-G-08 keeps the launch path free of
  /// network work.
  Future<ContentSyncResult> maybeSync({bool force = false}) async {
    if (!force) {
      final last = _storage.getInt(StorageKeys.lastContentSyncAt);
      final elapsed = DateTime.now().millisecondsSinceEpoch - last;
      if (last > 0 && elapsed < minInterval.inMilliseconds) {
        return const ContentSyncResult(skippedReason: 'not-due');
      }
    }

    final connection = await _connectivity.checkConnectivity();
    if (connection.isEmpty || connection.every((r) => r == ConnectivityResult.none)) {
      // Not a failure: offline is the expected state for much of the audience.
      return const ContentSyncResult(skippedReason: 'offline');
    }

    return _run();
  }

  Future<ContentSyncResult> _run() async {
    final Map<String, dynamic> response;
    try {
      response = await _api.get(_manifestPath);
    } catch (_) {
      // Server down, no auth, timeout — all identical from here: keep the
      // content we have and try again next time.
      return const ContentSyncResult(skippedReason: 'manifest-unavailable');
    }

    final files = response['files'];
    if (files is! Map) {
      return const ContentSyncResult(skippedReason: 'manifest-malformed');
    }

    final dir = await _documentsDirectory();
    if (dir == null) {
      return const ContentSyncResult(skippedReason: 'no-storage');
    }

    final contentDir = Directory('${dir.path}/content');
    try {
      if (!contentDir.existsSync()) await contentDir.create(recursive: true);
    } catch (_) {
      return const ContentSyncResult(skippedReason: 'no-storage');
    }

    final localVersions = _localVersions();
    final updated = <String>[];
    final failed = <String>[];

    for (final entry in files.entries) {
      final key = entry.key;
      if (key is! String) continue;

      final filename = fileNames[key];
      if (filename == null) continue; // unknown to this client version

      final file = ContentFileEntry.tryParse(key, entry.value);
      if (file == null) {
        failed.add(key);
        continue;
      }

      // FR-C-03 — only newer files are fetched. Equal versions are the common
      // case and must cost nothing.
      if (file.version <= (localVersions[key] ?? 0)) continue;

      final ok = await _install(file, filename, contentDir);
      if (ok) {
        updated.add(key);
        localVersions[key] = file.version;
      } else {
        failed.add(key);
      }
    }

    if (updated.isNotEmpty) {
      await _storage.setString(
        StorageKeys.contentVersions,
        jsonEncode(localVersions),
      );
      // Drop parsed copies so the next read picks up what was just written.
      for (final key in updated) {
        _content.invalidate(fileNames[key]);
      }
    }

    // Stamped even when nothing changed: a successful check is what the 24h
    // interval measures, not a successful download.
    await _storage.setInt(
      StorageKeys.lastContentSyncAt,
      DateTime.now().millisecondsSinceEpoch,
    );

    return ContentSyncResult(updated: updated, failed: failed);
  }

  /// Downloads, verifies and atomically installs one file.
  ///
  /// Returns false on any failure, having left the existing file untouched.
  Future<bool> _install(
    ContentFileEntry file,
    String filename,
    Directory contentDir,
  ) async {
    final List<int> bytes;
    try {
      final response = await _downloader.get<List<int>>(
        file.url,
        options: Options(
          responseType: ResponseType.bytes,
          // Static content: read it ourselves rather than letting Dio throw.
          validateStatus: (_) => true,
        ),
      );
      if (response.statusCode != 200 || response.data == null) return false;
      bytes = response.data!;
    } catch (_) {
      return false;
    }

    // FR-C-04 — a file that does not match its manifest digest is discarded.
    // Truncation, a captive-portal login page, and tampering all land here.
    if (sha256.convert(bytes).toString() != file.sha256) return false;

    // Parsing before committing keeps a syntactically valid but wrong-typed
    // payload from replacing good content.
    try {
      jsonDecode(utf8.decode(bytes));
    } catch (_) {
      return false;
    }

    // FR-C-05 — temp file plus rename. A kill between the two leaves the old
    // file whole; rename is atomic within a filesystem.
    final target = File('${contentDir.path}/$filename');
    final temp = File('${target.path}.tmp');
    try {
      await temp.writeAsBytes(bytes, flush: true);
      await temp.rename(target.path);
      return true;
    } catch (_) {
      try {
        if (temp.existsSync()) await temp.delete();
      } catch (_) {
        // Best effort — a stray temp file is harmless and is overwritten next
        // time this key is installed.
      }
      return false;
    }
  }

  Map<String, int> _localVersions() {
    final raw = _storage.getString(StorageKeys.contentVersions);
    if (raw.isEmpty) return {};

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      return {
        for (final e in decoded.entries)
          if (e.key is String && e.value is int) e.key as String: e.value as int,
      };
    } catch (_) {
      return {};
    }
  }
}
