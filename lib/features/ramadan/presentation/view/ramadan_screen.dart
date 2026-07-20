import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/utils/prayer_time_utils.dart';
import '../../../../global_widgets/loading_indicator.dart';
import '../viewmodel/ramadan_viewmodel.dart';

class RamadanScreen extends ConsumerWidget {
  const RamadanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ramadanAsync = ref.watch(ramadanProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('রমজান স্পেশাল')),
      body: ramadanAsync.when(
        loading: () => const LoadingIndicator(),
        error: (_, _) => const Center(child: Text('লোড করা যাচ্ছে না')),
        data: (state) => ListView(
          padding: EdgeInsets.all(16.w),
          children: [
            const _SehriIftarCard(),
            SizedBox(height: 16.h),
            _RamadanAmalList(state: state),
          ],
        ),
      ),
    );
  }
}

/// Sehri and iftar for the user's own location.
///
/// These were previously hardcoded to ৪:১৫ AM / ৬:৪৫ PM, which is a real
/// correctness problem rather than a cosmetic one: a user breaking their fast
/// on a fixed time that is earlier than their actual Maghrib breaks it early.
class _SehriIftarCard extends ConsumerWidget {
  const _SehriIftarCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timesAsync = ref.watch(sehriIftarProvider);

    return Card(
      color: AppColors.primaryDark,
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: timesAsync.when(
          loading: () => SizedBox(
            height: 74.h,
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white70),
            ),
          ),
          error: (_, _) => SizedBox(
            height: 74.h,
            child: Center(
              child: Text(
                'সময় লোড করা যাচ্ছে না',
                style: TextStyle(color: Colors.white70, fontSize: 13.sp),
              ),
            ),
          ),
          data: (times) => Row(
            children: [
              Expanded(
                child: _TimeColumn(
                  icon: Icons.nightlight,
                  // Sehri ENDS at Fajr. Labelling Fajr as plain "সেহরি" could
                  // be read as when to begin, which is the opposite of the
                  // deadline it actually is.
                  label: 'সেহরির শেষ সময়',
                  time: times.sehri,
                ),
              ),
              Container(width: 1, height: 60.h, color: Colors.white30),
              Expanded(
                child: _TimeColumn(
                  icon: Icons.wb_twilight,
                  label: 'ইফতার',
                  time: times.iftar,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeColumn extends StatelessWidget {
  const _TimeColumn({
    required this.icon,
    required this.label,
    required this.time,
  });

  final IconData icon;
  final String label;
  final DateTime? time;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 28),
        SizedBox(height: 6.h),
        Text(label,
            style: TextStyle(color: Colors.white70, fontSize: 12.sp),
            textAlign: TextAlign.center),
        Text(
          time == null ? '—' : PrayerTimeUtils.formatBangla(time!),
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _RamadanAmalList extends ConsumerWidget {
  const _RamadanAmalList({required this.state});

  final RamadanState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(ramadanProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('রমজানের আমল',
                style:
                    TextStyle(fontSize: 17.sp, fontWeight: FontWeight.bold)),
            Text(
              '${state.completedCount}/${state.totalCount}',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        if (state.daysObserved > 0) ...[
          SizedBox(height: 4.h),
          Text(
            '${state.daysObserved} দিন আমল করা হয়েছে',
            style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
          ),
        ],
        SizedBox(height: 12.h),
        ...state.items.map(
          (item) => CheckboxListTile(
            title: Text(item.title, style: TextStyle(fontSize: 14.sp)),
            value: item.isCompleted,
            activeColor: AppColors.primary,
            onChanged: (_) => notifier.toggle(item.id),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        if (state.allCompleted) ...[
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, color: AppColors.success),
                SizedBox(width: 8.w),
                Flexible(
                  child: Text(
                    'মাশাআল্লাহ! আজকের সব আমল সম্পন্ন',
                    style: TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                      fontSize: 13.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
