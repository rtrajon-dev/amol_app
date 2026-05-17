import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/app_colors.dart';
import '../../domain/models/amal_item_model.dart';

class AmalCheckItem extends StatelessWidget {
  const AmalCheckItem({super.key, required this.item, required this.onToggle});
  final AmalItemModel item;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 8.h),
      child: ListTile(
        leading: GestureDetector(
          onTap: onToggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 28.w,
            height: 28.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: item.isCompleted ? AppColors.success : Colors.transparent,
              border: Border.all(color: item.isCompleted ? AppColors.success : AppColors.textSecondary, width: 2),
            ),
            child: item.isCompleted ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
          ),
        ),
        title: Text(
          item.title,
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.w500,
            decoration: item.isCompleted ? TextDecoration.lineThrough : null,
            color: item.isCompleted ? AppColors.textSecondary : null,
          ),
        ),
        subtitle: Text(item.subtitle, style: TextStyle(fontSize: 12.sp)),
        trailing: item.isPremium ? Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
          decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
          child: Text('প্রিমিয়াম', style: TextStyle(fontSize: 10.sp, color: AppColors.accent, fontWeight: FontWeight.bold)),
        ) : null,
      ),
    );
  }
}
