import 'package:amol365/app/router/app_routes.dart';
import 'package:amol365/app/shell/main_shell.dart';
import 'package:amol365/app/shell/widgets/bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const designSize = Size(390, 844);

  /// `MainShell.tabs` and `AppBottomNavBar.items` are two lists in two files
  /// joined only by index. Getting them out of step routes taps to the wrong
  /// screen and nothing catches it at compile time, so it is pinned here.
  group('tab wiring', () {
    testWidgets('every nav item has a matching route', (tester) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: designSize,
          builder: (_, _) => MaterialApp(
            home: Scaffold(
              bottomNavigationBar:
                  AppBottomNavBar(currentIndex: 0, onTap: (_) {}),
            ),
          ),
        ),
      );

      final bar = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );

      expect(bar.items.length, MainShell.tabs.length,
          reason: 'a label without a route sends taps to the wrong screen');
    });

    testWidgets('labels sit in the same order as their routes',
        (tester) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: designSize,
          builder: (_, _) => MaterialApp(
            home: Scaffold(
              bottomNavigationBar:
                  AppBottomNavBar(currentIndex: 0, onTap: (_) {}),
            ),
          ),
        ),
      );

      final bar = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );

      const expected = {
        AppRoutes.home: 'হোম',
        AppRoutes.prayerTime: 'নামাজ',
        AppRoutes.amalTracker: 'আমল',
        AppRoutes.profile: 'প্রোফাইল',
      };

      for (var i = 0; i < MainShell.tabs.length; i++) {
        expect(bar.items[i].label, expected[MainShell.tabs[i]],
            reason: 'index $i: ${MainShell.tabs[i]} is mislabelled');
      }
    });

    test('holds four tabs', () {
      expect(MainShell.tabs, hasLength(4));
    });

    test('contains no duplicates', () {
      expect(MainShell.tabs.toSet(), hasLength(MainShell.tabs.length));
    });

    test('starts at home', () {
      // A shell whose first tab is not Home leaves the app with no obvious
      // way back.
      expect(MainShell.tabs.first, AppRoutes.home);
    });
  });
}
