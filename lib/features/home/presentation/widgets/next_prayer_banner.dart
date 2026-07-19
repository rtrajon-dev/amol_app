import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/utils/prayer_time_utils.dart';
import '../../../prayer_time/presentation/viewmodel/prayer_time_viewmodel.dart';

/// FR-N-20 — the home banner reads from the SAME provider as the Namaz Time
/// screen. No duplicate computation, and the two can never disagree about when
/// the next prayer is.
class NextPrayerBanner extends ConsumerWidget {
  const NextPrayerBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final next = ref.watch(nextPrayerProvider).value;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.access_time, color: Colors.white70, size: 18),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              next == null
                  ? 'নামাজের সময় লোড হচ্ছে...'
                  : 'পরবর্তী: ${next.prayer.bangla} — ${next.remainingBangla}',
              style: TextStyle(color: Colors.white, fontSize: 13.sp),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (next != null)
            Text(
              PrayerTimeUtils.formatBangla(next.prayer.time),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15.sp,
              ),
            ),
        ],
      ),
    );
  }
}
