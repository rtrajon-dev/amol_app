import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../amal_tracker/domain/models/amal_item_model.dart';
import '../../../amal_tracker/presentation/viewmodel/amal_tracker_viewmodel.dart';

class HomeViewModel {
  const HomeViewModel({
    required this.completedAmalCount,
    required this.totalAmalCount,
  });

  final int completedAmalCount;
  final int totalAmalCount;
}

/// Summary counts for the home screen's amal card.
///
/// Prayer times are deliberately absent: `NextPrayerBanner` reads
/// `nextPrayerProvider` directly (FR-N-20), and routing them through here too
/// would give the home screen a second source of truth that could disagree
/// with the Namaz Time screen.
final homeViewModelProvider = Provider<HomeViewModel>((ref) {
  // Watched, not read: checking an amal must move the card on Home too.
  final amal = ref.watch(amalTrackerProvider).value;

  return HomeViewModel(
    completedAmalCount: amal?.completedCount ?? 0,
    // While the first load is in flight the total is still known, so the card
    // shows "0/9" rather than briefly claiming there is nothing to do.
    totalAmalCount: amal?.totalCount ?? AmalItemModel.defaultList.length,
  );
});
