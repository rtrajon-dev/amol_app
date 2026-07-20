import 'package:amol365/app/database/app_database.dart';
import 'package:amol365/app/di/providers.dart';
import 'package:amol365/features/ramadan/domain/models/ramadan_model.dart';
import 'package:amol365/features/ramadan/presentation/viewmodel/ramadan_viewmodel.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  final today = dayKeyFor(DateTime.now());

  group('checklist', () {
    test('starts with every item unchecked', () async {
      final state = await container.read(ramadanProvider.future);

      expect(state.items, hasLength(RamadanAmalItem.defaultList.length));
      expect(state.completedCount, 0);
      expect(state.allCompleted, isFalse);
    });

    test('toggling an item marks it complete', () async {
      await container.read(ramadanProvider.future);
      await container.read(ramadanProvider.notifier).toggle('tarawih');

      final state = container.read(ramadanProvider).value!;
      expect(state.items.firstWhere((i) => i.id == 'tarawih').isCompleted,
          isTrue);
      expect(state.completedCount, 1);
    });

    test('toggling twice clears it again', () async {
      await container.read(ramadanProvider.future);
      final notifier = container.read(ramadanProvider.notifier);

      await notifier.toggle('tarawih');
      await notifier.toggle('tarawih');

      expect(container.read(ramadanProvider).value!.completedCount, 0);
    });

    test('toggling one item leaves the others alone', () async {
      await container.read(ramadanProvider.future);
      await container.read(ramadanProvider.notifier).toggle('tahajjud');

      final state = container.read(ramadanProvider).value!;
      expect(state.items.firstWhere((i) => i.id == 'tahajjud').isCompleted,
          isTrue);
      expect(state.items.firstWhere((i) => i.id == 'tarawih').isCompleted,
          isFalse);
    });

    test('allCompleted becomes true only when every item is checked',
        () async {
      await container.read(ramadanProvider.future);
      final notifier = container.read(ramadanProvider.notifier);

      for (final item in RamadanAmalItem.defaultList) {
        expect(container.read(ramadanProvider).value!.allCompleted, isFalse);
        await notifier.toggle(item.id);
      }

      expect(container.read(ramadanProvider).value!.allCompleted, isTrue);
    });
  });

  group('persistence', () {
    test('a toggle reaches the database', () async {
      await container.read(ramadanProvider.future);
      await container.read(ramadanProvider.notifier).toggle('quran_page');

      expect(await db.completedRamadanIds(today), {'quran_page'});
    });

    test('untoggling removes the row', () async {
      await container.read(ramadanProvider.future);
      final notifier = container.read(ramadanProvider.notifier);

      await notifier.toggle('quran_page');
      await notifier.toggle('quran_page');

      expect(await db.completedRamadanIds(today), isEmpty);
    });

    test('existing rows are restored on first read', () async {
      await db.markRamadanCompleted(
        itemId: 'laylat_qadr',
        dayKey: today,
        completedAt: DateTime.now(),
      );

      final state = await container.read(ramadanProvider.future);

      expect(state.items.firstWhere((i) => i.id == 'laylat_qadr').isCompleted,
          isTrue);
    });

    test('yesterday\'s completions do not appear as today\'s', () async {
      await db.markRamadanCompleted(
        itemId: 'tarawih',
        dayKey: dayKeyFor(DateTime.now().subtract(const Duration(days: 1))),
        completedAt: DateTime.now(),
      );

      final state = await container.read(ramadanProvider.future);

      expect(state.completedCount, 0);
    });
  });

  group('daysObserved', () {
    test('counts distinct days, not individual items', () async {
      final now = DateTime.now();
      for (final id in ['tarawih', 'tahajjud', 'quran_page']) {
        await db.markRamadanCompleted(
          itemId: id,
          dayKey: dayKeyFor(now),
          completedAt: now,
        );
      }

      expect(await db.ramadanDaysObserved(), 1);
    });

    test('accumulates across days', () async {
      final now = DateTime.now();
      for (var i = 0; i < 5; i++) {
        await db.markRamadanCompleted(
          itemId: 'tarawih',
          dayKey: dayKeyFor(now.subtract(Duration(days: i))),
          completedAt: now,
        );
      }

      expect(await db.ramadanDaysObserved(), 5);
    });

    test('does not reset when a day is skipped', () async {
      final now = DateTime.now();
      // Days 0 and 3 only — a broken chain.
      for (final offset in [0, 3]) {
        await db.markRamadanCompleted(
          itemId: 'tarawih',
          dayKey: dayKeyFor(now.subtract(Duration(days: offset))),
          completedAt: now,
        );
      }

      // A running total, not a streak: Ramadan is a fixed season and missing
      // one night should not erase the record of the others.
      expect(await db.ramadanDaysObserved(), 2);
    });
  });

  group('isolation from the amal streak', () {
    test('Ramadan check-ins do not feed the daily amal streak', () async {
      final now = DateTime.now();
      await db.markRamadanCompleted(
        itemId: 'tarawih',
        dayKey: dayKeyFor(now),
        completedAt: now,
      );

      // Storing these in amal_logs would have silently inflated the streak
      // with days holding no ordinary amal.
      expect(await db.currentStreak(now), 0);
      expect(await db.completedAmalIds(dayKeyFor(now)), isEmpty);
    });

    test('the daily amal tracker does not feed daysObserved', () async {
      final now = DateTime.now();
      await db.markAmalCompleted(
        amalId: 'fajr',
        dayKey: dayKeyFor(now),
        completedAt: now,
      );

      expect(await db.ramadanDaysObserved(), 0);
    });
  });
}
