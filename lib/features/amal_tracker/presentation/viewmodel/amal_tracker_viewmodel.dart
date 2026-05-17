import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/amal_item_model.dart';

class AmalTrackerState {
  final List<AmalItemModel> items;
  final int streak;
  final String lastCompletedDate;

  const AmalTrackerState({
    required this.items,
    this.streak = 0,
    this.lastCompletedDate = '',
  });

  int get completedCount => items.where((i) => i.isCompleted).length;
  int get totalCount => items.length;
  bool get allCompleted => completedCount == totalCount;

  AmalTrackerState copyWith({List<AmalItemModel>? items, int? streak}) => AmalTrackerState(
        items: items ?? this.items,
        streak: streak ?? this.streak,
        lastCompletedDate: lastCompletedDate,
      );
}

class AmalTrackerNotifier extends Notifier<AmalTrackerState> {
  @override
  AmalTrackerState build() => AmalTrackerState(items: AmalItemModel.defaultList);

  void toggle(String id) {
    final updated = state.items.map((item) {
      if (item.id == id) return item.copyWith(isCompleted: !item.isCompleted);
      return item;
    }).toList();
    state = state.copyWith(items: updated);
    // TODO: persist to SharedPreferences + update streak
  }

  void resetDay() {
    final reset = state.items.map((i) => i.copyWith(isCompleted: false)).toList();
    state = state.copyWith(items: reset);
  }
}

final amalTrackerProvider = NotifierProvider<AmalTrackerNotifier, AmalTrackerState>(AmalTrackerNotifier.new);
