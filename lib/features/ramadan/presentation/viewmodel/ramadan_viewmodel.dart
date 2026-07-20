import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/database/app_database.dart';
import '../../../../app/di/providers.dart';
import '../../../prayer_time/domain/models/prayer_time_model.dart';
import '../../../prayer_time/presentation/viewmodel/prayer_time_viewmodel.dart';
import '../../domain/models/ramadan_model.dart';

class RamadanState {
  const RamadanState({
    required this.items,
    required this.dayKey,
    this.daysObserved = 0,
  });

  final List<RamadanAmalItem> items;

  /// The local day these items describe (`YYYY-MM-DD`).
  final String dayKey;

  /// Distinct days with at least one completed Ramadan amal.
  final int daysObserved;

  int get completedCount => items.where((i) => i.isCompleted).length;
  int get totalCount => items.length;
  bool get allCompleted => completedCount == totalCount;

  RamadanState copyWith({List<RamadanAmalItem>? items, int? daysObserved}) =>
      RamadanState(
        items: items ?? this.items,
        dayKey: dayKey,
        daysObserved: daysObserved ?? this.daysObserved,
      );
}

class RamadanNotifier extends AsyncNotifier<RamadanState> {
  AppDatabase get _db => ref.read(appDatabaseProvider);

  @override
  Future<RamadanState> build() async {
    final today = dayKeyFor(DateTime.now());

    final completed = await _db.completedRamadanIds(today);
    final observed = await _db.ramadanDaysObserved();

    return RamadanState(
      items: [
        for (final item in RamadanAmalItem.defaultList)
          item.copyWith(isCompleted: completed.contains(item.id)),
      ],
      dayKey: today,
      daysObserved: observed,
    );
  }

  Future<void> toggle(String id) async {
    final current = state.value;
    if (current == null) return;

    final item = current.items.firstWhere((i) => i.id == id);
    final nowCompleted = !item.isCompleted;

    // Apply to the UI first — a checkbox must not wait on disk I/O.
    state = AsyncData(current.copyWith(
      items: [
        for (final i in current.items)
          i.id == id ? i.copyWith(isCompleted: nowCompleted) : i,
      ],
    ));

    if (nowCompleted) {
      await _db.markRamadanCompleted(
        itemId: id,
        dayKey: current.dayKey,
        completedAt: DateTime.now(),
      );
    } else {
      await _db.clearRamadanCompleted(itemId: id, dayKey: current.dayKey);
    }

    final observed = await _db.ramadanDaysObserved();
    final latest = state.value;
    if (latest != null) {
      state = AsyncData(latest.copyWith(daysObserved: observed));
    }
  }
}

final ramadanProvider =
    AsyncNotifierProvider<RamadanNotifier, RamadanState>(RamadanNotifier.new);

/// Sehri and iftar for today, derived from the user's actual prayer times.
///
/// Sehri ends at Fajr and iftar begins at Maghrib, so these are not separate
/// quantities to be configured — they are the prayer times the app already
/// computes for the user's location. Hardcoding them, as this screen
/// previously did, means telling someone in Sylhet to break their fast at
/// Dhaka's time, or at no real place's time at all.
final sehriIftarProvider = FutureProvider<({DateTime? sehri, DateTime? iftar})>(
  (ref) async {
    final times = await ref.watch(prayerTimesProvider.future);
    return (
      sehri: times.timeFor(PrayerSlot.fajr),
      iftar: times.timeFor(PrayerSlot.maghrib),
    );
  },
);
