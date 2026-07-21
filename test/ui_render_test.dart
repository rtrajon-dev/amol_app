import 'dart:io';

import 'package:amol365/app/config/feature_flags.dart';
import 'package:amol365/app/database/app_database.dart';
import 'package:amol365/app/di/providers.dart';
import 'package:amol365/app/services/storage_service.dart';
import 'package:amol365/app/theme/app_theme.dart';
import 'package:amol365/features/amal_tracker/presentation/view/amal_tracker_screen.dart';
import 'package:amol365/features/home/presentation/view/home_screen.dart';
import 'package:amol365/features/prayer_time/presentation/viewmodel/prayer_time_viewmodel.dart';
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
