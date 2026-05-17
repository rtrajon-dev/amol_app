import 'package:adhan/adhan.dart';

class PrayerTimeUtils {
  static PrayerTimes calculate({
    required double latitude,
    required double longitude,
    DateTime? date,
  }) {
    final coords = Coordinates(latitude, longitude);
    final params = CalculationMethod.karachi.getParameters()
      ..madhab = Madhab.hanafi;
    final dateComponents = DateComponents.from(date ?? DateTime.now());
    return PrayerTimes(coords, dateComponents, params);
  }

  static String formatTime(DateTime time) {
    final h = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final m = time.minute.toString().padLeft(2, '0');
    final period = time.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  // Default coordinates for Dhaka, Bangladesh
  static const double dhakeLat = 23.8103;
  static const double dhakaLng = 90.4125;
}
