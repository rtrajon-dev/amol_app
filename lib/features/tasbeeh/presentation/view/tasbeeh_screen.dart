import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../global_widgets/loading_indicator.dart';
import '../../domain/models/tasbeeh_model.dart';
import '../viewmodel/tasbeeh_viewmodel.dart';
import '../widgets/tasbeeh_selector.dart';

class TasbeehScreen extends ConsumerWidget {
  const TasbeehScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(tasbeehProvider);
    final notifier = ref.read(tasbeehProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('তাসবিহ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => notifier.reset(),
            tooltip: 'রিসেট',
          ),
        ],
      ),
      body: asyncState.when(
        loading: () => const LoadingIndicator(),
        error: (_, _) => const Center(child: Text('তাসবিহ লোড করা যাচ্ছে না')),
        data: (state) => _TasbeehBody(state: state, notifier: notifier),
      ),
    );
  }
}

class _TasbeehBody extends StatelessWidget {
  const _TasbeehBody({required this.state, required this.notifier});

  final TasbeehState state;
  final TasbeehNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return Column(
        children: [
          TasbeehSelector(
            presets: TasbeehModel.presets,
            selected: state.selected,
            onSelect: notifier.select,
          ),
          const Spacer(),
          Text(
            state.selected.arabic,
            style: TextStyle(fontSize: 32.sp, fontFamily: 'Amiri', height: 2),
            textDirection: TextDirection.rtl,
          ),
          SizedBox(height: 8.h),
          Text(state.selected.bangla, style: TextStyle(fontSize: 16.sp, color: AppColors.textSecondary)),
          const Spacer(),
          Text(
            '${state.count}',
            style: TextStyle(fontSize: 80.sp, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
          Text('আজকের মোট: ${state.displayTotal}', style: TextStyle(fontSize: 13.sp, color: AppColors.textSecondary)),
          SizedBox(height: 8.h),
          LinearProgressIndicator(
            value: state.count / state.selected.target,
            backgroundColor: AppColors.primaryLight.withValues(alpha: 0.2),
            color: AppColors.primary,
            minHeight: 6,
          ),
          Text('লক্ষ্য: ${state.selected.target}', style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary)),
          const Spacer(),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              notifier.increment();
            },
            child: Container(
              width: 160.w,
              height: 160.w,
              margin: EdgeInsets.only(bottom: 40.h),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
                boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 20, spreadRadius: 4)],
              ),
              child: Icon(Icons.add, color: Colors.white, size: 48.sp),
            ),
          ),
        ],
    );
  }
}
