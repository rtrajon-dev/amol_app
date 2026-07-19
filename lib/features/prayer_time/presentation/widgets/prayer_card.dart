import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/app_colors.dart';

class PrayerCard extends StatelessWidget {
  const PrayerCard({
    super.key,
    required this.name,
    required this.time,
    required this.icon,
    this.isNext = false,
    this.isCurrent = false,
  });

  final String name;
  final String time;
  final IconData icon;

  /// The upcoming prayer.
  final bool isNext;

  /// FR-N-17 — the prayer whose waqt is currently active.
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final highlighted = isNext || isCurrent;

    return Card(
      color: isNext ? AppColors.primary : null,
      margin: EdgeInsets.only(bottom: 10.h),
      shape: isCurrent && !isNext
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.primary, width: 2),
            )
          : null,
      child: ListTile(
        leading: Icon(
          icon,
          color: isNext ? Colors.white : AppColors.primary,
          size: 28.sp,
        ),
        title: Text(
          name,
          style: TextStyle(
            fontWeight: highlighted ? FontWeight.bold : FontWeight.w600,
            color: isNext ? Colors.white : null,
          ),
        ),
        // NFR-08 — colour is never the only signal for the current waqt; a
        // text label carries the same information for colour-blind users and
        // in high-contrast modes.
        subtitle: isCurrent && !isNext
            ? Text(
                'এখন চলছে',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              )
            : (isNext
                ? Text(
                    'পরবর্তী',
                    style: TextStyle(fontSize: 12.sp, color: Colors.white70),
                  )
                : null),
        trailing: Text(
          time,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: isNext ? Colors.white : AppColors.primary,
          ),
        ),
      ),
    );
  }
}
