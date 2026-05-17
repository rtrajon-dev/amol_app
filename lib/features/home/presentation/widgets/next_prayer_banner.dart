import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../features/prayer_time/domain/models/prayer_time_model.dart';

class NextPrayerBanner extends StatelessWidget {
  const NextPrayerBanner({super.key, this.prayerTimes});
  final PrayerTimesModel? prayerTimes;

  @override
  Widget build(BuildContext context) {
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
          Text(
            prayerTimes != null ? 'পরবর্তী: ${prayerTimes!.nextPrayerName}' : 'নামাজের সময় লোড হচ্ছে...',
            style: TextStyle(color: Colors.white, fontSize: 13.sp),
          ),
          if (prayerTimes != null) ...[
            const Spacer(),
            Text(prayerTimes!.nextPrayerTime, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15.sp)),
          ],
        ],
      ),
    );
  }
}
