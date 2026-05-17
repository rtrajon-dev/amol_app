import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/app_colors.dart';

class StreakBanner extends StatelessWidget {
  const StreakBanner({super.key, required this.streak, required this.completedCount, required this.totalCount});

  final int streak;
  final int completedCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      margin: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.primaryDark, AppColors.primary]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ধারাবাহিক আমল', style: TextStyle(color: Colors.white70, fontSize: 12.sp)),
              SizedBox(height: 4.h),
              Row(
                children: [
                  Text('$streak', style: TextStyle(color: Colors.white, fontSize: 32.sp, fontWeight: FontWeight.bold)),
                  SizedBox(width: 4.w),
                  Text('দিন', style: TextStyle(color: Colors.white70, fontSize: 14.sp)),
                  SizedBox(width: 4.w),
                  const Text('🔥', style: TextStyle(fontSize: 20)),
                ],
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$completedCount/$totalCount', style: TextStyle(color: Colors.white, fontSize: 22.sp, fontWeight: FontWeight.bold)),
              Text('আমল সম্পন্ন', style: TextStyle(color: Colors.white70, fontSize: 12.sp)),
            ],
          ),
        ],
      ),
    );
  }
}
