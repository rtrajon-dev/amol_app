import 'dart:io';

import 'package:amol365/app/config/feature_flags.dart';
import 'package:amol365/app/database/app_database.dart';
import 'package:amol365/app/di/providers.dart';
import 'package:amol365/app/router/app_router.dart';
import 'package:amol365/app/router/app_routes.dart';
import 'package:amol365/app/services/storage_service.dart';
import 'package:amol365/app/theme/app_theme.dart';
import 'package:amol365/features/amal_tracker/presentation/view/amal_tracker_screen.dart';
import 'package:amol365/features/auth/domain/app_user.dart';
import 'package:amol365/features/auth/presentation/viewmodel/auth_viewmodel.dart';
import 'package:amol365/features/home/presentation/view/home_screen.dart';
import 'package:amol365/features/islamic_calendar/presentation/view/calendar_screen.dart';
import 'package:amol365/features/prayer_time/presentation/view/prayer_time_screen.dart';
import 'package:amol365/features/prayer_time/data/services/prayer_time_service.dart';
import 'package:amol365/features/prayer_time/presentation/viewmodel/prayer_time_viewmodel.dart';
import 'package:amol365/features/profile/presentation/view/profile_screen.dart';
import 'package:amol365/features/qibla/presentation/view/qibla_screen.dart';
import 'package:amol365/features/ramadan/presentation/view/ramadan_screen.dart';
import 'package:amol365/features/subscription/domain/entitlement.dart';
import 'package:amol365/features/subscription/presentation/viewmodel/subscription_viewmodel.dart';
import 'package:amol365/features/tasbeeh/presentation/view/tasbeeh_screen.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Drives the real router and asserts on what is ON SCREEN.
///
/// Two reasons it works this way. First, every earlier navigation test checked
/// the tab LIST rather than navigating, which is exactly how the reported bug
/// shipped: tapping a home tile called `context.go`, wiping the stack, so back
/// closed the app and nothing caught it.
///
/// Second, these deliberately do not assert on `currentConfiguration.uri`.
/// go_router's imperative `push` does not update that URI — it stays at the
/// branch's location while the pushed page is displayed. Asserting on it
/// reports a working screen as broken, which it did while this file was being
/// written. What a user experiences is which screen is visible and where back
/// takes them, so that is what is measured.
class _StubAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(
        status: AuthStatus.authenticated,
        user: AppUser(id: 1, email: 'a@b.com'),
      );
}

