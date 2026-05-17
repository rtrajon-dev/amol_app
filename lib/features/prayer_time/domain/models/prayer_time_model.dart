class PrayerTimesModel {
  final String fajr;
  final String sunrise;
  final String dhuhr;
  final String asr;
  final String maghrib;
  final String isha;
  final String nextPrayerName;
  final String nextPrayerTime;
  final DateTime date;

  const PrayerTimesModel({
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    required this.nextPrayerName,
    required this.nextPrayerTime,
    required this.date,
  });
}

class Prayer {
  final String name;
  final String banglaName;
  final String time;
  final bool isNext;
  final bool isPassed;

  const Prayer({
    required this.name,
    required this.banglaName,
    required this.time,
    this.isNext = false,
    this.isPassed = false,
  });
}
