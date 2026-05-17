import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/app_colors.dart';

class QiblaScreen extends StatelessWidget {
  const QiblaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('কিবলা দিকনির্দেশনা')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.explore, size: 120.sp, color: AppColors.primary),
            SizedBox(height: 24.h),
            Text('কিবলা কম্পাস', style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 8.h),
            Text('sensors_plus দিয়ে কম্পাস ইমপ্লিমেন্ট করতে হবে', style: TextStyle(fontSize: 13.sp, color: AppColors.textSecondary), textAlign: TextAlign.center),
            // TODO: implement compass with sensors_plus + adhan qibla bearing
          ],
        ),
      ),
    );
  }
}
