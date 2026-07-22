import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/utils/hijri_utils.dart';
import '../../../../app/utils/prayer_time_utils.dart';
import '../../../../global_widgets/app_card.dart';
import '../../../../global_widgets/app_state_view.dart';
import '../../../../global_widgets/loading_indicator.dart';
import '../../domain/models/prayer_time_model.dart';
import '../viewmodel/prayer_time_viewmodel.dart';
import '../widgets/prayer_card.dart';

class PrayerTimeScreen extends ConsumerWidget {
  const PrayerTimeScreen({super.key});

  static const _icons = {
    PrayerSlot.fajr: Icons.wb_twilight,
    PrayerSlot.sunrise: Icons.wb_sunny_outlined,
    PrayerSlot.dhuhr: Icons.light_mode_rounded,
    PrayerSlot.asr: Icons.wb_cloudy_outlined,
    PrayerSlot.maghrib: Icons.nights_stay_outlined,
    PrayerSlot.isha: Icons.dark_mode_rounded,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timesAsync = ref.watch(prayerTimesProvider);
    final locationAsync = ref.watch(resolvedLocationProvider);
    final nextAsync = ref.watch(nextPrayerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('নামাজের সময়'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'আযান সেটিংস',
            onPressed: () => context.push(AppRoutes.azanSettings),
          ),
          const _LocationChip(),
          // Matches the title's leading inset, so the chip is not jammed
          // against the screen edge.
          const SizedBox(width: Space.lg),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(resolvedLocationProvider);
          await ref.read(prayerTimesProvider.future);
        },
        child: timesAsync.when(
          loading: () => const SkeletonList(itemCount: 6, itemHeight: 72),
          error: (_, _) => ListView(
            children: [
              SizedBox(height: MediaQuery.sizeOf(context).height * 0.15),
              AppStateView.error(
                title: 'সময় গণনা করা যায়নি',
                message: 'নিচে টেনে আবার চেষ্টা করুন, অথবা আপনার শহর '
                    'নির্বাচন করুন।',
                actionLabel: 'শহর নির্বাচন',
                onAction: () => context.push(AppRoutes.citySelector),
              ),
            ],
          ),
          data: (times) {
            final now = DateTime.now();
            final current = times.currentAt(now);

            return ListView(
              padding: const EdgeInsets.fromLTRB(
                Space.lg,
                Space.lg,
                Space.lg,
                Space.xxxl,
              ),
              children: [
                _CountdownHero(times: times, next: nextAsync.value),
                const SizedBox(height: Space.lg),

                // G-06 — when the location is a guess, say so. The original
                // build silently used Dhaka, so a user in Sylhet saw times
                // that were quietly wrong with no way to notice.
                if (locationAsync.value?.isApproximate ?? false) ...[
                  const _ApproximateWarning(),
                  const SizedBox(height: Space.lg),
                ],

                for (final prayer in times.prayers)
                  PrayerCard(
                    slot: prayer.slot,
                    name: prayer.bangla,
                    time: PrayerTimeUtils.formatBangla(prayer.time),
                    icon: _icons[prayer.slot] ?? Icons.access_time,
                    isCurrent: current?.slot == prayer.slot,
                    isNext: nextAsync.value?.prayer.slot == prayer.slot,
                    isPast: prayer.time.isBefore(now),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// The current location, in the app bar.
///
/// A bare pin icon told the user nothing: not where the times were computed
/// for, and not that it was tappable. Since a wrong location silently produces
/// wrong prayer times (G-06), the place has to be legible without scrolling.
///
/// Width is capped rather than left to grow. The longest district name here is
/// ব্রাহ্মণবাড়িয়া at sixteen characters, which on a 320pt screen would push
/// the screen title out of the bar entirely.
class _LocationChip extends ConsumerWidget {
  const _LocationChip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final location = ref.watch(resolvedLocationProvider).value;
    final isApproximate = location?.isApproximate ?? false;

    // Blue rather than the brand emerald. Emerald is the app's "primary
    // action" colour and appears on buttons, active tabs and the hero, so an
    // emerald chip would read as one more piece of chrome. Blue is the one
    // hue nothing else here uses, which is exactly what makes it findable.
    //
    // Amber overrides it when the position is a guess, matching the warning
    // card below so the two cannot disagree about whether to trust it.
    final color = isApproximate
        ? AppColors.warning
        : (isLight ? AppColors.info : AppColors.infoLight);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          // Wider than before because the text is larger. Still capped:
          // ব্রাহ্মণবাড়িয়া unbounded pushes the screen title out of the bar.
          maxWidth: MediaQuery.sizeOf(context).width * 0.42,
        ),
        child: Material(
          color: color.withValues(alpha: isLight ? 0.13 : 0.20),
          borderRadius: Radii.mdAll,
          child: InkWell(
            onTap: () => context.push(AppRoutes.citySelector),
            borderRadius: Radii.mdAll,
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: Radii.mdAll,
                // A border as well as a fill. On a white app bar a tint alone
                // is nearly invisible at a glance, which was the complaint.
                border: Border.all(color: color.withValues(alpha: 0.38)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Space.md,
                  vertical: Space.sm,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isApproximate
                          ? Icons.location_off_outlined
                          : Icons.location_on_rounded,
                      size: 18,
                      color: color,
                    ),
                    const SizedBox(width: Space.xs),
                    Flexible(
                      child: Text(
                        // Named while resolving rather than left blank: an
                        // empty chip reads as a broken control.
                        location?.name ?? 'অবস্থান…',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.label.copyWith(
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Hijri date and the live countdown.
///
/// The countdown is the reason this screen is opened between prayers, so it is
/// the largest element and everything else is context around it.
class _CountdownHero extends StatelessWidget {
  const _CountdownHero({required this.times, this.next});

  final PrayerTimesModel times;
  final NextPrayerState? next;

  @override
  Widget build(BuildContext context) {
    final hijri = HijriDate.fromGregorian(times.date);

    return GradientCard(
      child: Column(
        children: [
          // The location used to be repeated here. It now lives in the app bar,
          // where it is always visible instead of scrolling away, so this card
          // is left to do one job: the date and the countdown.
          Text(
            '${PrayerTimeUtils.toBanglaDigits('${hijri.day}')} '
            '${hijri.monthNameBangla} '
            '${PrayerTimeUtils.toBanglaDigits('${hijri.year}')} হিজরি',
            style: AppType.body.copyWith(color: Colors.white),
          ),
          if (next != null) ...[
            const SizedBox(height: Space.xl),
            Container(
              height: 1,
              color: Colors.white.withValues(alpha: 0.15),
            ),
            const SizedBox(height: Space.xl),
            Text(
              '${next!.prayer.bangla} শুরু হতে বাকি',
              style: AppType.labelSmall.copyWith(
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: Space.sm),
            // FR-N-16 — live, once per second. FittedBox because the string
            // grows from "৫ মিনিট" to "১১ ঘণ্টা ৫৯ মিনিট" across a day and
            // must not wrap or clip at either end.
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                next!.remainingBangla,
                style: AppType.displayMedium.copyWith(color: Colors.white),
              ),
            ),
            const SizedBox(height: Space.sm),
            Text(
              PrayerTimeUtils.formatBangla(next!.prayer.time),
              style: AppType.label.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ApproximateWarning extends StatelessWidget {
  const _ApproximateWarning();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.warning.withValues(alpha: 0.10),
      borderColor: AppColors.warning.withValues(alpha: 0.35),
      padding: const EdgeInsets.all(Space.md),
      onTap: () => context.push(AppRoutes.citySelector),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.warning,
            size: 20,
          ),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'আনুমানিক অবস্থান',
                  style: AppType.label.copyWith(color: AppColors.warning),
                ),
                const SizedBox(height: 2),
                Text(
                  'ঢাকার সময় দেখানো হচ্ছে। সঠিক সময়ের জন্য আপনার শহর '
                  'নির্বাচন করুন।',
                  style: AppType.bodySmall.copyWith(color: AppColors.warning),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.warning,
            size: 20,
          ),
        ],
      ),
    );
  }
}
