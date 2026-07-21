import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../global_widgets/app_state_view.dart';
import '../../../../global_widgets/loading_indicator.dart';
import '../viewmodel/amal_tracker_viewmodel.dart';
import '../widgets/amal_check_item.dart';
import '../widgets/streak_banner.dart';

class AmalTrackerScreen extends ConsumerWidget {
  const AmalTrackerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(amalTrackerProvider);
    final notifier = ref.read(amalTrackerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('আজকের আমল'),
        actions: [
          TextButton(
            onPressed: () => _confirmReset(context, notifier),
            child: const Text('রিসেট'),
          ),
          const SizedBox(width: Space.xs),
        ],
      ),
      body: asyncState.when(
        loading: () => const SkeletonList(itemCount: 6, itemHeight: 78),
        error: (_, _) => AppStateView.error(
          title: 'আমল লোড করা যাচ্ছে না',
          message: 'অ্যাপটি বন্ধ করে আবার খুলুন।',
        ),
        data: (state) => ListView(
          padding: const EdgeInsets.fromLTRB(
            Space.lg,
            Space.lg,
            Space.lg,
            Space.xxxl,
          ),
          children: [
            StreakBanner(
              streak: state.streak,
              completedCount: state.completedCount,
              totalCount: state.totalCount,
            ),
            const SizedBox(height: Space.xxl),
            if (state.allCompleted) ...[
              const _CompletionBanner(),
              const SizedBox(height: Space.lg),
            ],
            for (final item in state.items)
              AmalCheckItem(
                item: item,
                onToggle: () => notifier.toggle(item.id),
              ),
          ],
        ),
      ),
    );
  }

  /// Confirmed, because reset wipes a whole day of taps and the button sits in
  /// the app bar where it is easy to hit by accident.
  Future<void> _confirmReset(
    BuildContext context,
    AmalTrackerNotifier notifier,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('আজকের আমল রিসেট'),
        content: const Text(
          'আজ সম্পন্ন করা সব আমল মুছে যাবে। স্ট্রিকও প্রভাবিত হতে পারে।',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('থাক'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('রিসেট', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) await notifier.resetDay();
  }
}

class _CompletionBanner extends StatelessWidget {
  const _CompletionBanner();

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Space.lg),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: isLight ? 0.10 : 0.18),
        borderRadius: Radii.lgAll,
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_rounded, color: AppColors.success, size: 22),
          const SizedBox(width: Space.md),
          Expanded(
            child: Text(
              'মাশাআল্লাহ! আজকের সব আমল সম্পন্ন হয়েছে।',
              style: AppType.label.copyWith(color: AppColors.success),
            ),
          ),
        ],
      ),
    );
  }
}
