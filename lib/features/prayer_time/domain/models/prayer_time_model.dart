/// The five daily prayers plus sunrise.
///
/// Sunrise is included because it bounds the Fajr window, but it is NOT a
/// prayer and is never notifiable (FR-N-23).
enum PrayerSlot { fajr, sunrise, dhuhr, asr, maghrib, isha }

extension PrayerSlotX on PrayerSlot {
  String get bangla => switch (this) {
        PrayerSlot.fajr => 'ফজর',
        PrayerSlot.sunrise => 'সূর্যোদয়',
        PrayerSlot.dhuhr => 'যোহর',
        PrayerSlot.asr => 'আসর',
        PrayerSlot.maghrib => 'মাগরিব',
        PrayerSlot.isha => 'এশা',
      };

  /// FR-N-23 — sunrise is not a prayer, so it cannot be notified.
  bool get isNotifiable => this != PrayerSlot.sunrise;

  /// Stable id base for notification scheduling. These must NOT change between
  /// releases: pending notifications are matched by id, and a changed id makes
  /// an already-scheduled azan impossible to cancel or replace.
  int get notificationBaseId => switch (this) {
        PrayerSlot.fajr => 100,
        PrayerSlot.sunrise => 200,
        PrayerSlot.dhuhr => 300,
        PrayerSlot.asr => 400,
        PrayerSlot.maghrib => 500,
        PrayerSlot.isha => 600,
      };

  /// Storage key fragment for the per-prayer toggle (FR-N-23).
  String get key => name;
}

/// A single prayer at a concrete moment.
class PrayerTime {
  const PrayerTime({required this.slot, required this.time});

  final PrayerSlot slot;

  /// FR-N-14 — a real `DateTime`, not a formatted string. Countdown arithmetic
  /// and notification scheduling both need this; the previous string-based
  /// model made azan impossible to implement (G-07).
  final DateTime time;

  String get bangla => slot.bangla;
}

/// One day's prayer times for one location.
class PrayerTimesModel {
  const PrayerTimesModel({
    required this.date,
    required this.prayers,
    required this.locationName,
    this.isFromCache = false,
  });

  final DateTime date;
  final List<PrayerTime> prayers;

  /// FR-N-18 — shown in the header so the user can see which location the
  /// times belong to. Silently computing for the wrong city is exactly the
  /// failure this closes (G-06).
  final String locationName;

  /// FR-N-09 — true when GPS timed out and a cached location was used.
  final bool isFromCache;

  DateTime? timeFor(PrayerSlot slot) {
    for (final p in prayers) {
      if (p.slot == slot) return p.time;
    }
    return null;
  }

  /// The next prayer strictly after [from].
  ///
  /// EC-01 — after Isha there is no later prayer today, so this returns null
  /// and the caller falls forward to tomorrow's Fajr. Sunrise is skipped: it
  /// is a boundary, not something to count down to.
  PrayerTime? nextAfter(DateTime from) {
    for (final p in prayers) {
      if (p.slot == PrayerSlot.sunrise) continue;
      if (p.time.isAfter(from)) return p;
    }
    return null;
  }

  /// The prayer whose window is currently active (FR-N-17).
  PrayerTime? currentAt(DateTime at) {
    PrayerTime? current;
    for (final p in prayers) {
      if (p.slot == PrayerSlot.sunrise) continue;
      if (!p.time.isAfter(at)) current = p;
    }
    return current;
  }
}
