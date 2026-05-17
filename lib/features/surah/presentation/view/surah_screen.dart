import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../domain/models/surah_model.dart';

class SurahScreen extends StatelessWidget {
  const SurahScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('সূরা সমূহ')),
      body: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: popularSurahs.length,
        itemBuilder: (_, i) {
          final surah = popularSurahs[i];
          return Card(
            margin: EdgeInsets.only(bottom: 10.h),
            child: ListTile(
              leading: Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Center(child: Text('${surah.number}', style: TextStyle(fontSize: 13.sp, color: AppColors.primary, fontWeight: FontWeight.bold))),
              ),
              title: Text(surah.banglaName, style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600)),
              subtitle: Text('${surah.verseCount} আয়াত · ${surah.revelationType}', style: TextStyle(fontSize: 12.sp)),
              trailing: Text(surah.arabicName, style: TextStyle(fontFamily: 'Amiri', fontSize: 20.sp, color: AppColors.primary)),
              onTap: () => context.go('/surah/${surah.number}'),
            ),
          );
        },
      ),
    );
  }
}
