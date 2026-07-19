import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/app_colors.dart';

/// Shown only while the local session is being read (AuthStatus.unknown).
///
/// That read is a keystore call, not a network call, so this is typically a
/// single frame — it exists to prevent Login flashing before the app knows the
/// user is already signed in (NFR-A-01, FR-G-08).
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🕌', style: TextStyle(fontSize: 64.sp)),
            SizedBox(height: 20.h),
            Text(
              'ইসলামিক আমল',
              style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 28.h),
            SizedBox(
              width: 24.w,
              height: 24.w,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
