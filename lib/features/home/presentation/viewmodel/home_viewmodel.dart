import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/prayer_time/domain/models/prayer_time_model.dart';

class HomeViewModel {
  final PrayerTimesModel? todayPrayerTimes;
  final int completedAmalCount;
  final int totalAmalCount;

  const HomeViewModel({
    this.todayPrayerTimes,
    this.completedAmalCount = 0,
    this.totalAmalCount = 7,
  });
}

final homeViewModelProvider = Provider<HomeViewModel>((ref) {
  // TODO: wire prayer time + amal tracker providers
  return const HomeViewModel();
});
