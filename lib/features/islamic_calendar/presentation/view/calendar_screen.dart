import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/utils/hijri_utils.dart';
import '../../domain/models/hijri_date_model.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final hijri = HijriDate.now();

    return Scaffold(
      appBar: AppBar(title: const Text('ইসলামিক ক্যালেন্ডার')),
      body: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          Card(
            color: AppColors.primary,
            child: Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                children: [
                  Text('আজকের হিজরি তারিখ', style: TextStyle(color: Colors.white70, fontSize: 13.sp)),
                  SizedBox(height: 8.h),
                  Text('${hijri.day} ${hijri.monthNameBangla} ${hijri.year}', style: TextStyle(color: Colors.white, fontSize: 28.sp, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4.h),
                  Text('${hijri.day} ${hijri.monthName} ${hijri.year} AH', style: TextStyle(color: Colors.white60, fontSize: 13.sp)),
                ],
              ),
            ),
          ),
          SizedBox(height: 20.h),
          Text('গুরুত্বপূর্ণ ইসলামিক দিবস', style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.bold)),
          SizedBox(height: 12.h),
          ...IslamicEvent.events.map((event) => ListTile(
                leading: const Icon(Icons.star, color: AppColors.accent),
                title: Text(event.nameBangla, style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w500)),
                subtitle: Text(
                  '${event.hijriDay} ${HijriDate.monthNamesBangla[event.hijriMonth - 1]}',
                  style: TextStyle(fontSize: 12.sp),
                ),
              )),
        ],
      ),
    );
  }
}
