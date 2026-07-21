import 'package:amol365/app/database/app_database.dart';
import 'package:amol365/app/di/providers.dart';
import 'package:amol365/app/services/storage_service.dart';
import 'package:amol365/features/tasbeeh/domain/models/tasbeeh_model.dart';
import 'package:amol365/features/tasbeeh/presentation/viewmodel/tasbeeh_viewmodel.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Each dhikr keeps its own in-progress count.
///
/// The original build stored ONE counter for all five, so counting 50
/// Subhanallah, switching to Alhamdulillah and switching back showed zero.
/// That was a deliberate choice — "switching abandons the partial cycle" — and
/// the wrong one: taps belonging to a dhikr should be kept against it, not
/// discarded. Nothing tested switching, which is why it survived.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late ProviderContainer container;

  final subhanallah =
      TasbeehModel.presets.firstWhere((t) => t.id == 'subhanallah');
  final alhamdulillah =
      TasbeehModel.presets.firstWhere((t) => t.id == 'alhamdulillah');

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.instance.init();
    db = AppDatabase(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<TasbeehNotifier> ready() async {
    await container.read(tasbeehProvider.future);
    return container.read(tasbeehProvider.notifier);
  }

  // A function, not a getter: Dart has no local getters inside a function body.
  TasbeehState state() => container.read(tasbeehProvider).value!;

  Future<void> tap(TasbeehNotifier notifier, int times) async {
    for (var i = 0; i < times; i++) {
      await notifier.increment();
    }
  }

  group('per-dhikr counts', () {
    test('switching away and back preserves the count', () async {
      final notifier = await ready();

      await notifier.select(subhanallah);
      await tap(notifier, 20);
      expect(state().count, 20);

      await notifier.select(alhamdulillah);
      expect(state().count, 0, reason: 'a fresh dhikr starts at zero');

      await tap(notifier, 5);
      expect(state().count, 5);

      await notifier.select(subhanallah);

      // The reported bug: this used to be 0.
      expect(state().count, 20,
          reason: 'returning to a dhikr must resume where it was left');
    });

    test('each dhikr counts independently', () async {
      final notifier = await ready();

      await notifier.select(subhanallah);
      await tap(notifier, 7);

      await notifier.select(alhamdulillah);
      await tap(notifier, 3);

      expect(state().counts['subhanallah'], 7);
      expect(state().counts['alhamdulillah'], 3);
    });

    test('counts survive a restart', () async {
      final notifier = await ready();
      await notifier.select(subhanallah);
      await tap(notifier, 12);
      await notifier.select(alhamdulillah);
      await tap(notifier, 4);

      // A fresh container reads back from storage, as a relaunch would.
      final restarted = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(restarted.dispose);
      await restarted.read(tasbeehProvider.future);

      final restored = restarted.read(tasbeehProvider).value!;
      expect(restored.counts['subhanallah'], 12);
      expect(restored.counts['alhamdulillah'], 4);
    });
  });

  group('reset', () {
    test('clears only the selected dhikr', () async {
      final notifier = await ready();

      await notifier.select(subhanallah);
      await tap(notifier, 9);
      await notifier.select(alhamdulillah);
      await tap(notifier, 6);

      await notifier.reset();

      expect(state().counts['alhamdulillah'] ?? 0, 0);
      expect(state().counts['subhanallah'], 9,
          reason: 'resetting one dhikr must not touch another');
    });
  });

  group('completing a cycle', () {
    test('banks the target and zeroes only that dhikr', () async {
      final notifier = await ready();

      await notifier.select(alhamdulillah);
      await tap(notifier, 4);

      await notifier.select(subhanallah);
      await tap(notifier, subhanallah.target);

      expect(state().counts['subhanallah'] ?? 0, 0);
      expect(state().counts['alhamdulillah'], 4);
      expect(
        await db.tasbeehTotalForDay(dayKeyFor(DateTime.now())),
        subhanallah.target,
      );
    });
  });

  group('displayTotal', () {
    test('includes every in-progress cycle, not just the selected one',
        () async {
      final notifier = await ready();

      await notifier.select(subhanallah);
      await tap(notifier, 10);
      await notifier.select(alhamdulillah);
      await tap(notifier, 5);

      // What the user has actually recited today is the sum of all of it.
      expect(state().displayTotal, 15);
    });
  });

  group('stored counts are sanitised', () {
    test('a count at or above its target is dropped', () async {
      // A target lowered between releases would otherwise leave a counter the
      // user can never clear by counting.
      SharedPreferences.setMockInitialValues({
        'tasbeeh_counts': '{"subhanallah": 999}',
      });
      await StorageService.instance.init();

      final fresh = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(fresh.dispose);
      await fresh.read(tasbeehProvider.future);

      expect(fresh.read(tasbeehProvider).value!.counts['subhanallah'], isNull);
    });

    test('an unknown dhikr id is ignored', () async {
      SharedPreferences.setMockInitialValues({
        'tasbeeh_counts': '{"removed_preset": 5}',
      });
      await StorageService.instance.init();

      final fresh = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(fresh.dispose);
      await fresh.read(tasbeehProvider.future);

      expect(fresh.read(tasbeehProvider).value!.counts, isEmpty);
    });

    test('corrupt JSON yields empty counts rather than crashing', () async {
      SharedPreferences.setMockInitialValues({
        'tasbeeh_counts': 'not json at all',
      });
      await StorageService.instance.init();

      final fresh = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(fresh.dispose);
      await fresh.read(tasbeehProvider.future);

      expect(fresh.read(tasbeehProvider).value!.counts, isEmpty);
    });
  });
}
