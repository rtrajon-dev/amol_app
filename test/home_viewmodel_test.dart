import 'package:amol365/app/database/app_database.dart';
import 'package:amol365/app/di/providers.dart';
import 'package:amol365/features/amal_tracker/domain/models/amal_item_model.dart';
import 'package:amol365/features/amal_tracker/presentation/viewmodel/amal_tracker_viewmodel.dart';
import 'package:amol365/features/home/presentation/viewmodel/home_viewmodel.dart';
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

  test('reports the real total, not a hardcoded one', () async {
    await container.read(amalTrackerProvider.future);

    expect(
      container.read(homeViewModelProvider).totalAmalCount,
      AmalItemModel.defaultList.length,
    );
    expect(AmalItemModel.defaultList.length, 9,
        reason: 'the card previously claimed 7');
  });

  test('shows zero completed before anything is checked', () async {
    await container.read(amalTrackerProvider.future);

    expect(container.read(homeViewModelProvider).completedAmalCount, 0);
  });

  test('reflects completions made through the tracker', () async {
    await container.read(amalTrackerProvider.future);

    await container.read(amalTrackerProvider.notifier).toggle('fajr');
    await container.read(amalTrackerProvider.notifier).toggle('quran');

    expect(container.read(homeViewModelProvider).completedAmalCount, 2);
  });

  test('drops back when an amal is unchecked', () async {
    await container.read(amalTrackerProvider.future);
    final notifier = container.read(amalTrackerProvider.notifier);

    await notifier.toggle('fajr');
    expect(container.read(homeViewModelProvider).completedAmalCount, 1);

    await notifier.toggle('fajr');
    expect(container.read(homeViewModelProvider).completedAmalCount, 0);
  });

  test('picks up completions already in the database on first read', () async {
    await db.markAmalCompleted(
      amalId: 'fajr',
      dayKey: dayKeyFor(DateTime.now()),
      completedAt: DateTime.now(),
    );

    await container.read(amalTrackerProvider.future);

    expect(container.read(homeViewModelProvider).completedAmalCount, 1);
  });

  test('holds a usable total while the first load is still in flight', () {
    // Read before awaiting: this is the frame the user actually sees on a cold
    // start, and it must not render "0/0".
    final vm = container.read(homeViewModelProvider);

    expect(vm.completedAmalCount, 0);
    expect(vm.totalAmalCount, AmalItemModel.defaultList.length);
  });
}
