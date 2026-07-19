import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/services/notification_service.dart';
import '../../data/services/prayer_time_service.dart';
import '../../domain/models/prayer_time_model.dart';

final prayerTimeServiceProvider =
    Provider<PrayerTimeService>((ref) => PrayerTimeService());

/// The resolved location, exposed so the screen can warn when it is a guess
/// rather than silently showing Dhaka times to someone in Sylhet (G-06).
final resolvedLocationProvider = FutureProvider<ResolvedLocation>((ref) async {
  return ref.watch(prayerTimeServiceProvider).resolveLocation();
});

/// Today's prayer times.
final prayerTimesProvider = FutureProvider<PrayerTimesModel>((ref) async {
  final service = ref.watch(prayerTimeServiceProvider);
  final location = await ref.watch(resolvedLocationProvider.future);
  return service.computeFor(location: location, date: DateTime.now());
});

/// FR-N-19 — times for an arbitrary date (±30 days), for planning ahead.
final prayerTimesForDateProvider =
    FutureProvider.family<PrayerTimesModel, DateTime>((ref, date) async {
  final service = ref.watch(prayerTimeServiceProvider);
  final location = await ref.watch(resolvedLocationProvider.future);
  return service.computeFor(location: location, date: date);
});

/// FR-N-16 / FR-N-20 — the next prayer, ticking once per second.
///
/// A single stream feeds both the Namaz Time screen and the home banner, so
/// there is no duplicate computation and the two can never disagree.
final nextPrayerProvider = StreamProvider<NextPrayerState?>((ref) async* {
  final service = ref.watch(prayerTimeServiceProvider);
  final location = await ref.watch(resolvedLocationProvider.future);

  while (true) {
    final now = DateTime.now();
    final today = service.computeFor(location: location, date: now);

    var next = today.nextAfter(now);
    if (next == null) {
      // EC-01 — past Isha, roll forward to tomorrow's Fajr so the countdown
      // spans midnight instead of vanishing for a few hours every night.
      final tomorrow = service.computeFor(
        location: location,
        date: DateTime(now.year, now.month, now.day + 1),
      );
      final fajr = tomorrow.timeFor(PrayerSlot.fajr);
      next = fajr == null ? null : PrayerTime(slot: PrayerSlot.fajr, time: fajr);
    }

    yield next == null
        ? null
        : NextPrayerState(prayer: next, remaining: next.time.difference(now));

    await Future<void>.delayed(const Duration(seconds: 1));
  }
});

class NextPrayerState {
  const NextPrayerState({required this.prayer, required this.remaining});

  final PrayerTime prayer;
  final Duration remaining;

  /// NFR-07 — Bangla numerals, e.g. "২ ঘণ্টা ১৪ মিনিট".
  String get remainingBangla {
    final total = remaining.isNegative ? Duration.zero : remaining;
    final hours = total.inHours;
    final minutes = total.inMinutes % 60;
    final seconds = total.inSeconds % 60;

    String bn(int v) => _toBangla(v.toString());

    if (hours > 0) return '${bn(hours)} ঘণ্টা ${bn(minutes)} মিনিট';
    if (minutes > 0) return '${bn(minutes)} মিনিট ${bn(seconds)} সেকেন্ড';
    return '${bn(seconds)} সেকেন্ড';
  }

  static String _toBangla(String value) {
    const digits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    return value.split('').map((c) {
      final i = int.tryParse(c);
      return i == null ? c : digits[i];
    }).join();
  }
}

/// FR-N-15 / FR-N-26 — rescheduling azan whenever the inputs change.
///
/// Everything that alters prayer times must route through here. A silent
/// mismatch between the times on screen and the alarms actually queued is the
/// worst possible outcome for this feature.
class AzanScheduler {
  AzanScheduler(this._ref);

  final Ref _ref;

  Future<void> rescheduleAll() async {
    final service = _ref.read(prayerTimeServiceProvider);
    final days = await service.getUpcomingDays(
      days: NotificationService.scheduleHorizonDays,
    );

    await NotificationService.instance.rescheduleAzan(
      upcomingDays: days,
      enabledPrayers: AzanPreferences.read(),
      preReminderMinutes: AzanPreferences.preReminderMinutes(),
    );
  }
}

final azanSchedulerProvider = Provider<AzanScheduler>(AzanScheduler.new);
