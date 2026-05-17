import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/prayer_time_service.dart';
import '../../domain/models/prayer_time_model.dart';

final prayerTimeServiceProvider = Provider<PrayerTimeService>((ref) => PrayerTimeService());

final prayerTimesProvider = FutureProvider<PrayerTimesModel>((ref) async {
  final service = ref.watch(prayerTimeServiceProvider);
  return service.getTodayPrayerTimes();
});
