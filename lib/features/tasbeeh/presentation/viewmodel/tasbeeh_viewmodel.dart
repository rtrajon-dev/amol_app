import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/tasbeeh_model.dart';

class TasbeehState {
  final TasbeehModel selected;
  final int count;
  final int totalSession;

  const TasbeehState({
    required this.selected,
    this.count = 0,
    this.totalSession = 0,
  });

  TasbeehState copyWith({TasbeehModel? selected, int? count, int? totalSession}) => TasbeehState(
        selected: selected ?? this.selected,
        count: count ?? this.count,
        totalSession: totalSession ?? this.totalSession,
      );
}

class TasbeehNotifier extends Notifier<TasbeehState> {
  @override
  TasbeehState build() => TasbeehState(selected: TasbeehModel.presets.first);

  void increment() {
    final newCount = state.count + 1;
    final newTotal = state.totalSession + 1;
    if (newCount >= state.selected.target) {
      state = state.copyWith(count: 0, totalSession: newTotal);
    } else {
      state = state.copyWith(count: newCount, totalSession: newTotal);
    }
  }

  void reset() => state = state.copyWith(count: 0);

  void select(TasbeehModel tasbeeh) => state = TasbeehState(selected: tasbeeh);
}

final tasbeehProvider = NotifierProvider<TasbeehNotifier, TasbeehState>(TasbeehNotifier.new);
