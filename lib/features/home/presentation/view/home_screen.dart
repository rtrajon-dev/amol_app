import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../global_widgets/section_header.dart';
import '../viewmodel/home_viewmodel.dart';
import '../widgets/next_prayer_banner.dart';
import '../widgets/amal_summary_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(homeViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180.h,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primaryDark, AppColors.primary],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('আস-সালামু আলাইকুম', style: TextStyle(color: Colors.white70, fontSize: 13.sp)),
                        SizedBox(height: 4.h),
                        Text('ইসলামিক আমল', style: TextStyle(color: Colors.white, fontSize: 24.sp, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        NextPrayerBanner(prayerTimes: vm.todayPrayerTimes),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.all(16.w),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                AmalSummaryCard(completedCount: vm.completedAmalCount, totalCount: vm.totalAmalCount),
                SizedBox(height: 20.h),
                SectionHeader(title: 'দ্রুত অ্যাক্সেস', actionLabel: 'সব দেখুন', onAction: () {}),
                SizedBox(height: 12.h),
                _QuickAccessGrid(),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAccessGrid extends StatelessWidget {
  final _items = const [
    _QuickItem(icon: Icons.access_time, label: 'নামাজের সময়', route: AppRoutes.prayerTime, color: AppColors.fajr),
    _QuickItem(icon: Icons.explore_outlined, label: 'কিবলা', route: AppRoutes.qibla, color: AppColors.success),
    _QuickItem(icon: Icons.menu_book_outlined, label: 'হাদিস', route: AppRoutes.hadith, color: AppColors.warning),
    _QuickItem(icon: Icons.loop, label: 'তাসবিহ', route: AppRoutes.tasbeeh, color: AppColors.primaryLight),
    _QuickItem(icon: Icons.book_outlined, label: 'সূরা', route: AppRoutes.surah, color: AppColors.accent),
    _QuickItem(icon: Icons.calendar_month_outlined, label: 'ক্যালেন্ডার', route: AppRoutes.islamicCalendar, color: AppColors.asr),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12.w,
      mainAxisSpacing: 12.h,
      childAspectRatio: 1,
      children: _items.map((item) => _QuickAccessTile(item: item)).toList(),
    );
  }
}

class _QuickItem {
  final IconData icon;
  final String label;
  final String route;
  final Color color;
  const _QuickItem({required this.icon, required this.label, required this.route, required this.color});
}

class _QuickAccessTile extends StatelessWidget {
  const _QuickAccessTile({required this.item});
  final _QuickItem item;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go(item.route),
      child: Card(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon, color: item.color, size: 32.sp),
            SizedBox(height: 8.h),
            Text(item.label, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
