import 'package:amol365/app/database/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  /// Marks [day] complete for one amal, so a streak can be built up.
  Future<void> logDay(DateTime day, {String amalId = 'fajr'}) {
    return db.markAmalCompleted(
      amalId: amalId,
      dayKey: dayKeyFor(day),
      completedAt: day,
    );
  }

  group('dayKeyFor', () {
    test('zero-pads month and day', () {
      expect(dayKeyFor(DateTime(2026, 1, 5)), '2026-01-05');
      expect(dayKeyFor(DateTime(2026, 12, 25)), '2026-12-25');
    });

    test('keys by local calendar day, not by time of day', () {
      expect(dayKeyFor(DateTime(2026, 7, 20, 0, 0)), '2026-07-20');
      expect(dayKeyFor(DateTime(2026, 7, 20, 23, 59)), '2026-07-20');
    });
  });

  group('amal completion', () {
    test('records and reads back a completed amal', () async {
      final now = DateTime(2026, 7, 20, 9);
      await logDay(now, amalId: 'quran');

      expect(await db.completedAmalIds('2026-07-20'), {'quran'});
    });

    test('re-marking the same amal twice does not throw or duplicate', () async {
      final now = DateTime(2026, 7, 20, 9);
      await logDay(now);
      await logDay(now);

      expect(await db.completedAmalIds('2026-07-20'), {'fajr'});
    });

    test('clearing removes only that amal on that day', () async {
      await logDay(DateTime(2026, 7, 20), amalId: 'fajr');
      await logDay(DateTime(2026, 7, 20), amalId: 'quran');
      await logDay(DateTime(2026, 7, 19), amalId: 'fajr');

      await db.clearAmalCompleted(amalId: 'fajr', dayKey: '2026-07-20');

      expect(await db.completedAmalIds('2026-07-20'), {'quran'});
      expect(await db.completedAmalIds('2026-07-19'), {'fajr'});
    });

    test('days are isolated from one another', () async {
      await logDay(DateTime(2026, 7, 19));

      expect(await db.completedAmalIds('2026-07-20'), isEmpty);
    });
  });

  group('currentStreak', () {
    test('is zero with no history', () async {
      expect(await db.currentStreak(DateTime(2026, 7, 20)), 0);
    });

    test('counts consecutive days ending today', () async {
      final now = DateTime(2026, 7, 20, 10);
      for (var i = 0; i < 3; i++) {
        await logDay(now.subtract(Duration(days: i)));
      }

      expect(await db.currentStreak(now), 3);
    });

    test('survives today being empty — yesterday still anchors it', () async {
      final now = DateTime(2026, 7, 20, 10);
      await logDay(now.subtract(const Duration(days: 1)));
      await logDay(now.subtract(const Duration(days: 2)));

      // Nothing logged today yet; a 9pm check-in has not lost the run.
      expect(await db.currentStreak(now), 2);
    });

    test('breaks on a gap and counts only the run nearest today', () async {
      final now = DateTime(2026, 7, 20, 10);
      await logDay(now);
      await logDay(now.subtract(const Duration(days: 1)));
      // Gap at day 2.
      await logDay(now.subtract(const Duration(days: 3)));
      await logDay(now.subtract(const Duration(days: 4)));

      expect(await db.currentStreak(now), 2);
    });

    test('is zero when the most recent day is older than yesterday', () async {
      final now = DateTime(2026, 7, 20, 10);
      await logDay(now.subtract(const Duration(days: 2)));

      expect(await db.currentStreak(now), 0);
    });

    test('counts a day once no matter how many amals it holds', () async {
      final now = DateTime(2026, 7, 20, 10);
      await logDay(now, amalId: 'fajr');
      await logDay(now, amalId: 'quran');
      await logDay(now, amalId: 'tahajjud');

      expect(await db.currentStreak(now), 1);
    });

    test('crosses a month boundary', () async {
      final now = DateTime(2026, 8, 1, 10);
      await logDay(now);
      await logDay(DateTime(2026, 7, 31));
      await logDay(DateTime(2026, 7, 30));

      expect(await db.currentStreak(now), 3);
    });

    test('crosses a year boundary', () async {
      final now = DateTime(2027, 1, 1, 10);
      await logDay(now);
      await logDay(DateTime(2026, 12, 31));

      expect(await db.currentStreak(now), 2);
    });

    test('crosses a leap day', () async {
      final now = DateTime(2028, 3, 1, 10);
      await logDay(now);
      await logDay(DateTime(2028, 2, 29));
      await logDay(DateTime(2028, 2, 28));

      expect(await db.currentStreak(now), 3);
    });

    test('drops to zero when the only logged day is cleared', () async {
      final now = DateTime(2026, 7, 20, 10);
      await logDay(now);
      expect(await db.currentStreak(now), 1);

      await db.clearAmalCompleted(amalId: 'fajr', dayKey: '2026-07-20');
      expect(await db.currentStreak(now), 0);
    });
  });

  group('tasbeeh sessions', () {
    test('is zero for a day with no cycles', () async {
      expect(await db.tasbeehTotalForDay('2026-07-20'), 0);
    });

    test('sums cycles across tasbeehs within a day', () async {
      await db.recordTasbeehCycle(
        tasbeehId: 'subhanallah',
        dayKey: '2026-07-20',
        count: 33,
        recordedAt: DateTime(2026, 7, 20, 9),
      );
      await db.recordTasbeehCycle(
        tasbeehId: 'astaghfirullah',
        dayKey: '2026-07-20',
        count: 100,
        recordedAt: DateTime(2026, 7, 20, 10),
      );

      expect(await db.tasbeehTotalForDay('2026-07-20'), 133);
    });

    test('does not leak totals across days', () async {
      await db.recordTasbeehCycle(
        tasbeehId: 'subhanallah',
        dayKey: '2026-07-19',
        count: 33,
        recordedAt: DateTime(2026, 7, 19),
      );

      expect(await db.tasbeehTotalForDay('2026-07-20'), 0);
    });

    test('records repeat cycles of the same tasbeeh separately', () async {
      for (var i = 0; i < 3; i++) {
        await db.recordTasbeehCycle(
          tasbeehId: 'subhanallah',
          dayKey: '2026-07-20',
          count: 33,
          recordedAt: DateTime(2026, 7, 20, 9 + i),
        );
      }

      expect(await db.tasbeehTotalForDay('2026-07-20'), 99);
    });
  });
}
