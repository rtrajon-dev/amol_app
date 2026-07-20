import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router/app_routes.dart';
import 'widgets/bottom_nav_bar.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  /// Four tabs, ordered by daily frequency.
  ///
  /// This list is positionally coupled to `AppBottomNavBar.items` — index N
  /// here must be the item at index N there. Editing one without the other
  /// routes taps to the wrong screen, and nothing catches it at compile time.
  ///
  /// তাসবিহ and রমজান moved to the home grid: tasbeeh is used in sessions
  /// rather than constantly, and Ramadan is relevant about thirty days a year,
  /// which is a poor use of a permanent slot.
  static const tabs = [
    AppRoutes.home,
    AppRoutes.prayerTime,
    AppRoutes.amalTracker,
    AppRoutes.profile,
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final currentIndex = _tabIndexFor(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: currentIndex < 0 ? 0 : currentIndex,
        onTap: (i) => context.go(tabs[i]),
      ),
    );
  }

  int _tabIndexFor(String path) => tabs.indexWhere((t) => path == t);
}
