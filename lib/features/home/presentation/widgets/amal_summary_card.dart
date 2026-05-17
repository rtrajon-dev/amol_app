import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/app_colors.dart';

class AmalSummaryCard extends StatelessWidget {
  const AmalSummaryCard({super.key, required this.completedCount, required this.totalCount});

  final int completedCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final progress = totalCount > 0 ? completedCount / totalCount : 0.0;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('আজকের আমল', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                Text('$completedCount/$totalCount', style: TextStyle(fontSize: 14.sp, color: AppColors.primary, fontWeight: FontWeight.w600)),
              ],
            ),
            SizedBox(height: 12.h),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.primaryLight.withOpacity(0.2),
              color: AppColors.primary,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            SizedBox(height: 8.h),
            Text(
              progress >= 1.0 ? 'মাশাআল্লাহ! সব আমল সম্পন্ন ✓' : 'আরও ${totalCount - completedCount}টি আমল বাকি আছে',
              style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
