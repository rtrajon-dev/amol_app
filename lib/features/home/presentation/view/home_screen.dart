import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/config/feature_flags.dart';
import '../../../../app/di/providers.dart';
import '../../../../app/di/subscription_notice.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../global_widgets/app_card.dart';
import '../../../../features/amal_tracker/presentation/viewmodel/amal_tracker_viewmodel.dart';
import '../../../../features/prayer_time/presentation/viewmodel/prayer_time_viewmodel.dart';
import '../../../../app/utils/hijri_utils.dart';
import '../../../../global_widgets/section_header.dart';
import '../viewmodel/home_viewmodel.dart';
import '../widgets/amal_summary_card.dart';
import '../widgets/home_hero.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();

    // M-5 / FR-C-07 — content sync is attempted here, after the first frame,
    // rather than in bootstrap(): FR-G-08 keeps network work off the launch
    // path. The service itself decides whether a run is due, so calling this
    // on every visit to Home costs nothing.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(ref.read(contentSyncServiceProvider).maybeSync());
      _announceSubscriptionNotice();
    });
  }

  /// Closes the loop on whatever just happened with the subscription.
  ///
  /// Two things can bring a user here: they subscribed through the gate, or the
  /// number they registered with was already paying. Both deserve saying, and
  /// neither can be said by the screen that learned it — the router replaces
  /// the gate and the registration screen the instant entitlement flips.
  void _announceSubscriptionNotice() {
    // take() consumes it, so it appears once rather than on every visit Home.
    final notice = ref.read(subscriptionNoticeProvider.notifier).take();

    final message = switch (notice) {
      SubscriptionNotice.none => null,
      // Covers INITIAL CHARGING PENDING. The subscription is taken out and
      // bdapps debits the number automatically each day from here, so there is
      // nothing provisional to warn them about.
      SubscriptionNotice.activated =>
        'অভিনন্দন! আপনার সাবস্ক্রিপশন চালু হয়েছে।',
      SubscriptionNotice.recognised =>
        'আপনার সাবস্ক্রিপশন সক্রিয় আছে — নতুন করে চার্জ হয়নি।',
    };

    if (message == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(homeViewModelProvider);
    final isLight = Theme.of(context).brightness == Brightness.light;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // The hero is dark in both themes, so the status bar icons above it must
      // be light in both — the theme-level default would make them invisible.
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: isLight
            ? AppColors.backgroundLight
            : AppColors.backgroundDark,
        body: RefreshIndicator(
          onRefresh: () async {
            // Prayer times are location- and clock-derived, so a pull is the
            // natural gesture for "I have moved" or "this looks stale".
            ref.invalidate(prayerTimesProvider);
            ref.invalidate(amalTrackerProvider);
            await Future<void>.delayed(Motion.slow);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              const SliverToBoxAdapter(child: HomeHero()),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  Space.lg,
                  Space.xl,
                  Space.lg,
                  Space.xxxl,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    AmalSummaryCard(
                      completedCount: vm.completedAmalCount,
                      totalCount: vm.totalAmalCount,
                      streak: vm.streak,
                      // go, not push: Amal is a TAB, so this switches branch
                      // rather than stacking a second copy on top of Home.
                      onTap: () => context.go(AppRoutes.amalTracker),
                    ),
                    const SizedBox(height: Space.xxl),
                    const SectionHeader(title: 'দ্রুত অ্যাক্সেস'),
                    const SizedBox(height: Space.lg),
                    const _QuickAccessGrid(),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAccessGrid extends ConsumerWidget {
  const _QuickAccessGrid();

  /// Everything not in the bottom nav has to be reachable from here.
  ///
  /// Two columns rather than three: five destinations in a three-wide grid
  /// leaves a ragged last row, and wider tiles give Bangla labels room to sit
  /// on one line.
  ///
  /// নামাজের সময় is deliberately absent — it is a permanent tab, so a tile
  /// would spend a slot on a screen that is always one tap away.
  static const _items = [
    _QuickItem(
      icon: Icons.explore_outlined,
      label: 'কিবলা',
      route: AppRoutes.qibla,
      color: AppColors.primary500,
    ),
    _QuickItem(
      icon: Icons.radio_button_checked,
      label: 'তাসবিহ',
      route: AppRoutes.tasbeeh,
      color: AppColors.fajr,
    ),
    _QuickItem(
      icon: Icons.calendar_month_outlined,
      label: 'ক্যালেন্ডার',
      route: AppRoutes.islamicCalendar,
      color: AppColors.asr,
    ),
    _QuickItem(
      icon: Icons.auto_awesome_outlined,
      label: '৯৯ নাম',
      route: AppRoutes.namesOfAllah,
      color: AppColors.maghrib,
    ),
    // Phase 2. They join the grid automatically when their flags are raised.
    _QuickItem(
      icon: Icons.menu_book_outlined,
      label: 'হাদিস',
      route: AppRoutes.hadith,
      color: AppColors.warning,
    ),
    _QuickItem(
      icon: Icons.book_outlined,
      label: 'সূরা',
      route: AppRoutes.surah,
      color: AppColors.isha,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // FR-PH-07 — a withheld feature leaves no tile behind. The grid reflows to
    // fill the gap rather than showing a hole where the feature used to be.
    final flags = ref.watch(featureFlagsProvider);
    final visible =
        _items.where((i) => !flags.isRouteWithheld(i.route)).toList();

    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: visible.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: Space.md,
            mainAxisSpacing: Space.md,
            // Wide and short: a two-column tile has room for the icon and
            // label side by side, so it does not need a square's height.
            childAspectRatio: 2.1,
          ),
          itemBuilder: (_, i) => _QuickAccessTile(item: visible[i]),
        ),
        const SizedBox(height: Space.md),
        // Ramadan sits alone, full width, flagged as seasonal. It is relevant
        // about thirty days a year, and a tile that looks identical to the
        // others implies it is useful today when usually it is not.
        const _RamadanTile(),
      ],
    );
  }
}

/// Full-width Ramadan entry, labelled by where the Hijri year actually is.
class _RamadanTile extends StatelessWidget {
  const _RamadanTile();

  static const _ramadanMonth = 9;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final hijri = HijriDate.now();
    final isRamadan = hijri.month == _ramadanMonth;

    return AppCard(
      padding: const EdgeInsets.all(Space.lg),
      onTap: () {
        HapticFeedback.selectionClick();
        context.push(AppRoutes.ramadan);
      },
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.accent500
                  .withValues(alpha: isLight ? 0.11 : 0.20),
              borderRadius: Radii.mdAll,
            ),
            child: const Icon(
              Icons.nightlight_round,
              color: AppColors.accent500,
              size: 21,
            ),
          ),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'রমজান',
                  style: AppType.h3.copyWith(color: theme.colorScheme.onSurface),
                ),
                const SizedBox(height: 2),
                Text(
                  isRamadan
                      ? 'সেহরি, ইফতার ও রমজানের আমল'
                      : 'রমজান মাসে সক্রিয় হবে',
                  style: AppType.bodySmall
                      .copyWith(color: theme.colorScheme.onSurfaceVariant),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: Space.sm),
          _SeasonBadge(isActive: isRamadan),
        ],
      ),
    );
  }
}

class _SeasonBadge extends StatelessWidget {
  const _SeasonBadge({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.success : AppColors.accent700;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Space.sm, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: Radii.smAll,
      ),
      child: Text(
        isActive ? 'চলছে' : 'মৌসুমি',
        style: AppType.labelSmall.copyWith(color: color),
      ),
    );
  }
}

class _QuickItem {
  const _QuickItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String route;
  final Color color;
}

class _QuickAccessTile extends StatelessWidget {
  const _QuickAccessTile({required this.item});

  final _QuickItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return AppCard(
      padding: const EdgeInsets.all(Space.md),
      onTap: () {
        HapticFeedback.selectionClick();
        // push, not go: these are drill-downs within the Home branch, so back
        // must return here. `go` replaces the stack, which left nothing to pop
        // and closed the app on the next back press.
        context.push(item.route);
      },
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              // A tinted plate gives each tile the same optical weight
              // regardless of how dense its glyph is.
              color: item.color.withValues(alpha: isLight ? 0.11 : 0.20),
              borderRadius: Radii.mdAll,
            ),
            child: Icon(item.icon, color: item.color, size: 20),
          ),
          const SizedBox(width: Space.md),
          Expanded(
            child: Text(
              item.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppType.label.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
