import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/database/app_database.dart';
import '../../../../app/di/providers.dart';
import '../../../../app/services/storage_service.dart';
import '../../domain/models/tasbeeh_model.dart';

class TasbeehState {
  final TasbeehModel selected;

  /// Taps in the current, incomplete cycle. Returns to zero each time the
  /// cycle's target is reached.
  final int count;

  /// Recitations recorded today across every completed cycle.
  final int todayTotal;

  const TasbeehState({
    required this.selected,
    this.count = 0,
    this.todayTotal = 0,
  });

  /// What the user has actually recited today, including the cycle in progress.
  int get displayTotal => todayTotal + count;

  TasbeehState copyWith({
    TasbeehModel? selected,
    int? count,
    int? todayTotal,
  }) =>
      TasbeehState(
        selected: selected ?? this.selected,
        count: count ?? this.count,
        todayTotal: todayTotal ?? this.todayTotal,
      );
}

class TasbeehNotifier extends AsyncNotifier<TasbeehState> {
  AppDatabase get _db => ref.read(appDatabaseProvider);
  StorageService get _storage => ref.read(storageServiceProvider);

  @override
  Future<TasbeehState> build() async {
    final todayTotal = await _db.tasbeehTotalForDay(dayKeyFor(DateTime.now()));

    final savedId = _storage.getString(StorageKeys.tasbeehSelectedId);
    final selected = TasbeehModel.presets.firstWhere(
      (t) => t.id == savedId,
      orElse: () => TasbeehModel.presets.first,
    );

    // Restore the in-progress cycle only if the saved tasbeeh is the one being
    // restored — otherwise those taps would be credited to the wrong dhikr.
    final savedCount =
        savedId == selected.id ? _storage.getInt(StorageKeys.tasbeehCount) : 0;

    return TasbeehState(
      selected: selected,
      // A target changed between releases could leave a stale count above it.
      count: savedCount < selected.target ? savedCount : 0,
      todayTotal: todayTotal,
    );
  }

  Future<void> increment() async {
    final current = state.value;
    if (current == null) return;

    final next = current.count + 1;

    if (next < current.selected.target) {
      state = AsyncData(current.copyWith(count: next));
      await _storage.setInt(StorageKeys.tasbeehCount, next);
      return;
    }

    // Cycle complete — bank it and start the next one.
    state = AsyncData(current.copyWith(
      count: 0,
      todayTotal: current.todayTotal + current.selected.target,
    ));
    await _storage.setInt(StorageKeys.tasbeehCount, 0);
    await _db.recordTasbeehCycle(
      tasbeehId: current.selected.id,
      dayKey: dayKeyFor(DateTime.now()),
      count: current.selected.target,
      recordedAt: DateTime.now(),
    );
  }

  /// Clears the cycle in progress. Completed cycles are history and are left
  /// alone — this is "start this count over", not "undo today".
  Future<void> reset() async {
    final current = state.value;
    if (current == null) return;

    state = AsyncData(current.copyWith(count: 0));
    await _storage.setInt(StorageKeys.tasbeehCount, 0);
  }

  Future<void> select(TasbeehModel tasbeeh) async {
    final current = state.value;
    if (current == null || tasbeeh.id == current.selected.id) return;

    // Switching dhikr abandons the partial cycle: those taps belong to the
    // previous tasbeeh and cannot be carried across.
    state = AsyncData(current.copyWith(selected: tasbeeh, count: 0));
    await _storage.setInt(StorageKeys.tasbeehCount, 0);
    await _storage.setString(StorageKeys.tasbeehSelectedId, tasbeeh.id);
  }
}

final tasbeehProvider =
    AsyncNotifierProvider<TasbeehNotifier, TasbeehState>(TasbeehNotifier.new);
