import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../global_widgets/primary_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  final _pages = const [
    _OnboardingData(
      emoji: '🕌',
      title: 'নামাজের সময়সূচী',
      subtitle: 'আপনার অবস্থান অনুযায়ী সঠিক নামাজের সময় এবং আযানের রিমাইন্ডার পান',
    ),
    _OnboardingData(
      emoji: '📿',
      title: 'তাসবিহ কাউন্টার',
      subtitle: 'ডিজিটাল তাসবিহ দিয়ে যিকির করুন এবং আপনার প্রতিদিনের আমল ট্র্যাক করুন',
    ),
    _OnboardingData(
      emoji: '📖',
      title: 'দোয়া ও আমল',
      subtitle: 'বাংলায় দোয়া, হাদিস এবং দৈনন্দিন আমলের সম্পূর্ণ সংকলন',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (_, i) => _OnboardingPage(data: _pages[i]),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: EdgeInsets.symmetric(horizontal: 4.w),
                width: _currentPage == i ? 20.w : 8.w,
                height: 8.h,
                decoration: BoxDecoration(
                  color: _currentPage == i ? AppColors.primary : AppColors.primary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              )),
            ),
            SizedBox(height: 32.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: PrimaryButton(
                label: _currentPage == _pages.length - 1 ? 'শুরু করুন' : 'পরবর্তী',
                onPressed: () {
                  if (_currentPage < _pages.length - 1) {
                    _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                  } else {
                    context.go(AppRoutes.home);
                  }
                },
              ),
            ),
            SizedBox(height: 16.h),
            TextButton(
              onPressed: () => context.go(AppRoutes.home),
              child: Text('এড়িয়ে যান', style: TextStyle(color: AppColors.textSecondary, fontSize: 14.sp)),
            ),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }
}

class _OnboardingData {
  final String emoji;
  final String title;
  final String subtitle;
  const _OnboardingData({required this.emoji, required this.title, required this.subtitle});
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.data});
  final _OnboardingData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(32.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(data.emoji, style: TextStyle(fontSize: 80.sp)),
          SizedBox(height: 40.h),
          Text(data.title, style: TextStyle(fontSize: 26.sp, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          SizedBox(height: 16.h),
          Text(data.subtitle, style: TextStyle(fontSize: 16.sp, color: AppColors.textSecondary, height: 1.6), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
