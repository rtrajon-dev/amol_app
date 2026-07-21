import 'dart:convert';

import 'package:adhan/adhan.dart';

import '../../features/prayer_time/domain/models/prayer_time_model.dart';
import '../services/storage_service.dart';

/// Astronomical prayer-time calculation.
///
/// C-01 — computed on-device via the `adhan` package. There is no prayer-time
/// API and none may be introduced: the feature must work with no network.
class PrayerTimeUtils {
  /// FR-N-11 — selectable calculation methods.
  ///
  /// Karachi is the default because it is the standard used across Bangladesh;
  /// changing it visibly changes Fajr and Isha.
  static const methods = <String, String>{
    'karachi': 'কারাচি',
    'muslim_world_league': 'মুসলিম ওয়ার্ল্ড লীগ',
    'umm_al_qura': 'উম্মুল কুরা',
    'egyptian': 'মিশরীয়',
    'moon_sighting_committee': 'মুনসাইটিং কমিটি',
  };

  static CalculationMethod _method(String key) => switch (key) {
        'muslim_world_league' => CalculationMethod.muslim_world_league,
        'umm_al_qura' => CalculationMethod.umm_al_qura,
        'egyptian' => CalculationMethod.egyptian,
        'moon_sighting_committee' => CalculationMethod.moon_sighting_committee,
        _ => CalculationMethod.karachi,
      };

  static String readMethodKey() {
    final saved = StorageService.instance.getString(StorageKeys.calculationMethod);
    return methods.containsKey(saved) ? saved : 'karachi';
  }

  /// FR-N-12 — Hanafi is the default; it affects Asr only.
  static Madhab readMadhab() =>
      StorageService.instance.getString(StorageKeys.madhab) == 'shafi'
          ? Madhab.shafi
          : Madhab.hanafi;

  /// FR-N-11 / FR-N-12 — method and madhab now come from settings rather than
  /// being hardcoded (closes G-02).
  static PrayerTimes calculate({
    required double latitude,
    required double longitude,
    DateTime? date,
  }) {
    final coords = Coordinates(latitude, longitude);
    final params = _method(readMethodKey()).getParameters()
      ..madhab = readMadhab();
    final dateComponents = DateComponents.from(date ?? DateTime.now());
    return PrayerTimes(coords, dateComponents, params);
  }

  /// FR-N-13 — per-prayer offsets in minutes, clamped to −30..+30.
  static Map<PrayerSlot, int> readOffsets() {
    final raw = StorageService.instance.getString(StorageKeys.prayerOffsets);
    if (raw.isEmpty) return const {};

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const {};

      final offsets = <PrayerSlot, int>{};
      for (final slot in PrayerSlot.values) {
        final value = decoded[slot.name];
        if (value is int) offsets[slot] = value.clamp(-30, 30);
      }
      return offsets;
    } catch (_) {
      return const {};
    }
  }

  static Future<void> writeOffsets(Map<PrayerSlot, int> offsets) async {
    final map = <String, int>{
      for (final entry in offsets.entries)
        if (entry.value != 0) entry.key.name: entry.value.clamp(-30, 30),
    };
    await StorageService.instance
        .setString(StorageKeys.prayerOffsets, jsonEncode(map));
  }

  static String formatTime(DateTime time) {
    final h = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final m = time.minute.toString().padLeft(2, '0');
    final period = time.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  /// NFR-07 — Bangla numerals, e.g. "৫:৪২ ভোর".
  static String formatBangla(DateTime time) {
    final h = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final m = time.minute.toString().padLeft(2, '0');
    final period = switch (time.hour) {
      < 6 => 'ভোর',
      < 12 => 'সকাল',
      < 15 => 'দুপুর',
      < 18 => 'বিকাল',
      < 20 => 'সন্ধ্যা',
      _ => 'রাত',
    };
    return '${toBanglaDigits('$h:$m')} $period';
  }

  /// Gregorian date in Bangla, e.g. "২১ জুলাই ২০২৬".
  ///
  /// Written out rather than pulled from `intl`: the bundled Bangla locale
  /// abbreviates months in a form most readers here do not use day to day.
  static String formatDateBangla(DateTime date) {
    const months = [
      'জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন',
      'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর',
    ];
    final month = months[date.month - 1];
    return '${toBanglaDigits('${date.day}')} $month '
        '${toBanglaDigits('${date.year}')}';
  }

  static String toBanglaDigits(String value) {
    const digits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    return value.split('').map((c) {
      final i = int.tryParse(c);
      return i == null ? c : digits[i];
    }).join();
  }

  // Dhaka, Bangladesh — last-resort fallback only, and always reported as
  // approximate rather than silently substituted (G-06).
  // (Previously `dhakeLat`, a typo — G-08.)
  static const double dhakaLat = 23.8103;
  static const double dhakaLng = 90.4125;
}
