import 'package:adhan/adhan.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../app/utils/prayer_time_utils.dart';
import '../../domain/models/prayer_time_model.dart';

class PrayerTimeService {
  Future<PrayerTimesModel> getTodayPrayerTimes() async {
    final position = await _getPosition();
    final times = PrayerTimeUtils.calculate(
      latitude: position.latitude,
      longitude: position.longitude,
    );
    return _toModel(times);
  }

  Future<Position> _getPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return _dhakaDefault();

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) return _dhakaDefault();

    return Geolocator.getCurrentPosition();
  }

  Position _dhakaDefault() => Position(
        latitude: PrayerTimeUtils.dhakeLat,
        longitude: PrayerTimeUtils.dhakaLng,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );

  PrayerTimesModel _toModel(PrayerTimes times) {
    final now = DateTime.now();
    final next = times.nextPrayer();
    final nextName = _prayerBanglaName(next);
    final nextTime = PrayerTimeUtils.formatTime(times.timeForPrayer(next)!);

    return PrayerTimesModel(
      fajr: PrayerTimeUtils.formatTime(times.fajr),
      sunrise: PrayerTimeUtils.formatTime(times.sunrise),
      dhuhr: PrayerTimeUtils.formatTime(times.dhuhr),
      asr: PrayerTimeUtils.formatTime(times.asr),
      maghrib: PrayerTimeUtils.formatTime(times.maghrib),
      isha: PrayerTimeUtils.formatTime(times.isha),
      nextPrayerName: nextName,
      nextPrayerTime: nextTime,
      date: now,
    );
  }

  String _prayerBanglaName(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr: return 'ফজর';
      case Prayer.sunrise: return 'সূর্যোদয়';
      case Prayer.dhuhr: return 'যোহর';
      case Prayer.asr: return 'আসর';
      case Prayer.maghrib: return 'মাগরিব';
      case Prayer.isha: return 'এশা';
      default: return 'নামাজ';
    }
  }
}
