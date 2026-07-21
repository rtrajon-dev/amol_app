import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../router/app_routes.dart';
import 'widgets/bottom_nav_bar.dart';

/// The tabbed shell.
///
/// Driven by [StatefulNavigationShell], so each tab owns its navigation stack
/// and keeps its state across switches. The previous plain `ShellRoute` shared
/// one stack between every tab, which is what let `context.go` from the home
/// grid wipe the history and close the app on the next back press.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  /// Branch order. Positionally coupled to `AppBottomNavBar.items` AND to the
  /// branch order in `app_router.dart` — index N must mean the same tab in all
  /// three. Nothing catches a mismatch at compile time, so `navigation_test`
  /// pins it.
  static const tabs = [
    AppRoutes.home,
    AppRoutes.prayerTime,
    AppRoutes.amalTracker,
    AppRoutes.profile,
  ];

  static const _homeBranch = 0;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Handled below rather than by the framework, so back can move between
      // branches instead of only in or out of the app.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBack(context);
      },
      child: Scaffold(
        body: navigationShell,
        bottomNavigationBar: AppBottomNavBar(
          currentIndex: navigationShell.currentIndex,
          onTap: _onTap,
        ),
      ),
    );
  }

  /// Android's three-level back convention, which most apps implement only the
  /// first and third of:
  ///
  ///  1. a screen pushed inside a tab pops back within that tab
  ///  2. at a tab's root, back returns to Home rather than exiting — this is
  ///     the step usually missed, and it is why users report "back closed the
  ///     app" after tapping a tab
  ///  3. at Home's root, back exits
  void _handleBack(BuildContext context) {
    // The branch's own Navigator gets first refusal; this only runs when it
    // has nothing left to pop.
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
      return;
    }

    if (navigationShell.currentIndex != _homeBranch) {
      navigationShell.goBranch(_homeBranch);
      return;
    }

    SystemNavigator.pop();
  }

  void _onTap(int index) {
    HapticFeedback.selectionClick();

    // Tapping the tab you are already on returns to that tab's root — the
    // standard "escape hatch" out of a deep stack, and the reason
    // `initialLocation` is set on a re-tap rather than a first tap.
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}
