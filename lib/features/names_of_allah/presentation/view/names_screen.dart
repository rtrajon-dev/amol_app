import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/app_colors.dart';

class NamesScreen extends StatelessWidget {
  const NamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('আল্লাহর ৯৯ নাম')),
      body: GridView.builder(
        padding: EdgeInsets.all(16.w),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12.w,
          mainAxisSpacing: 12.h,
          childAspectRatio: 1.2,
        ),
        itemCount: 99,
        itemBuilder: (_, i) => Card(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${i + 1}', style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary)),
                Text('আরবি নাম', style: TextStyle(fontFamily: 'Amiri', fontSize: 18.sp, color: AppColors.primary, height: 1.8)),
                Text('বাংলা অর্থ', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
        // TODO: load from assets/data/names_of_allah.json
      ),
    );
  }
}
