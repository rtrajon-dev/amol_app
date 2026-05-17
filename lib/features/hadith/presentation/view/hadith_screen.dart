import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/app_colors.dart';

class HadithScreen extends StatelessWidget {
  const HadithScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('হাদিস')),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  children: [
                    Text('আজকের হাদিস', style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                    SizedBox(height: 16.h),
                    Text('আরবি হাদিস এখানে', style: TextStyle(fontFamily: 'Amiri', fontSize: 22.sp, height: 2), textDirection: TextDirection.rtl, textAlign: TextAlign.center),
                    SizedBox(height: 16.h),
                    Text('বাংলা অনুবাদ এখানে দেখাবে', style: TextStyle(fontSize: 15.sp, height: 1.6), textAlign: TextAlign.center),
                    SizedBox(height: 12.h),
                    Text('— সহিহ বুখারি', style: TextStyle(fontSize: 13.sp, color: AppColors.primary, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
            // TODO: load from assets/data/hadiths.json with daily rotation
          ],
        ),
      ),
    );
  }
}
