import 'dart:convert';
import 'dart:io';

import 'package:amol365/features/hadith/domain/models/hadith_model.dart';
import 'package:amol365/features/names_of_allah/domain/models/allah_name_model.dart';
import 'package:amol365/features/surah/domain/models/surah_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// Validates the JSON that actually ships in the APK.
///
/// These tests cannot check whether the Arabic is CORRECT — only a qualified
/// human can do that (docs/CONTENT.md §3). What they can do is catch the
/// mechanical failures: malformed JSON, missing fields, wrong counts, empty
/// strings, and unattributed hadiths.
Map<String, dynamic> readJson(String filename) {
  final file = File('lib/assets/data/$filename');
  expect(file.existsSync(), isTrue, reason: '$filename must exist');
  return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
}

List<Map<String, dynamic>> itemsOf(Map<String, dynamic> doc) =>
    (doc['items'] as List).cast<Map<String, dynamic>>();

void main() {
  group('names_of_allah.json', () {
    late Map<String, dynamic> doc;
    setUp(() => doc = readJson('names_of_allah.json'));

    test('contains exactly 99 names, numbered 1..99 with no gaps', () {
      final items = itemsOf(doc);
      expect(items.length, 99);

      final numbers = items.map((e) => e['number'] as int).toList()..sort();
      expect(numbers, List.generate(99, (i) => i + 1));
    });

    test('every name parses and has no empty field', () {
      for (final raw in itemsOf(doc)) {
        final name = AllahNameModel.fromJson(raw);
        expect(name.arabic, isNotEmpty, reason: 'name ${name.number} arabic');
        expect(name.transliteration, isNotEmpty, reason: 'name ${name.number} translit');
        expect(name.bangla, isNotEmpty, reason: 'name ${name.number} bangla');
        expect(name.meaning, isNotEmpty, reason: 'name ${name.number} meaning');
      }
    });

    test('arabic fields contain Arabic script, not placeholder text', () {
      final arabic = RegExp(r'[؀-ۿ]');
      for (final raw in itemsOf(doc)) {
        expect(arabic.hasMatch(raw['arabic'] as String), isTrue,
            reason: 'name ${raw['number']} must be Arabic script');
      }
    });

    test('bangla fields contain Bengali script', () {
      final bengali = RegExp(r'[ঀ-৿]');
      for (final raw in itemsOf(doc)) {
        expect(bengali.hasMatch(raw['bangla'] as String), isTrue,
            reason: 'name ${raw['number']} bangla must be Bengali script');
      }
    });
  });

  group('surahs.json', () {
    late Map<String, dynamic> doc;
    setUp(() => doc = readJson('surahs.json'));

    test('every surah parses with a complete ayah list', () {
      for (final raw in itemsOf(doc)) {
        final surah = SurahModel.fromJson(raw);
        expect(surah.number, greaterThan(0));
        expect(surah.arabicName, isNotEmpty);
        expect(surah.banglaName, isNotEmpty);
        expect(surah.ayahs, isNotEmpty, reason: 'surah ${surah.number} has no ayahs');

        expect(surah.ayahs.length, surah.verseCount,
            reason: 'surah ${surah.number}: verseCount must match the ayahs shipped');

        for (final ayah in surah.ayahs) {
          expect(ayah.arabic, isNotEmpty, reason: '${surah.number}:${ayah.number} arabic');
          expect(ayah.bangla, isNotEmpty, reason: '${surah.number}:${ayah.number} bangla');
        }
      }
    });

    test('no surah claims more verses than it ships', () {
      // Guards the specific failure this file was built to avoid: listing a
      // long surah (Al-Baqarah, Ya-Sin, …) with only a stub of its text.
      for (final raw in itemsOf(doc)) {
        final surah = SurahModel.fromJson(raw);
        expect(surah.ayahs.length, greaterThanOrEqualTo(surah.verseCount),
            reason: 'surah ${surah.number} is incomplete and must not be listed');
      }
    });

    test('ayah numbers are sequential within a complete surah', () {
      for (final raw in itemsOf(doc)) {
        final surah = SurahModel.fromJson(raw);
        if (surah.isPassage) continue; // a passage keeps its original numbering
        final numbers = surah.ayahs.map((a) => a.number).toList();
        expect(numbers, List.generate(surah.ayahs.length, (i) => i + 1),
            reason: 'surah ${surah.number} ayah numbering');
      }
    });

    test('a passage is labelled as a passage', () {
      for (final raw in itemsOf(doc)) {
        final surah = SurahModel.fromJson(raw);
        if (!surah.isPassage) continue;
        expect(surah.passageNote, isNotEmpty,
            reason: 'surah ${surah.number}: a passage must say where it is from, '
                'so it is never mistaken for a complete surah');
      }
    });

    test('long surahs are absent until ingested from a verified source', () {
      final numbers = itemsOf(doc).map((e) => e['number'] as int).toSet();
      // docs/CONTENT.md §2 — these must come from a verified digital edition,
      // never hand-typed. If you add them, remove them from this list.
      for (final banned in [2, 36, 55, 67]) {
        expect(numbers.contains(banned), isFalse,
            reason: 'surah $banned must be ingested from a verified edition '
                '(docs/CONTENT.md §4), not added by hand');
      }
    });
  });

  group('hadiths.json', () {
    test('if present, every hadith carries full attribution', () {
      final file = File('lib/assets/data/hadiths.json');
      if (!file.existsSync()) {
        // Intentionally absent — no verified source chosen yet.
        return;
      }

      final items = itemsOf(jsonDecode(file.readAsStringSync()) as Map<String, dynamic>);
      for (final raw in items) {
        final hadith = HadithModel.fromJson(raw);
        expect(hadith.isAttributed, isTrue,
            reason: 'hadith "${hadith.id}" lacks source/bookReference — '
                'unattributed text must never ship as hadith');
      }
    });
  });

  group('release gate', () {
    test('unverified content files are flagged for review', () {
      // This test documents status rather than failing the build: it prints
      // what still needs a qualified reviewer before release.
      // See docs/CONTENT.md §3.
      final unverified = <String>[];
      for (final filename in ['names_of_allah.json', 'surahs.json']) {
        final doc = readJson(filename);
        final meta = doc['_meta'] as Map<String, dynamic>?;
        expect(meta, isNotNull, reason: '$filename must carry _meta');
        if (meta!['verified'] != true) unverified.add(filename);
      }

      if (unverified.isNotEmpty) {
        printOnFailure('Awaiting review: ${unverified.join(", ")}');
      }
      expect(unverified, isNotEmpty,
          reason: 'When these are verified, flip _meta.verified and update '
              'this test to assert the opposite.');
    });
  });
}