class _StubEntitlement extends EntitlementNotifier {
  @override
  Entitlement build() => const Entitlement(tier: Tier.premium);
}

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
  });

  late AppDatabase db;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      // Past onboarding, so the router settles on Home rather than redirecting.
      'onboarding_done': true,
    });
    await StorageService.instance.init();
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  Future<GoRouter> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = phone * 3;
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    late GoRouter router;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          appVersionProvider.overrideWithValue('0.0.0-test'),
          featureFlagsProvider.overrideWithValue(FeatureFlags.phase1),
          nextPrayerProvider.overrideWith((ref) => const Stream.empty()),
          // Without this the Qibla and Namaz screens sit on a spinner waiting
          // for real GPS, and an indefinite CircularProgressIndicator makes
          // pumpAndSettle time out rather than fail meaningfully.
          resolvedLocationProvider.overrideWith(
            (ref) async => const ResolvedLocation(
              latitude: 23.8103,
              longitude: 90.4125,
              name: 'ঢাকা',
              source: LocationSource.manual,
            ),
          ),
          authProvider.overrideWith(_StubAuth.new),
          entitlementProvider.overrideWith(_StubEntitlement.new),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            router = ref.watch(appRouterProvider);
            return ScreenUtilInit(
              designSize: phone,
              minTextAdapt: true,
              builder: (_, _) => MaterialApp.router(
                theme: AppTheme.light,
                routerConfig: router,
              ),
            );
          },
        ),
      ),
    );

    await tester.pumpAndSettle();
    return router;
  }

  /// The home grid sits below the fold. `ensureVisible`, not
  /// `scrollUntilVisible`: Home has two Scrollables — the CustomScrollView and
  /// the grid's own non-scrolling one — and targeting the wrong one scrolls
  /// nothing while the tap silently misses.
  Future<void> tapTile(WidgetTester tester, String label) async {
    final target = find.text(label);
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  Future<void> tapTab(WidgetTester tester, String label) async {
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  /// The system back gesture, as Android delivers it.
  Future<void> pressBack(WidgetTester tester) async {
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      'flutter/navigation',
      const JSONMethodCodec().encodeMethodCall(const MethodCall('popRoute')),
      (_) {},
    );
    await tester.pumpAndSettle();
  }

  group('drill-down from Home', () {
    testWidgets('opening the calendar leaves Home on the stack',
        (tester) async {
      final router = await pumpApp(tester);
      expect(find.byType(HomeScreen), findsOneWidget);

      await tapTile(tester, 'ক্যালেন্ডার');

      expect(find.byType(CalendarScreen), findsOneWidget);
      // The reported bug: `go` replaced the stack, so there was nothing to pop
      // and Android closed the app.
      expect(router.canPop(), isTrue,
          reason: 'back must return to Home, not exit the app');
    });

    testWidgets('back from the calendar returns to Home', (tester) async {
      await pumpApp(tester);
      await tapTile(tester, 'ক্যালেন্ডার');

      await pressBack(tester);

      expect(find.byType(CalendarScreen), findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('every home-grid destination is poppable', (tester) async {
      final destinations = <String, Type>{
        'কিবলা': QiblaScreen,
        'তাসবিহ': TasbeehScreen,
        'রমজান': RamadanScreen,
      };

      for (final entry in destinations.entries) {
        final router = await pumpApp(tester);

        await tapTile(tester, entry.key);
        expect(find.byType(entry.value), findsOneWidget,
            reason: '${entry.key} should open');
        expect(router.canPop(), isTrue,
            reason: '${entry.key} must be poppable');

        await pressBack(tester);
        expect(find.byType(HomeScreen), findsOneWidget,
            reason: 'back from ${entry.key} should reach Home');
      }
    });
  });

  group('tabs', () {
    testWidgets('switching tabs changes the screen', (tester) async {
      await pumpApp(tester);

      await tapTab(tester, 'আমল');

      expect(find.byType(AmalTrackerScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
    });

    testWidgets('back from a non-home tab returns to Home, not out of the app',
        (tester) async {
      await pumpApp(tester);

      await tapTab(tester, 'প্রোফাইল');
      expect(find.byType(ProfileScreen), findsOneWidget);

      await pressBack(tester);

      // The step most apps skip, and why users report that back "closed the
      // app" after tapping a tab.
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('a drill-down keeps its originating tab selected',
        (tester) async {
      await pumpApp(tester);
      await tapTile(tester, 'ক্যালেন্ডার');

      final bar = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );

      // Home stays lit because the calendar lives in the Home BRANCH — the
      // same as opening a post from a feed. Correct, provided back works,
      // which the tests above pin.
      expect(bar.currentIndex, 0);
    });
  });

  group('branch state is preserved', () {
    testWidgets('leaving and returning to a tab keeps its drill-down',
        (tester) async {
      await pumpApp(tester);

      await tapTile(tester, 'ক্যালেন্ডার');
      expect(find.byType(CalendarScreen), findsOneWidget);

      await tapTab(tester, 'নামাজ');
      expect(find.byType(PrayerTimeScreen), findsOneWidget);

      await tapTab(tester, 'হোম');

      // The point of StatefulShellRoute. A plain ShellRoute shares one stack
      // and would have dropped back to Home.
      expect(find.byType(CalendarScreen), findsOneWidget);
    });

    testWidgets('re-tapping the active tab pops it back to its root',
        (tester) async {
      await pumpApp(tester);

      await tapTile(tester, 'ক্যালেন্ডার');
      expect(find.byType(CalendarScreen), findsOneWidget);

      await tapTab(tester, 'হোম');

      // The standard escape hatch out of a deep stack.
      expect(find.byType(CalendarScreen), findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });

  group('config screens sit outside the shell', () {
    /// Bounded pumps rather than pumpAndSettle: the city selector loads its
    /// list asynchronously and shows a spinner meanwhile, and an indefinite
    /// CircularProgressIndicator never settles. Long enough for the route
    /// transition, which is all these assertions need.
    Future<void> settleTransition(WidgetTester tester) async {
      await tester.pump();
      // Long enough for the page transition to finish. Until it does, the
      // route below is still on stage and its nav bar is still findable, so a
      // shorter pump reports a covered nav bar as a visible one.
      await tester.pump(const Duration(seconds: 1));
    }

    testWidgets('the city selector shows no bottom nav', (tester) async {
      final router = await pumpApp(tester);

      router.push(AppRoutes.citySelector);
      await settleTransition(tester);

      // A nav bar on a configuration flow invites abandoning it half-done.
      expect(find.byType(BottomNavigationBar), findsNothing);
    });

    testWidgets('and returns to where it was opened from', (tester) async {
      final router = await pumpApp(tester);

      router.push(AppRoutes.citySelector);
      await settleTransition(tester);

      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/navigation',
        const JSONMethodCodec().encodeMethodCall(const MethodCall('popRoute')),
        (_) {},
      );
      await settleTransition(tester);

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });
  });
}
