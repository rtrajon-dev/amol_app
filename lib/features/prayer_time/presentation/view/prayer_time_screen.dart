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
import '../../data/services/prayer_time_service.dart';
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
          IconButton(
            icon: const Icon(Icons.location_on_outlined),
            tooltip: 'শহর নির্বাচন',
            onPressed: () => context.push(AppRoutes.citySelector),
          ),
          const SizedBox(width: Space.xs),
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
                _CountdownHero(
                  times: times,
                  location: locationAsync.value,
                  next: nextAsync.value,
                ),
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

/// Location, Hijri date, and the live countdown.
///
/// The countdown is the reason this screen is opened between prayers, so it is
/// the largest element and everything else is context around it.
class _CountdownHero extends StatelessWidget {
  const _CountdownHero({required this.times, this.location, this.next});

  final PrayerTimesModel times;
  final ResolvedLocation? location;
  final NextPrayerState? next;

  @override
  Widget build(BuildContext context) {
    final hijri = HijriDate.fromGregorian(times.date);

    return GradientCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 14,
                color: Colors.white.withValues(alpha: 0.75),
              ),
              const SizedBox(width: Space.xs),
              Flexible(
                child: Text(
                  location?.name ?? '—',
                  overflow: TextOverflow.ellipsis,
                  style: AppType.labelSmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.sm),
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
