import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../global_widgets/loading_indicator.dart';
import '../viewmodel/prayer_time_viewmodel.dart';
import '../widgets/prayer_card.dart';

class PrayerTimeScreen extends ConsumerWidget {
  const PrayerTimeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prayerTimesAsync = ref.watch(prayerTimesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('নামাজের সময়')),
      body: prayerTimesAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => Center(child: Text('সময় লোড করা যাচ্ছে না: $e')),
        data: (times) => ListView(
          padding: EdgeInsets.all(16.w),
          children: [
            PrayerCard(name: 'ফজর', time: times.fajr, icon: Icons.wb_twilight),
            PrayerCard(name: 'সূর্যোদয়', time: times.sunrise, icon: Icons.wb_sunny_outlined),
            PrayerCard(name: 'যোহর', time: times.dhuhr, icon: Icons.wb_sunny),
            PrayerCard(name: 'আসর', time: times.asr, icon: Icons.cloud_outlined),
            PrayerCard(name: 'মাগরিব', time: times.maghrib, icon: Icons.nights_stay_outlined),
            PrayerCard(name: 'এশা', time: times.isha, icon: Icons.nightlight_round),
          ],
        ),
      ),
    );
  }
}
