import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/utils/hijri_utils.dart';
import '../../../../app/utils/prayer_time_utils.dart';
import '../../../prayer_time/presentation/viewmodel/prayer_time_viewmodel.dart';

/// The home header: greeting, both dates, and the next prayer countdown.
///
/// This is the screen's centre of gravity. A user opening the app between
/// prayers wants one number — how long until the next one — and the layout
/// makes that the largest thing on the display rather than burying it in a
/// row of equals.
class HomeHero extends ConsumerWidget {
  const HomeHero({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final next = ref.watch(nextPrayerProvider).value;
    final hijri = HijriDate.now();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient:
            isLight ? AppColors.heroGradient : AppColors.heroGradientDark,
        borderRadius: Radii.bottomXl,
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Space.xl,
            Space.md,
            Space.xl,
            Space.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'আস-সালামু আলাইকুম',
                style: AppType.bodySmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.72),
                ),
              ),
              const SizedBox(height: Space.xs),
              Text(
                'ইসলামিক আমল',
                style: AppType.h1.copyWith(color: Colors.white),
              ),
              const SizedBox(height: Space.md),

              // Both calendars. A Bangladeshi user thinks in Gregorian for
              // daily life and Hijri for worship, and needs no translation
              // step between them.
              Row(
                children: [
                  _DateChip(
                    icon: Icons.calendar_today_rounded,
                    label: PrayerTimeUtils.formatDateBangla(DateTime.now()),
                  ),
                  const SizedBox(width: Space.sm),
                  Flexible(
                    child: _DateChip(
                      icon: Icons.nights_stay_outlined,
                      label: '${BanglaNumerals.from(hijri.day)} '
                          '${hijri.monthNameBangla}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Space.xl),

              _NextPrayerBlock(next: next),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.md,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: Radii.smAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white.withValues(alpha: 0.85)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppType.labelSmall.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _NextPrayerBlock extends StatelessWidget {
  const _NextPrayerBlock({required this.next});

  final NextPrayerState? next;

  @override
  Widget build(BuildContext context) {
    if (next == null) {
      // Same height as the loaded state, so the hero does not resize under the
      // user's thumb the moment prayer times resolve.
      return SizedBox(
        height: 78,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'নামাজের সময় লোড হচ্ছে…',
            style: AppType.body.copyWith(
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
        ),
      );
    }

    final prayer = next!.prayer;

    return SizedBox(
      height: 78,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'পরবর্তী নামাজ · ${prayer.bangla}',
                  style: AppType.labelSmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.78),
                  ),
                ),
                const SizedBox(height: Space.xs),
                // The one number the screen exists to show.
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    next!.remainingBangla,
                    style: AppType.displayMedium.copyWith(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: Space.md),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Space.md,
              vertical: Space.sm,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: Radii.mdAll,
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: Text(
              PrayerTimeUtils.formatBangla(prayer.time),
              style: AppType.h3.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
