import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/utils/hijri_utils.dart';
import '../../../../app/utils/prayer_time_utils.dart';
import '../../../../global_widgets/loading_indicator.dart';
import '../../data/services/prayer_time_service.dart';
import '../../domain/models/prayer_time_model.dart';
import '../viewmodel/prayer_time_viewmodel.dart';
import '../widgets/prayer_card.dart';

class PrayerTimeScreen extends ConsumerWidget {
  const PrayerTimeScreen({super.key});

  static const _icons = {
    PrayerSlot.fajr: Icons.wb_twilight,
    PrayerSlot.sunrise: Icons.wb_sunny_outlined,
    PrayerSlot.dhuhr: Icons.wb_sunny,
    PrayerSlot.asr: Icons.cloud_outlined,
    PrayerSlot.maghrib: Icons.nights_stay_outlined,
    PrayerSlot.isha: Icons.nightlight_round,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timesAsync = ref.watch(prayerTimesProvider);
    final locationAsync = ref.watch(resolvedLocationProvider);
    final nextAsync = ref.watch(nextPrayerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('নামাজের সময়')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(resolvedLocationProvider);
          await ref.read(prayerTimesProvider.future);
        },
        child: timesAsync.when(
          loading: () => const LoadingIndicator(),
          error: (_, _) => ListView(
            children: [
              SizedBox(height: 80.h),
              const _Message(
                emoji: '⚠️',
                text: 'নামাজের সময় গণনা করা যায়নি। টেনে রিফ্রেশ করুন।',
              ),
            ],
          ),
          data: (times) {
            final current = times.currentAt(DateTime.now());

            return ListView(
              padding: EdgeInsets.all(16.w),
              children: [
                // FR-N-18 — location, date, and live countdown.
                _Header(
                  times: times,
                  location: locationAsync.value,
                  next: nextAsync.value,
                ),
                SizedBox(height: 16.h),

                // G-06 — when the location is a guess, say so. The previous
                // build silently used Dhaka, so a user in Sylhet saw times
                // that were quietly wrong with no way to notice.
                if (locationAsync.value?.isApproximate ?? false) ...[
                  const _ApproximateWarning(),
                  SizedBox(height: 16.h),
                ],

                for (final prayer in times.prayers)
                  PrayerCard(
                    name: prayer.bangla,
                    time: PrayerTimeUtils.formatBangla(prayer.time),
                    icon: _icons[prayer.slot] ?? Icons.access_time,
                    isCurrent: current?.slot == prayer.slot,
                    isNext: nextAsync.value?.prayer.slot == prayer.slot,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.times, this.location, this.next});

  final PrayerTimesModel times;
  final ResolvedLocation? location;
  final NextPrayerState? next;

  @override
  Widget build(BuildContext context) {
    final hijri = HijriDate.fromGregorian(times.date);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_on_outlined, size: 16.sp, color: Colors.white70),
              SizedBox(width: 4.w),
              Flexible(
                child: Text(
                  location?.name ?? '—',
                  style: TextStyle(color: Colors.white70, fontSize: 13.sp),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            '${PrayerTimeUtils.toBanglaDigits('${hijri.day}')} '
            '${hijri.monthNameBangla} '
            '${PrayerTimeUtils.toBanglaDigits('${hijri.year}')} হিজরি',
            style: TextStyle(color: Colors.white, fontSize: 15.sp),
          ),
          if (next != null) ...[
            SizedBox(height: 16.h),
            Text(
              'পরবর্তী ${next!.prayer.bangla}',
              style: TextStyle(color: Colors.white70, fontSize: 13.sp),
            ),
            SizedBox(height: 4.h),
            // FR-N-16 — live countdown, updating once per second.
            Text(
              next!.remainingBangla,
              style: TextStyle(
                color: Colors.white,
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ApproximateWarning extends StatelessWidget {
  const _ApproximateWarning();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              'অবস্থান পাওয়া যায়নি, ঢাকার সময় দেখানো হচ্ছে। '
              'সঠিক সময়ের জন্য সেটিংস থেকে আপনার শহর নির্বাচন করুন।',
              style: TextStyle(fontSize: 13.sp, height: 1.5, color: AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.emoji, required this.text});

  final String emoji;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          children: [
            Text(emoji, style: TextStyle(fontSize: 44.sp)),
            SizedBox(height: 16.h),
            Text(
              text,
              style: TextStyle(fontSize: 15.sp, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
