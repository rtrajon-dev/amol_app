import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/prayer_time/presentation/viewmodel/prayer_time_viewmodel.dart';
import '../services/notification_service.dart';

/// Keeps the scheduled azan window in step with reality (FR-N-15, FR-N-26).
///
/// Without this, alarms would only ever be scheduled when the user happened to
/// open the azan settings screen — so a fresh install would go silent until
/// someone went looking for the setting.
///
/// Rescheduling is wholesale rather than incremental: trying to diff pending
/// notifications against recomputed times is where stale alarms survive and
/// fire at the wrong moment.
final azanBootstrapProvider = Provider<void>((ref) {
  Timer? midnightTimer;

  Future<void> reschedule() async {
    // Nothing to schedule if the user has not granted permission — and asking
    // here would violate FR-N-25 (permission is requested on enable, in
    // settings, never implicitly at startup).
    if (!await NotificationService.instance.hasNotificationPermission()) return;

    final enabled = AzanPreferences.read();
    if (!enabled.values.any((on) => on)) return;

    await ref.read(azanSchedulerProvider).rescheduleAll();
  }

  /// EC-09 / FR-N-15 — at midnight the rolling window has shifted by a day, so
  /// the far end needs filling in. Scheduling one timer to the next midnight is
  /// cheaper and more accurate than polling.
  void scheduleMidnightRefresh() {
    midnightTimer?.cancel();
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1, 0, 1);
    midnightTimer = Timer(nextMidnight.difference(now), () async {
      await reschedule();
      scheduleMidnightRefresh(); // re-arm for the following day
    });
  }

  // FR-N-15 — a location change moves every prayer time, so the whole window
  // is invalid and must be rebuilt.
  ref.listen(resolvedLocationProvider, (previous, next) {
    final before = previous?.value;
    final after = next.value;
    if (after == null) return;
    if (before != null &&
        before.latitude == after.latitude &&
        before.longitude == after.longitude) {
      return; // same place, nothing moved
    }
    reschedule();
  });

  reschedule();
  scheduleMidnightRefresh();

  ref.onDispose(() => midnightTimer?.cancel());
});
