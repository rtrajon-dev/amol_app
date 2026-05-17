import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/app_colors.dart';
import '../../domain/models/dua_model.dart';

class DuaCard extends StatelessWidget {
  const DuaCard({super.key, required this.dua, this.onTap});
  final DuaModel dua;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(dua.arabic, style: TextStyle(fontFamily: 'Amiri', fontSize: 20.sp, height: 1.8), textDirection: TextDirection.rtl, textAlign: TextAlign.right),
              SizedBox(height: 8.h),
              Text(dua.bangla, style: TextStyle(fontSize: 13.sp, color: AppColors.textSecondary, height: 1.5)),
              SizedBox(height: 8.h),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                    decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text(dua.category.banglaName, style: TextStyle(fontSize: 11.sp, color: AppColors.primary)),
                  ),
                  const Spacer(),
                  Text(dua.source, style: TextStyle(fontSize: 11.sp, color: AppColors.textSecondary)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
