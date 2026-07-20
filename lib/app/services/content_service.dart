import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// Loads bundled JSON content, preferring a downloaded copy when one exists.
///
/// FR-C-01 — the app ships a complete copy of every content file and is fully
/// functional with no network, forever.
/// FR-C-06 — resolution order is: downloaded → bundled. A failed or absent
/// sync is therefore invisible to the user.
///
/// M-5 adds the downloader that writes into the documents directory; this
/// service already reads from there, so that release needs no change here.
class ContentService {
  ContentService._();
  static final instance = ContentService._();

  static const _assetDir = 'lib/assets/data';

  /// Parsed files are cached for the process lifetime — content is static and
  /// re-parsing on every screen entry is wasted work on a low-end device.
  final Map<String, List<dynamic>> _cache = {};

  Directory? _documentsDir;

  Future<Directory?> _docs() async {
    try {
      return _documentsDir ??= await getApplicationDocumentsDirectory();
    } catch (_) {
      return null; // unavailable in tests / restricted environments
    }
  }

  /// Load a JSON array file, e.g. `names_of_allah.json`.
  ///
  /// Returns an empty list rather than throwing when the file is missing or
  /// malformed: a content screen with nothing in it is recoverable, a crash on
  /// launch is not.
  Future<List<Map<String, dynamic>>> loadList(String filename) async {
    final cached = _cache[filename];
    if (cached != null) return cached.cast<Map<String, dynamic>>();

    final raw = await _readRaw(filename);
    if (raw == null) return const [];

    try {
      final decoded = jsonDecode(raw);
      final list = decoded is List
          ? decoded
          : (decoded is Map && decoded['items'] is List
              ? decoded['items'] as List
              : const []);

      _cache[filename] = list;
      return list.cast<Map<String, dynamic>>();
    } on FormatException {
      return const [];
    }
  }

  Future<String?> _readRaw(String filename) async {
    // 1. Downloaded copy (M-5), if present.
    final dir = await _docs();
    if (dir != null) {
      final file = File('${dir.path}/content/$filename');
      try {
        if (file.existsSync()) return await file.readAsString();
      } catch (_) {
        // Fall through to the bundled copy — a corrupt download must never
        // take the feature down when a good bundled version exists.
      }
    }

    // 2. Bundled copy.
    try {
      return await rootBundle.loadString('$_assetDir/$filename');
    } catch (_) {
      return null;
    }
  }

  /// Test seam / M-5 hook: drop cached parses after a sync writes new files.
  void invalidate([String? filename]) {
    if (filename == null) {
      _cache.clear();
    } else {
      _cache.remove(filename);
    }
  }
}

abstract class ContentFiles {
  static const namesOfAllah = 'names_of_allah.json';
  static const surahs = 'surahs.json';
  static const hadiths = 'hadiths.json';
  static const cities = 'cities.json';

  /// FR-C-08 — all 114 surahs, premium-only. Served only to entitled users and
  /// enforced server-side; the client never decides its own entitlement.
  static const surahsFull = 'surahs_full.json';
}
