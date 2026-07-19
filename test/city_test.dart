import 'dart:convert';
import 'dart:io';

import 'package:amol365/features/prayer_time/domain/models/city_model.dart';
import 'package:flutter_test/flutter_test.dart';

List<CityModel> loadCities() {
  final file = File('lib/assets/data/cities.json');
  expect(file.existsSync(), isTrue);
  final doc = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  return (doc['items'] as List)
      .cast<Map<String, dynamic>>()
      .map(CityModel.fromJson)
      .toList();
}

void main() {
  late List<CityModel> cities;
  setUp(() => cities = loadCities());

  group('cities.json (FR-N-05)', () {
    test('contains all 64 district headquarters', () {
      expect(cities.length, 64);
    });

    test('every city has both scripts and a division', () {
      for (final c in cities) {
        expect(c.bangla, isNotEmpty, reason: c.english);
        expect(c.english, isNotEmpty, reason: c.bangla);
        expect(c.division, isNotEmpty, reason: c.english);
      }
    });

    test('all coordinates fall inside Bangladesh', () {
      // Bangladesh spans roughly 20.5–26.7 N, 88.0–92.7 E. A city outside this
      // box is a typo, and a typo here silently gives a whole district wrong
      // prayer times.
      for (final c in cities) {
        expect(c.latitude, inInclusiveRange(20.5, 26.8), reason: '${c.english} lat');
        expect(c.longitude, inInclusiveRange(88.0, 92.8), reason: '${c.english} lng');
      }
    });

    test('no duplicate district names', () {
      final bangla = cities.map((c) => c.bangla).toSet();
      final english = cities.map((c) => c.english).toSet();
      expect(bangla.length, 64);
      expect(english.length, 64);
    });

    test('no two cities share identical coordinates', () {
      final coords = cities.map((c) => '${c.latitude},${c.longitude}').toSet();
      expect(coords.length, 64, reason: 'duplicate coordinates mean a copy-paste error');
    });

    test('covers all eight divisions', () {
      final divisions = cities.map((c) => c.division).toSet();
      expect(divisions, hasLength(8));
      expect(
        divisions,
        containsAll([
          'Dhaka', 'Chattogram', 'Rajshahi', 'Khulna',
          'Barishal', 'Sylhet', 'Rangpur', 'Mymensingh',
        ]),
      );
    });
  });

  group('search (FR-N-05 — both scripts)', () {
    test('finds by Bangla name', () {
      final hits = cities.where((c) => c.matches('সিলেট')).toList();
      expect(hits.single.english, 'Sylhet');
    });

    test('finds by English name, and the city itself ranks first', () {
      // "sylhet" also matches the 3 other districts of Sylhet division, so
      // ranking is what makes the exact answer usable rather than buried.
      final hits = cities.where((c) => c.matches('sylhet')).toList()
        ..sort((a, b) => a.matchRank('sylhet')!.compareTo(b.matchRank('sylhet')!));
      expect(hits.first.bangla, 'সিলেট');
      expect(hits.first.matchRank('sylhet'), 0, reason: 'exact match');
    });

    test('English search is case-insensitive and partial', () {
      // A Bangladeshi user on a Bangla phone very often types the city name in
      // English; partial matching is what makes that usable.
      final syl = cities.where((c) => c.matches('SYL')).toList()
        ..sort((a, b) => a.matchRank('SYL')!.compareTo(b.matchRank('SYL')!));
      expect(syl.first.english, 'Sylhet');
      expect(cities.where((c) => c.matches('chat')).isNotEmpty, isTrue);
    });

    test('a city name outranks a division-only match', () {
      final khulnaCity = cities.firstWhere((c) => c.english == 'Khulna');
      final jashore = cities.firstWhere((c) => c.english == 'Jashore');
      expect(khulnaCity.matchRank('khulna')! < jashore.matchRank('khulna')!, isTrue,
          reason: 'Jashore is in Khulna division but is not named Khulna');
    });

    test('finds by division', () {
      final khulna = cities.where((c) => c.matches('Khulna')).toList();
      expect(khulna.length, greaterThan(1), reason: 'division + city both match');
    });

    test('empty query matches everything', () {
      expect(cities.where((c) => c.matches('')).length, 64);
      expect(cities.where((c) => c.matches('   ')).length, 64);
    });

    test('nonsense query matches nothing', () {
      expect(cities.where((c) => c.matches('zzzznotacity')), isEmpty);
    });
  });

  group('known coordinates are sane', () {
    CityModel byEnglish(String name) =>
        cities.firstWhere((c) => c.english == name);

    test('Dhaka', () {
      final dhaka = byEnglish('Dhaka');
      expect(dhaka.latitude, closeTo(23.81, 0.1));
      expect(dhaka.longitude, closeTo(90.41, 0.1));
    });

    test('Sylhet is north-east of Dhaka', () {
      final dhaka = byEnglish('Dhaka');
      final sylhet = byEnglish('Sylhet');
      expect(sylhet.latitude, greaterThan(dhaka.latitude));
      expect(sylhet.longitude, greaterThan(dhaka.longitude));
    });

    test('Chattogram is south-east of Dhaka', () {
      final dhaka = byEnglish('Dhaka');
      final ctg = byEnglish('Chattogram');
      expect(ctg.latitude, lessThan(dhaka.latitude));
      expect(ctg.longitude, greaterThan(dhaka.longitude));
    });

    test('Panchagarh is the northernmost district', () {
      final northernmost =
          cities.reduce((a, b) => a.latitude > b.latitude ? a : b);
      expect(northernmost.english, 'Panchagarh');
    });
  });
}
