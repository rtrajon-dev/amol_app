import 'package:amol365/app/database/app_database.dart';
import 'package:amol365/app/di/providers.dart';
import 'package:amol365/app/services/storage_service.dart';
import 'package:amol365/features/amal_tracker/presentation/view/amal_tracker_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Proves the on-device database is genuinely file-backed.
///
/// The unit tests run against `NativeDatabase.memory()`, which cannot fail the
/// way that matters here: if `driftDatabase(name:)` resolved to a temporary or
/// per-instance store, every unit test would still pass while real users lost
/// their amal history on every app restart.
///
/// Closing the database and opening a fresh instance is the closest a test can
/// get to the app being killed and relaunched.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const day = '2026-07-20';

  Future<void> wipe(AppDatabase db) async {
    await db.delete(db.amalLogs).go();
    await db.delete(db.tasbeehSessions).go();
  }

  testWidgets('amal completions survive closing and reopening the database',
      (tester) async {
    final first = AppDatabase();
    await wipe(first);
    await first.markAmalCompleted(
      amalId: 'fajr',
      dayKey: day,
      completedAt: DateTime(2026, 7, 20, 5),
    );
    await first.markAmalCompleted(
      amalId: 'quran',
      dayKey: day,
      completedAt: DateTime(2026, 7, 20, 6),
    );
    await first.close();

    final second = AppDatabase();
    expect(await second.completedAmalIds(day), {'fajr', 'quran'});
    await wipe(second);
    await second.close();
  });

  testWidgets('streak survives a reopen', (tester) async {
    final now = DateTime(2026, 7, 20, 10);

    final first = AppDatabase();
    await wipe(first);
    for (var i = 0; i < 3; i++) {
      final d = now.subtract(Duration(days: i));
      await first.markAmalCompleted(
        amalId: 'fajr',
        dayKey: dayKeyFor(d),
        completedAt: d,
      );
    }
    await first.close();

    final second = AppDatabase();
    expect(await second.currentStreak(now), 3);
    await wipe(second);
    await second.close();
  });

  testWidgets('tasbeeh cycles survive a reopen', (tester) async {
    final first = AppDatabase();
    await wipe(first);
    await first.recordTasbeehCycle(
      tasbeehId: 'subhanallah',
      dayKey: day,
      count: 33,
      recordedAt: DateTime(2026, 7, 20, 9),
    );
    await first.close();

    final second = AppDatabase();
    expect(await second.tasbeehTotalForDay(day), 33);
    await wipe(second);
    await second.close();
  });

  testWidgets('clearing an amal is durable, not just an in-memory change',
      (tester) async {
    final first = AppDatabase();
    await wipe(first);
    await first.markAmalCompleted(
      amalId: 'fajr',
      dayKey: day,
      completedAt: DateTime(2026, 7, 20, 5),
    );
    await first.clearAmalCompleted(amalId: 'fajr', dayKey: day);
    await first.close();

    final second = AppDatabase();
    expect(await second.completedAmalIds(day), isEmpty);
    await second.close();
  });

  /// The database tests above would all pass even if the screen were still
  /// wired to the old in-memory notifier. This drives the real widget.
  testWidgets('tapping an amal on the tracker screen writes it to the database',
      (tester) async {
    await StorageService.instance.init();

    final db = AppDatabase();
    await wipe(db);
    final today = dayKeyFor(DateTime.now());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          // AmalCheckItem watches entitlement, which reaches the API client;
          // that throws unless the version bootstrap() normally supplies is set.
          appVersionProvider.overrideWithValue('0.0.0-test'),
        ],
        child: ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, _) => const MaterialApp(home: AmalTrackerScreen()),
        ),
      ),
    );
    // Settle the async load off the database.
    await tester.pumpAndSettle();

    expect(find.text('ফজর নামাজ'), findsOneWidget);
    expect(await db.completedAmalIds(today), isEmpty);

    await tester.tap(find.text('ফজর নামাজ'));
    await tester.pumpAndSettle();

    expect(await db.completedAmalIds(today), {'fajr'});

    // And untapping removes it again.
    await tester.tap(find.text('ফজর নামাজ'));
    await tester.pumpAndSettle();

    expect(await db.completedAmalIds(today), isEmpty);

    await wipe(db);
    await db.close();
  });
}
