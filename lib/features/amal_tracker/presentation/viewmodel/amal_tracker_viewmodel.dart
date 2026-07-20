import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/database/app_database.dart';
import '../../../../app/di/providers.dart';
import '../../domain/models/amal_item_model.dart';

class AmalTrackerState {
  final List<AmalItemModel> items;
  final int streak;

  /// The local day these items describe (`YYYY-MM-DD`).
  final String dayKey;

  const AmalTrackerState({
    required this.items,
    required this.dayKey,
    this.streak = 0,
  });

  int get completedCount => items.where((i) => i.isCompleted).length;
  int get totalCount => items.length;
  bool get allCompleted => completedCount == totalCount;

  AmalTrackerState copyWith({List<AmalItemModel>? items, int? streak}) =>
      AmalTrackerState(
        items: items ?? this.items,
        dayKey: dayKey,
        streak: streak ?? this.streak,
      );
}

class AmalTrackerNotifier extends AsyncNotifier<AmalTrackerState> {
  AppDatabase get _db => ref.read(appDatabaseProvider);

  @override
  Future<AmalTrackerState> build() async {
    final now = DateTime.now();
    final today = dayKeyFor(now);

    final completed = await _db.completedAmalIds(today);
    final streak = await _db.currentStreak(now);

    return AmalTrackerState(
      items: [
        for (final item in AmalItemModel.defaultList)
          item.copyWith(isCompleted: completed.contains(item.id)),
      ],
      dayKey: today,
      streak: streak,
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

    final now = DateTime.now();
    if (nowCompleted) {
      await _db.markAmalCompleted(
        amalId: id,
        dayKey: current.dayKey,
        completedAt: now,
      );
    } else {
      await _db.clearAmalCompleted(amalId: id, dayKey: current.dayKey);
    }

    // The first check of a day starts a streak and the last uncheck ends one,
    // so this has to run on every toggle, not only on completion.
    await _refreshStreak(now);
  }

  Future<void> resetDay() async {
    final current = state.value;
    if (current == null) return;

    state = AsyncData(current.copyWith(
      items: [
        for (final i in current.items) i.copyWith(isCompleted: false),
      ],
    ));

    for (final item in current.items) {
      await _db.clearAmalCompleted(amalId: item.id, dayKey: current.dayKey);
    }

    await _refreshStreak(DateTime.now());
  }

  Future<void> _refreshStreak(DateTime now) async {
    final streak = await _db.currentStreak(now);
    // Re-read: an interleaved toggle may have replaced the state while the
    // streak query was in flight.
    final latest = state.value;
    if (latest != null) state = AsyncData(latest.copyWith(streak: streak));
  }
}

final amalTrackerProvider =
    AsyncNotifierProvider<AmalTrackerNotifier, AmalTrackerState>(
  AmalTrackerNotifier.new,
);
