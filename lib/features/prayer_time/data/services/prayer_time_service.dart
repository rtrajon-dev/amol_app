import 'package:geolocator/geolocator.dart';

import '../../../../app/services/storage_service.dart';
import '../../../../app/utils/prayer_time_utils.dart';
import '../../domain/models/prayer_time_model.dart';

/// How the active location was obtained. The UI must be able to tell the user
/// which of these applied — silently computing for the wrong city is the bug
/// this closes (G-06).
enum LocationSource { gps, manual, cached, fallback }

class ResolvedLocation {
  const ResolvedLocation({
    required this.latitude,
    required this.longitude,
    required this.name,
    required this.source,
  });

  final double latitude;
  final double longitude;
  final String name;
  final LocationSource source;

  /// FR-N-03 / G-06 — true when we are guessing. The screen shows a warning
  /// and offers manual selection instead of presenting the times as correct.
  bool get isApproximate => source == LocationSource.fallback;
}

class PrayerTimeService {
  /// FR-N-09 — GPS is given a bounded window; beyond it we use the cache.
  static const gpsTimeout = Duration(seconds: 15);

  /// Resolve the location to compute for, in priority order:
  /// manual selection → fresh GPS → cached fix → Dhaka fallback.
  ///
  /// The fallback is still last resort, but unlike before it is *reported*
  /// rather than silently substituted (G-06).
  Future<ResolvedLocation> resolveLocation({bool allowGps = true}) async {
    final storage = StorageService.instance;

    // 1. Manual selection always wins (FR-N-01, FR-N-03).
    if (storage.getString(StorageKeys.locationSource) == 'manual') {
      final lat = double.tryParse(storage.getString(StorageKeys.locationLat));
      final lng = double.tryParse(storage.getString(StorageKeys.locationLng));
      if (lat != null && lng != null) {
        return ResolvedLocation(
          latitude: lat,
          longitude: lng,
          name: storage.getString(StorageKeys.locationName),
          source: LocationSource.manual,
        );
      }
    }

    // 2. GPS, if permitted and enabled.
    if (allowGps) {
      final position = await _tryGps();
      if (position != null) {
        await _cache(position.latitude, position.longitude);
        final saved = storage.getString(StorageKeys.locationName);
        return ResolvedLocation(
          latitude: position.latitude,
          longitude: position.longitude,
          name: saved.isEmpty ? 'বর্তমান অবস্থান' : saved,
          source: LocationSource.gps,
        );
      }
    }

    // 3. Cached fix (FR-N-07) — this is what makes airplane mode work.
    final cachedLat = double.tryParse(storage.getString(StorageKeys.locationLat));
    final cachedLng = double.tryParse(storage.getString(StorageKeys.locationLng));
    if (cachedLat != null && cachedLng != null) {
      final saved = storage.getString(StorageKeys.locationName);
      return ResolvedLocation(
        latitude: cachedLat,
        longitude: cachedLng,
        name: saved.isEmpty ? 'সর্বশেষ অবস্থান' : saved,
        source: LocationSource.cached,
      );
    }

    // 4. Dhaka — flagged as approximate, never presented as certain.
    return const ResolvedLocation(
      latitude: PrayerTimeUtils.dhakaLat,
      longitude: PrayerTimeUtils.dhakaLng,
      name: 'ঢাকা',
      source: LocationSource.fallback,
    );
  }

  Future<Position?> _tryGps() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low, // city-level is ample for prayer times
          timeLimit: gpsTimeout,
        ),
      );
    } catch (_) {
      // Timeout or platform error — the caller falls back to cache (FR-N-09).
      return null;
    }
  }

  Future<void> _cache(double lat, double lng) async {
    final storage = StorageService.instance;
    await storage.setString(StorageKeys.locationLat, lat.toString());
    await storage.setString(StorageKeys.locationLng, lng.toString());
    await storage.setInt(
      StorageKeys.locationTimestamp,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Prayer times for one date at a resolved location.
  PrayerTimesModel computeFor({
    required ResolvedLocation location,
    required DateTime date,
  }) {
    final times = PrayerTimeUtils.calculate(
      latitude: location.latitude,
      longitude: location.longitude,
      date: date,
    );

    final offsets = PrayerTimeUtils.readOffsets();

    PrayerTime build(PrayerSlot slot, DateTime time) => PrayerTime(
          slot: slot,
          // FR-N-13 — per-prayer manual offsets, applied after calculation so
          // users can match their local mosque.
          time: time.add(Duration(minutes: offsets[slot] ?? 0)),
        );

    return PrayerTimesModel(
      date: date,
      prayers: [
        build(PrayerSlot.fajr, times.fajr),
        build(PrayerSlot.sunrise, times.sunrise),
        build(PrayerSlot.dhuhr, times.dhuhr),
        build(PrayerSlot.asr, times.asr),
        build(PrayerSlot.maghrib, times.maghrib),
        build(PrayerSlot.isha, times.isha),
      ],
      locationName: location.name,
      isFromCache: location.source == LocationSource.cached ||
          location.source == LocationSource.fallback,
    );
  }

  Future<PrayerTimesModel> getTodayPrayerTimes() async {
    final location = await resolveLocation();
    return computeFor(location: location, date: DateTime.now());
  }

  /// FR-N-26 — the rolling window the azan scheduler needs.
  Future<List<PrayerTimesModel>> getUpcomingDays({int days = 7}) async {
    final location = await resolveLocation();
    final today = DateTime.now();

    return List.generate(
      days,
      (i) => computeFor(
        location: location,
        date: DateTime(today.year, today.month, today.day + i),
      ),
    );
  }

  /// EC-01 — after Isha there is no later prayer today, so the countdown rolls
  /// forward to tomorrow's Fajr rather than showing nothing.
  Future<PrayerTime?> nextPrayer() async {
    final location = await resolveLocation();
    final now = DateTime.now();

    final today = computeFor(location: location, date: now);
    final next = today.nextAfter(now);
    if (next != null) return next;

    final tomorrow = computeFor(
      location: location,
      date: DateTime(now.year, now.month, now.day + 1),
    );
    final fajr = tomorrow.timeFor(PrayerSlot.fajr);
    return fajr == null ? null : PrayerTime(slot: PrayerSlot.fajr, time: fajr);
  }
}
