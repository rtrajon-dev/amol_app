import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/app_colors.dart';

class SurahDetailScreen extends StatelessWidget {
  const SurahDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('সূরা #$id'),
        actions: [
          IconButton(icon: const Icon(Icons.text_fields), onPressed: () {/* font size */}),
          IconButton(icon: const Icon(Icons.bookmark_outline), onPressed: () {/* bookmark */}),
        ],
      ),
      body: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        itemCount: 10,
        itemBuilder: (_, i) => Container(
          margin: EdgeInsets.only(bottom: 12.h),
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: i % 2 == 0 ? AppColors.primary.withOpacity(0.04) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withOpacity(0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                Container(
                  padding: EdgeInsets.all(6.w),
                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(6)),
                  child: Text('${i + 1}', style: TextStyle(color: Colors.white, fontSize: 11.sp)),
                ),
              ]),
              SizedBox(height: 12.h),
              Text('آيَةٌ عَرَبِيَّةٌ', style: TextStyle(fontFamily: 'Amiri', fontSize: 22.sp, height: 2), textDirection: TextDirection.rtl, textAlign: TextAlign.right),
              SizedBox(height: 8.h),
              Text('বাংলা অনুবাদ এখানে দেখাবে', style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary, height: 1.6)),
            ],
          ),
        ),
        // TODO: load actual surah data from API or JSON asset
      ),
    );
  }
}
