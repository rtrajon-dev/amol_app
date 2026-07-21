import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../global_widgets/app_card.dart';

/// Streak and today's progress, above the checklist.
///
/// The streak leads. Completing today's items is the task; the streak is the
/// reason to bother — a number the user has built and does not want to break
/// motivates far better than a count of what remains.
class StreakBanner extends StatelessWidget {
  const StreakBanner({
    super.key,
    required this.streak,
    required this.completedCount,
    required this.totalCount,
  });

  final int streak;
  final int completedCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final progress = totalCount > 0 ? completedCount / totalCount : 0.0;
    final isComplete = totalCount > 0 && completedCount >= totalCount;

    return GradientCard(
      padding: const EdgeInsets.all(Space.xl),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: Radii.mdAll,
                ),
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  color: AppColors.accent300,
                  size: 26,
                ),
              ),
              const SizedBox(width: Space.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ধারাবাহিক আমল',
                      style: AppType.labelSmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.78),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          BanglaNumerals.from(streak),
                          style:
                              AppType.displayMedium.copyWith(color: Colors.white),
                        ),
                        const SizedBox(width: Space.sm),
                        Text(
                          'দিন',
                          style: AppType.body.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.xl),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'আজ সম্পন্ন',
                style: AppType.labelSmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.78),
                ),
              ),
              Text(
                '${BanglaNumerals.from(completedCount)} / '
                '${BanglaNumerals.from(totalCount)}',
                style: AppType.label.copyWith(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: Space.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
              duration: Motion.slow,
              curve: Motion.curve,
              builder: (_, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 7,
                backgroundColor: Colors.white.withValues(alpha: 0.18),
                valueColor: AlwaysStoppedAnimation(
                  isComplete ? AppColors.accent300 : Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
