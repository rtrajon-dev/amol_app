import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../global_widgets/loading_indicator.dart';
import '../viewmodel/qibla_viewmodel.dart';
import '../widgets/qibla_compass.dart';

class QiblaScreen extends ConsumerWidget {
  const QiblaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qiblaAsync = ref.watch(qiblaProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('কিবলা দিকনির্দেশনা')),
      body: qiblaAsync.when(
        loading: () => const LoadingIndicator(),
        error: (_, _) => const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'অবস্থান পাওয়া যাচ্ছে না। কিবলা নির্ণয়ের জন্য অবস্থান প্রয়োজন।',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (state) => _QiblaBody(state: state),
      ),
    );
  }
}

class _QiblaBody extends StatelessWidget {
  const _QiblaBody({required this.state});

  final QiblaState state;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      child: Column(
        children: [
          _LocationLine(state: state),
          SizedBox(height: 24.h),
          QiblaCompass(state: state),
          SizedBox(height: 24.h),
          _BearingReadout(state: state),
          SizedBox(height: 16.h),
          _StatusMessage(state: state),
        ],
      ),
    );
  }
}

class _LocationLine extends StatelessWidget {
  const _LocationLine({required this.state});

  final QiblaState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_on_outlined,
                size: 16.sp, color: AppColors.textSecondary),
            SizedBox(width: 4.w),
            Flexible(
              child: Text(
                state.location.name,
                style:
                    TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        // FR-N-03 / G-06 — never present a guessed location as if it were
        // known. A wrong position means a wrong Qibla.
        if (state.location.isApproximate) ...[
          SizedBox(height: 6.h),
          Text(
            'আনুমানিক অবস্থান — সঠিক দিকের জন্য শহর নির্বাচন করুন',
            style: TextStyle(fontSize: 11.sp, color: AppColors.warning),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

class _BearingReadout extends StatelessWidget {
  const _BearingReadout({required this.state});

  final QiblaState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '${state.qiblaBearing.toStringAsFixed(1)}°',
          style: TextStyle(
            fontSize: 34.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        Text(
          'উত্তর থেকে কিবলার কোণ',
          style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _StatusMessage extends StatelessWidget {
  const _StatusMessage({required this.state});

  final QiblaState state;

  @override
  Widget build(BuildContext context) {
    final (message, color, icon) = _status();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18.sp, color: color),
          SizedBox(width: 8.w),
          Flexible(
            child: Text(
              message,
              style: TextStyle(fontSize: 12.5.sp, color: color),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  (String, Color, IconData) _status() {
    if (!state.hasHeading) {
      // Either the device has no magnetometer or the reading is unusable.
      // Say so, rather than leaving a needle pointing confidently at nothing.
      return (
        'কম্পাস পাওয়া যাচ্ছে না — উপরের কোণ অনুযায়ী দিক ঠিক করুন',
        AppColors.textSecondary,
        Icons.explore_off_outlined,
      );
    }

    if (state.hasInterference) {
      return (
        'চৌম্বকীয় বাধা — ফোনটি ধাতব বস্তু থেকে দূরে সরান',
        AppColors.warning,
        Icons.warning_amber_rounded,
      );
    }

    if (state.isAligned) {
      return (
        'কিবলার দিকে মুখ করা হয়েছে',
        AppColors.success,
        Icons.check_circle_outline,
      );
    }

    return (
      'ফোনটি ঘুরিয়ে তীরটি উপরের দিকে আনুন',
      AppColors.textSecondary,
      Icons.rotate_right,
    );
  }
}
