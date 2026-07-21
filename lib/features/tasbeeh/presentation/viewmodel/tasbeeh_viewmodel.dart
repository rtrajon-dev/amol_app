import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/database/app_database.dart';
import '../../../../app/di/providers.dart';
import '../../../../app/services/storage_service.dart';
import '../../domain/models/tasbeeh_model.dart';

class TasbeehState {
  const TasbeehState({
    required this.selected,
    required this.counts,
    this.todayTotal = 0,
  });

  final TasbeehModel selected;

  /// In-progress cycle for EVERY tasbeeh, keyed by id.
  ///
  /// Held per dhikr rather than as one number: switching from Subhanallah to
  /// Alhamdulillah and back must return to where you left off. A single
  /// counter meant the first count was silently destroyed by the second.
  final Map<String, int> counts;

  /// Recitations recorded today across every completed cycle.
  final int todayTotal;

  /// Taps in the selected tasbeeh's current, incomplete cycle.
  int get count => counts[selected.id] ?? 0;

  /// What the user has actually recited today, including cycles in progress
  /// across all dhikr.
  int get displayTotal =>
      todayTotal + counts.values.fold(0, (sum, value) => sum + value);

  TasbeehState copyWith({
    TasbeehModel? selected,
    Map<String, int>? counts,
    int? todayTotal,
  }) =>
      TasbeehState(
        selected: selected ?? this.selected,
        counts: counts ?? this.counts,
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

    return TasbeehState(
      selected: selected,
      counts: _readCounts(),
      todayTotal: todayTotal,
    );
  }

  Future<void> increment() async {
    final current = state.value;
    if (current == null) return;

    final id = current.selected.id;
    final next = current.count + 1;

    if (next < current.selected.target) {
      await _write(current, {...current.counts, id: next});
      return;
    }

    // Cycle complete — bank it and start this dhikr's next one. Only this
    // tasbeeh's counter resets; the others are untouched.
    final cleared = {...current.counts, id: 0};
    state = AsyncData(current.copyWith(
      counts: cleared,
      todayTotal: current.todayTotal + current.selected.target,
    ));
    await _persist(cleared);

    await _db.recordTasbeehCycle(
      tasbeehId: id,
      dayKey: dayKeyFor(DateTime.now()),
      count: current.selected.target,
      recordedAt: DateTime.now(),
    );
  }

  /// Clears the SELECTED tasbeeh's cycle in progress.
  ///
  /// Completed cycles are history and are left alone, as are the other dhikr —
  /// this is "start this count over", not "undo today".
  Future<void> reset() async {
    final current = state.value;
    if (current == null) return;

    await _write(current, {...current.counts, current.selected.id: 0});
  }

  Future<void> select(TasbeehModel tasbeeh) async {
    final current = state.value;
    if (current == null || tasbeeh.id == current.selected.id) return;

    // Counts are NOT cleared. Each dhikr keeps its own progress, so returning
    // to one resumes it rather than starting again from zero.
    state = AsyncData(current.copyWith(selected: tasbeeh));
    await _storage.setString(StorageKeys.tasbeehSelectedId, tasbeeh.id);
  }

  Future<void> _write(TasbeehState current, Map<String, int> counts) async {
    state = AsyncData(current.copyWith(counts: counts));
    await _persist(counts);
  }

  Future<void> _persist(Map<String, int> counts) =>
      _storage.setString(StorageKeys.tasbeehCounts, jsonEncode(counts));

  /// Reads the stored map, dropping anything that no longer makes sense.
  ///
  /// A preset removed between releases, or a target lowered below a stored
  /// count, would otherwise leave a counter the user can never clear by
  /// counting.
  Map<String, int> _readCounts() {
    final raw = _storage.getString(StorageKeys.tasbeehCounts);
    if (raw.isEmpty) return {};

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};

      final result = <String, int>{};
      for (final preset in TasbeehModel.presets) {
        final value = decoded[preset.id];
        if (value is int && value > 0 && value < preset.target) {
          result[preset.id] = value;
        }
      }
      return result;
    } catch (_) {
      return {};
    }
  }
}

final tasbeehProvider =
    AsyncNotifierProvider<TasbeehNotifier, TasbeehState>(TasbeehNotifier.new);
