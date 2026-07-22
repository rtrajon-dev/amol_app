import 'dart:io';

import 'package:amol365/app/config/feature_flags.dart';
import 'package:amol365/app/database/app_database.dart';
import 'package:amol365/app/di/providers.dart';
import 'package:amol365/app/services/storage_service.dart';
import 'package:amol365/app/theme/app_theme.dart';
import 'package:amol365/features/amal_tracker/presentation/view/amal_tracker_screen.dart';
import 'package:amol365/features/home/presentation/view/home_screen.dart';
import 'package:amol365/features/prayer_time/data/services/prayer_time_service.dart';
import 'package:amol365/features/prayer_time/presentation/view/prayer_time_screen.dart';
import 'package:amol365/features/prayer_time/presentation/viewmodel/prayer_time_viewmodel.dart';
import 'package:amol365/features/profile/presentation/view/profile_screen.dart';
import 'package:amol365/features/tasbeeh/presentation/view/tasbeeh_screen.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Renders each redesigned screen and asserts nothing overflows.
///
/// The real Kalpurush is loaded first, which is the point. `flutter_test`
/// otherwise substitutes a placeholder font whose glyphs are all identical
/// boxes, so Bangla measures far wider than it does on a device and every
/// layout appears to overflow — false failures that trained me to ignore real
/// ones earlier in this project. With the actual font loaded, an overflow here
/// is an overflow on the phone.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const phone = Size(390, 844);

  setUpAll(() async {
    final loader = FontLoader('Kalpurush')
      ..addFont(
        File('lib/assets/fonts/kalpurush.ttf')
            .readAsBytes()
            .then((b) => b.buffer.asByteData()),
      );
    await loader.load();

    final amiri = FontLoader('Amiri')
      ..addFont(
        File('lib/assets/fonts/Amiri-Regular.ttf')
            .readAsBytes()
            .then((b) => b.buffer.asByteData()),
      );
    await amiri.load();
  });

  late AppDatabase db;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.instance.init();
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  Future<void> render(
    WidgetTester tester,
    Widget screen, {
    Brightness brightness = Brightness.light,
    Size size = phone,
    ResolvedLocation? location,
  }) async {
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          appVersionProvider.overrideWithValue('0.0.0-test'),
          featureFlagsProvider.overrideWithValue(FeatureFlags.phase1),
          nextPrayerProvider.overrideWith((ref) => const Stream.empty()),
          if (location != null)
            resolvedLocationProvider.overrideWith((ref) async => location),
        ],
        child: ScreenUtilInit(
          designSize: phone,
          minTextAdapt: true,
          builder: (_, _) => MaterialApp(
            theme: brightness == Brightness.light
                ? AppTheme.light
                : AppTheme.dark,
            home: screen,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  /// Fails on RenderFlex overflow, unbounded constraints, or any paint error.
  void expectNoLayoutErrors(WidgetTester tester, String label) {
    final error = tester.takeException();
    expect(error, isNull, reason: '$label produced: $error');
  }

  group('renders without overflow — light', () {
    testWidgets('home', (tester) async {
      await render(tester, const HomeScreen());
      expectNoLayoutErrors(tester, 'HomeScreen');
    });

    testWidgets('amal tracker', (tester) async {
      await render(tester, const AmalTrackerScreen());
      await tester.pump();
      expectNoLayoutErrors(tester, 'AmalTrackerScreen');
    });

    testWidgets('tasbeeh', (tester) async {
      await render(tester, const TasbeehScreen());
      await tester.pump();
      expectNoLayoutErrors(tester, 'TasbeehScreen');
    });

    testWidgets('profile', (tester) async {
      // The longest screen in the app since it absorbed Settings.
      await render(tester, const ProfileScreen());
      await tester.pump();
      expectNoLayoutErrors(tester, 'ProfileScreen');
    });

    testWidgets('profile scrolls to the bottom without overflow',
        (tester) async {
      await render(tester, const ProfileScreen());
      await tester.pump();

      await tester.scrollUntilVisible(
        find.text('অ্যাকাউন্ট মুছে ফেলুন'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();

      expectNoLayoutErrors(tester, 'ProfileScreen scrolled');
    });
  });

  group('renders without overflow — dark', () {
    testWidgets('home', (tester) async {
      await render(tester, const HomeScreen(), brightness: Brightness.dark);
      expectNoLayoutErrors(tester, 'HomeScreen dark');
    });

    testWidgets('amal tracker', (tester) async {
      await render(
        tester,
        const AmalTrackerScreen(),
        brightness: Brightness.dark,
      );
      await tester.pump();
      expectNoLayoutErrors(tester, 'AmalTrackerScreen dark');
    });
  });

  group('survives a small screen', () {
    // A 320pt-wide budget Android is common in this market and is where fixed
    // widths and long Bangla labels break first.
    const small = Size(320, 640);

    testWidgets('home', (tester) async {
      await render(tester, const HomeScreen(), size: small);
      expectNoLayoutErrors(tester, 'HomeScreen at 320pt');
    });

    testWidgets('tasbeeh', (tester) async {
      await render(tester, const TasbeehScreen(), size: small);
      await tester.pump();
      expectNoLayoutErrors(tester, 'TasbeehScreen at 320pt');
    });

    testWidgets('profile', (tester) async {
      await render(tester, const ProfileScreen(), size: small);
      await tester.pump();
      expectNoLayoutErrors(tester, 'ProfileScreen at 320pt');
    });
  });

  group('survives large system text', () {
    // The app clamps scaling to 1.3 (app.dart); this asserts the layout holds
    // at that ceiling, which is where a fixed-height row clips.
    testWidgets('home at max clamped scale', (tester) async {
      tester.view.physicalSize = phone * 3;
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            appVersionProvider.overrideWithValue('0.0.0-test'),
            featureFlagsProvider.overrideWithValue(FeatureFlags.phase1),
            nextPrayerProvider.overrideWith((ref) => const Stream.empty()),
          ],
          child: ScreenUtilInit(
            designSize: phone,
            minTextAdapt: true,
            builder: (_, _) => MaterialApp(
              theme: AppTheme.light,
              builder: (context, child) => MediaQuery.withClampedTextScaling(
                minScaleFactor: 1.3,
                maxScaleFactor: 1.3,
                child: child ?? const SizedBox.shrink(),
              ),
              home: const HomeScreen(),
            ),
          ),
        ),
      );
      await tester.pump();

      expectNoLayoutErrors(tester, 'HomeScreen at 1.3x text');
    });
  });

  group('home header actions', () {
    testWidgets('theme and language are reachable from Home', (tester) async {
      await render(tester, const HomeScreen());

      expect(find.byTooltip('ডার্ক থিমে যান'), findsOneWidget);
      expect(find.byTooltip('ভাষা'), findsOneWidget);
    });

    testWidgets('the icon shows the theme the app is currently in',
        (tester) async {
      await render(tester, const HomeScreen(), brightness: Brightness.light);
      expect(find.byIcon(Icons.light_mode_rounded), findsOneWidget);
    });

    testWidgets('tapping toggles straight to dark, with no menu',
        (tester) async {
      await render(tester, const HomeScreen());

      await tester.tap(find.byTooltip('ডার্ক থিমে যান'));
      await tester.pumpAndSettle();

      // A two-state toggle that opens a sheet costs two taps to do what one
      // should, so there must be no picker here.
      expect(find.text('সিস্টেম অনুযায়ী'), findsNothing);
      expect(find.byTooltip('লাইট থিমে যান'), findsOneWidget);
    });

    testWidgets('tapping again returns to light', (tester) async {
      await render(tester, const HomeScreen());

      await tester.tap(find.byTooltip('ডার্ক থিমে যান'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('লাইট থিমে যান'));
      await tester.pumpAndSettle();

      expect(find.byTooltip('ডার্ক থিমে যান'), findsOneWidget);
    });
  });

  group('namaz app bar location', () {
    /// ব্রাহ্মণবাড়িয়া is the longest district name in cities.json at sixteen
    /// characters. If the bar survives that on the narrowest screen it
    /// survives every other name.
    const longest = ResolvedLocation(
      latitude: 23.95,
      longitude: 91.11,
      name: 'ব্রাহ্মণবাড়িয়া',
      source: LocationSource.manual,
    );

    testWidgets('shows the location name beside the pin', (tester) async {
      await render(
        tester,
        const PrayerTimeScreen(),
        location: const ResolvedLocation(
          latitude: 23.8,
          longitude: 90.4,
          name: 'ঢাকা',
          source: LocationSource.manual,
        ),
      );
      await tester.pump();

      // A bare pin said nothing about WHERE the times were computed for.
      expect(find.text('ঢাকা'), findsOneWidget);
      // Filled, not outlined — the chip has to be findable at a glance.
      expect(find.byIcon(Icons.location_on_rounded), findsOneWidget);
    });

    testWidgets('the longest name does not break the bar at 320pt',
        (tester) async {
      await render(
        tester,
        const PrayerTimeScreen(),
        size: const Size(320, 640),
        location: longest,
      );
      await tester.pump();

      expectNoLayoutErrors(tester, 'app bar with the longest district name');
      // The screen title must survive too — an unbounded chip would push it
      // out of the bar entirely.
      expect(find.text('নামাজের সময়'), findsOneWidget);
    });

    testWidgets('an approximate location is flagged in the bar itself',
        (tester) async {
      await render(
        tester,
        const PrayerTimeScreen(),
        location: const ResolvedLocation(
          latitude: 23.8,
          longitude: 90.4,
          name: 'ঢাকা',
          source: LocationSource.fallback,
        ),
      );
      await tester.pump();

      // G-06 — a guessed location silently produces wrong prayer times, so it
      // is marked where the user is already looking.
      expect(find.byIcon(Icons.location_off_outlined), findsOneWidget);
    });

    testWidgets('the location is not repeated in the countdown card',
        (tester) async {
      await render(
        tester,
        const PrayerTimeScreen(),
        location: const ResolvedLocation(
          latitude: 23.8,
          longitude: 90.4,
          name: 'ঢাকা',
          source: LocationSource.manual,
        ),
      );
      await tester.pump();

      // It moved to the app bar, where it stays visible instead of scrolling
      // away. Showing it twice would be the duplication this replaced.
      expect(find.text('ঢাকা'), findsOneWidget);
    });
  });

  group('theme integrity', () {
    test('no theme reaches for a network font', () {
      // google_fonts fetched Hind at runtime and threw offline. Everything must
      // resolve to a bundled family.
      expect(AppTheme.light.textTheme.bodyMedium?.fontFamily, 'Kalpurush');
      expect(AppTheme.dark.textTheme.bodyMedium?.fontFamily, 'Kalpurush');
      expect(AppTheme.light.textTheme.titleLarge?.fontFamily, 'Kalpurush');
    });

    test('dark mode does not use the light primary', () {
      // A dark-on-dark brand colour is the single most common dark-theme bug.
      expect(
        AppTheme.dark.colorScheme.primary,
        isNot(AppTheme.light.colorScheme.primary),
      );
    });

    test('both themes are Material 3', () {
      expect(AppTheme.light.useMaterial3, isTrue);
      expect(AppTheme.dark.useMaterial3, isTrue);
    });
  });
}
