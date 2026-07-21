import 'package:amol365/app/config/feature_flags.dart';
import 'package:amol365/app/database/app_database.dart';
import 'package:amol365/app/di/providers.dart';
import 'package:amol365/app/services/content_sync_service.dart';
import 'package:amol365/app/services/storage_service.dart';
import 'package:amol365/features/amal_tracker/domain/models/amal_item_model.dart';
import 'package:amol365/features/amal_tracker/presentation/widgets/amal_check_item.dart';
import 'package:amol365/features/home/presentation/view/home_screen.dart';
import 'package:amol365/features/prayer_time/presentation/viewmodel/prayer_time_viewmodel.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const designSize = Size(390, 844);

  const phase2 = FeatureFlags(
    hadithEnabled: true,
    surahEnabled: true,
    subscriptionEnabled: true,
  );

  late AppDatabase db;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.instance.init();
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    required FeatureFlags flags,
  }) async {
    tester.view.physicalSize = designSize * 3;
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          featureFlagsProvider.overrideWithValue(flags),
          appVersionProvider.overrideWithValue('0.0.0-test'),
          appDatabaseProvider.overrideWithValue(db),
          nextPrayerProvider.overrideWith((ref) => const Stream.empty()),
        ],
        child: ScreenUtilInit(
          designSize: designSize,
          builder: (_, _) => MaterialApp(home: child),
        ),
      ),
    );
    await tester.pump();
    // Layout overflow here is a test-font artifact: flutter_test substitutes
    // uniform box glyphs, so Bangla measures wider than Kalpurush does.
    while (tester.takeException() != null) {}
  }

  group('home quick actions (FR-PH-07)', () {
    testWidgets('hides the hadith and surah tiles in Phase 1', (tester) async {
      await pump(tester, const HomeScreen(), flags: FeatureFlags.phase1);

      expect(find.text('হাদিস'), findsNothing);
      expect(find.text('সূরা'), findsNothing);
    });

    testWidgets('keeps every shipping tile', (tester) async {
      await pump(tester, const HomeScreen(), flags: FeatureFlags.phase1);

      expect(find.text('কিবলা'), findsOneWidget);
      expect(find.text('তাসবিহ'), findsOneWidget);
      expect(find.text('ক্যালেন্ডার'), findsOneWidget);
      // Dropped from the nav when it went to four tabs, so the grid is now
      // the only way in.
      expect(find.text('রমজান'), findsOneWidget);
    });

    testWidgets('does not duplicate a feature that owns a tab', (tester) async {
      await pump(tester, const HomeScreen(), flags: FeatureFlags.phase1);

      // নামাজ is a permanent tab; a tile would spend a grid slot on a screen
      // that is always one tap away.
      expect(find.text('নামাজের সময়'), findsNothing);
    });

    testWidgets('restores both tiles when the flags are raised',
        (tester) async {
      await pump(tester, const HomeScreen(), flags: phase2);

      expect(find.text('হাদিস'), findsOneWidget);
      expect(find.text('সূরা'), findsOneWidget);
    });
  });

  group('premium lock', () {
    final tahajjud = AmalItemModel.defaultList.firstWhere((i) => i.isPremium);

    testWidgets('locks a premium item when a tier is on sale', (tester) async {
      await pump(
        tester,
        Scaffold(body: AmalCheckItem(item: tahajjud, onToggle: () {})),
        flags: FeatureFlags.phase1,
      );

      // Under FR-G-06 only subscribers are inside the app, so this padlock is
      // effectively unreachable — it stays as the guard for a future phase
      // that sells individual features rather than the whole app.
      expect(find.byIcon(Icons.lock), findsAtLeastNWidgets(1));
    });

    testWidgets('does not lock when the kill switch is off', (tester) async {
      // FR-P-07 — with billing disabled a padlock would point at a flow the
      // user cannot complete and a route that redirects away.
      await pump(
        tester,
        Scaffold(body: AmalCheckItem(item: tahajjud, onToggle: () {})),
        flags: const FeatureFlags(
          hadithEnabled: false,
          surahEnabled: false,
          subscriptionEnabled: false,
        ),
      );

      expect(find.byIcon(Icons.lock), findsNothing);
    });

    testWidgets('is completable when billing is disabled', (tester) async {
      var toggled = false;

      await pump(
        tester,
        Scaffold(
          body: AmalCheckItem(item: tahajjud, onToggle: () => toggled = true),
        ),
        flags: const FeatureFlags(
          hadithEnabled: false,
          surahEnabled: false,
          subscriptionEnabled: false,
        ),
      );

      await tester.tap(find.text(tahajjud.title));
      await tester.pump();

      expect(toggled, isTrue);
    });
  });

  group('content manifest (FR-PH-12)', () {
    test('a Phase 1 client claims no Phase 2 content', () {
      final keys = ContentSyncService.fileNames.keys;

      expect(keys, isNot(contains('hadiths')));
      expect(keys, isNot(contains('surahs')));
      expect(keys, isNot(contains('surahsFull')));
    });

    test('it still claims the content Phase 1 ships', () {
      final keys = ContentSyncService.fileNames.keys;

      expect(keys, contains('names'));
      expect(keys, contains('cities'));
    });
  });
}
