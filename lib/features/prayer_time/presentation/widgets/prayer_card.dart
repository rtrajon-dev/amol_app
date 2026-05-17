import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/app_colors.dart';

class PrayerCard extends StatelessWidget {
  const PrayerCard({super.key, required this.name, required this.time, required this.icon, this.isNext = false});

  final String name;
  final String time;
  final IconData icon;
  final bool isNext;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isNext ? AppColors.primary : null,
      margin: EdgeInsets.only(bottom: 10.h),
      child: ListTile(
        leading: Icon(icon, color: isNext ? Colors.white : AppColors.primary, size: 28.sp),
        title: Text(name, style: TextStyle(fontWeight: FontWeight.w600, color: isNext ? Colors.white : null)),
        trailing: Text(time, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: isNext ? Colors.white : AppColors.primary)),
      ),
    );
  }
}
