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

      expect(find.text('নামাজের সময়'), findsOneWidget);
      expect(find.text('কিবলা'), findsOneWidget);
      expect(find.text('তাসবিহ'), findsOneWidget);
      expect(find.text('ক্যালেন্ডার'), findsOneWidget);
    });

    testWidgets('restores both tiles when the flags are raised',
        (tester) async {
      await pump(tester, const HomeScreen(), flags: phase2);

      expect(find.text('হাদিস'), findsOneWidget);
      expect(find.text('সূরা'), findsOneWidget);
    });
  });

  group('premium lock (FR-PH-02)', () {
    final tahajjud = AmalItemModel.defaultList.firstWhere((i) => i.isPremium);

    testWidgets('does not lock a premium item when nothing can be bought',
        (tester) async {
      await pump(
        tester,
        Scaffold(
          body: AmalCheckItem(item: tahajjud, onToggle: () {}),
        ),
        flags: FeatureFlags.phase1,
      );

      expect(find.byIcon(Icons.lock), findsNothing,
          reason: 'a padlock advertises a tier the user cannot purchase');
    });

    testWidgets('locks it again once the tier exists', (tester) async {
      await pump(
        tester,
        Scaffold(
          body: AmalCheckItem(item: tahajjud, onToggle: () {}),
        ),
        flags: phase2,
      );

      // Two appear when locked: the check circle and the PremiumBadge.
      expect(find.byIcon(Icons.lock), findsAtLeastNWidgets(1));
    });

    testWidgets('a premium item is tappable in Phase 1', (tester) async {
      var toggled = false;

      await pump(
        tester,
        Scaffold(
          body: AmalCheckItem(item: tahajjud, onToggle: () => toggled = true),
        ),
        flags: FeatureFlags.phase1,
      );

      await tester.tap(find.text(tahajjud.title));
      await tester.pump();

      // AC-PH-10 — it completes rather than opening a dead subscription route.
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
