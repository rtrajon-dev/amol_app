import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/config/feature_flags.dart';
import '../../../../app/di/providers.dart';
import '../../../../app/di/registration_coordinator.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../global_widgets/app_card.dart';
import '../../../../features/amal_tracker/presentation/viewmodel/amal_tracker_viewmodel.dart';
import '../../../../features/prayer_time/presentation/viewmodel/prayer_time_viewmodel.dart';
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
      _announceRecognisedSubscription();
    });
  }

  /// Tells a user who registered with an already-subscribed number that they
  /// were recognised — otherwise they land on Home and are left wondering
  /// whether they are about to be charged again.
  ///
  /// Shown here rather than on the registration screen because that screen is
  /// gone by the time the answer arrives.
  void _announceRecognisedSubscription() {
    if (!ref.read(subscriptionRecognisedProvider)) return;

    // Consume it, so it appears once rather than on every visit to Home.
    ref.read(subscriptionRecognisedProvider.notifier).set(false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('আপনার সাবস্ক্রিপশন সক্রিয় আছে — নতুন করে চার্জ হয়নি।'),
        duration: Duration(seconds: 4),
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
  /// নামাজের সময় is deliberately absent: it is a permanent tab, and a tile
  /// duplicating it would spend a grid slot on a screen that is always one tap
  /// away. তাসবিহ and রমজান moved here when the nav dropped to four.
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
      icon: Icons.nightlight_round,
      label: 'রমজান',
      route: AppRoutes.ramadan,
      color: AppColors.accent500,
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

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: visible.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: Space.md,
        mainAxisSpacing: Space.md,
        // Slightly taller than square: a Bangla label that wraps to two lines
        // has room, so the tile never clips at large system font sizes.
        childAspectRatio: 0.92,
      ),
      itemBuilder: (_, i) => _QuickAccessTile(item: visible[i]),
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              // A tinted plate rather than a bare icon: it gives each tile a
              // consistent optical weight regardless of how dense its glyph is.
              color: item.color.withValues(alpha: isLight ? 0.11 : 0.20),
              borderRadius: Radii.mdAll,
            ),
            child: Icon(item.icon, color: item.color, size: 21),
          ),
          const SizedBox(height: Space.sm),
          Flexible(
            child: Text(
              item.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppType.labelSmall.copyWith(
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
