import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/app_colors.dart';
import '../viewmodel/amal_tracker_viewmodel.dart';
import '../widgets/amal_check_item.dart';
import '../widgets/streak_banner.dart';

class AmalTrackerScreen extends ConsumerWidget {
  const AmalTrackerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(amalTrackerProvider);
    final notifier = ref.read(amalTrackerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('আজকের আমল'),
        actions: [
          TextButton(
            onPressed: notifier.resetDay,
            child: const Text('রিসেট', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Column(
        children: [
          StreakBanner(streak: state.streak, completedCount: state.completedCount, totalCount: state.totalCount),
          if (state.allCompleted)
            Container(
              margin: EdgeInsets.all(16.w),
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, color: AppColors.success),
                  SizedBox(width: 8.w),
                  const Text('মাশাআল্লাহ! আজকের সব আমল সম্পন্ন', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              itemCount: state.items.length,
              itemBuilder: (_, i) => AmalCheckItem(
                item: state.items[i],
                onToggle: () => notifier.toggle(state.items[i].id),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
