import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../global_widgets/app_card.dart';

/// Today's amal progress.
///
/// A ring rather than a bar: the question being asked at a glance is "am I on
/// track", which is a proportion, and a circle reads as a proportion faster
/// than a line does. It also gives the count somewhere to live at full size
/// instead of being squeezed into a caption.
class AmalSummaryCard extends StatelessWidget {
  const AmalSummaryCard({
    super.key,
    required this.completedCount,
    required this.totalCount,
    this.streak = 0,
    this.onTap,
  });

  final int completedCount;
  final int totalCount;
  final int streak;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = totalCount > 0 ? completedCount / totalCount : 0.0;
    final isComplete = totalCount > 0 && completedCount >= totalCount;

    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          _ProgressRing(
            progress: progress,
            completed: completedCount,
            total: totalCount,
            isComplete: isComplete,
          ),
          const SizedBox(width: Space.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'আজকের আমল',
                  style:
                      AppType.h3.copyWith(color: theme.colorScheme.onSurface),
                ),
                const SizedBox(height: Space.xs),
                Text(
                  isComplete
                      ? 'মাশাআল্লাহ! সব সম্পন্ন'
                      : 'আরও ${BanglaNumerals.from(totalCount - completedCount)}টি বাকি',
                  style: AppType.bodySmall.copyWith(
                    color: isComplete
                        ? AppColors.success
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: isComplete ? FontWeight.w600 : null,
                  ),
                ),
                if (streak > 0) ...[
                  const SizedBox(height: Space.md),
                  _StreakBadge(days: streak),
                ],
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: theme.colorScheme.onSurfaceVariant,
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({
    required this.progress,
    required this.completed,
    required this.total,
    required this.isComplete,
  });

  final double progress;
  final int completed;
  final int total;
  final bool isComplete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isComplete ? AppColors.success : theme.colorScheme.primary;

    return SizedBox(
      width: 62,
      height: 62,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Animated, so ticking an item on the tracker screen is visible here
          // rather than the ring silently jumping on the next rebuild.
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
            duration: Motion.slow,
            curve: Motion.curve,
            builder: (_, value, _) => SizedBox(
              width: 62,
              height: 62,
              child: CircularProgressIndicator(
                value: value,
                strokeWidth: 5,
                strokeCap: StrokeCap.round,
                backgroundColor: theme.brightness == Brightness.light
                    ? AppColors.neutral200
                    : AppColors.neutral800,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                BanglaNumerals.from(completed),
                style: AppType.h2.copyWith(color: color, height: 1),
              ),
              Text(
                '/${BanglaNumerals.from(total)}',
                style: AppType.labelSmall.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Streak. Gold, because it is an achievement — one of only two places besides
/// premium where the accent is earned.
class _StreakBadge extends StatelessWidget {
  const _StreakBadge({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Space.sm, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accent500.withValues(alpha: 0.12),
        borderRadius: Radii.smAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_fire_department_rounded,
            size: 14,
            color: AppColors.accent700,
          ),
          const SizedBox(width: 4),
          Text(
            '${BanglaNumerals.from(days)} দিন ধারাবাহিক',
            style: AppType.labelSmall.copyWith(color: AppColors.accent700),
          ),
        ],
      ),
    );
  }
}
