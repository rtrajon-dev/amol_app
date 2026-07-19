import 'package:amol365/features/prayer_time/domain/models/prayer_time_model.dart';
import 'package:flutter_test/flutter_test.dart';

PrayerTimesModel dayWith({
  required DateTime base,
  String location = 'ঢাকা',
}) {
  DateTime at(int h, int m) =>
      DateTime(base.year, base.month, base.day, h, m);

  return PrayerTimesModel(
    date: base,
    locationName: location,
    prayers: [
      PrayerTime(slot: PrayerSlot.fajr, time: at(5, 0)),
      PrayerTime(slot: PrayerSlot.sunrise, time: at(6, 15)),
      PrayerTime(slot: PrayerSlot.dhuhr, time: at(12, 10)),
      PrayerTime(slot: PrayerSlot.asr, time: at(16, 30)),
      PrayerTime(slot: PrayerSlot.maghrib, time: at(18, 5)),
      PrayerTime(slot: PrayerSlot.isha, time: at(19, 25)),
    ],
  );
}

void main() {
  final today = DateTime(2026, 7, 19);
  final day = dayWith(base: today);

  group('next prayer selection', () {
    test('before Fajr, next is Fajr', () {
      final next = day.nextAfter(DateTime(2026, 7, 19, 3, 0));
      expect(next?.slot, PrayerSlot.fajr);
    });

    test('between Fajr and Dhuhr, next is Dhuhr — sunrise is skipped', () {
      final next = day.nextAfter(DateTime(2026, 7, 19, 7, 0));
      expect(next?.slot, PrayerSlot.dhuhr,
          reason: 'sunrise is a boundary, not something to count down to');
    });

    test('EC-01: after Isha there is no next prayer today', () {
      final next = day.nextAfter(DateTime(2026, 7, 19, 22, 0));
      expect(next, isNull,
          reason: 'the caller must roll forward to tomorrow Fajr, and the '
              'countdown has to span midnight rather than disappear');
    });

    test('exactly at a prayer time, that prayer is no longer "next"', () {
      final next = day.nextAfter(DateTime(2026, 7, 19, 12, 10));
      expect(next?.slot, PrayerSlot.asr);
    });
  });

  group('current waqt (FR-N-17)', () {
    test('before Fajr nothing is active', () {
      expect(day.currentAt(DateTime(2026, 7, 19, 3, 0)), isNull);
    });

    test('mid-afternoon Asr is active', () {
      expect(day.currentAt(DateTime(2026, 7, 19, 17, 0))?.slot, PrayerSlot.asr);
    });

    test('late evening Isha is active', () {
      expect(day.currentAt(DateTime(2026, 7, 19, 23, 0))?.slot, PrayerSlot.isha);
    });

    test('sunrise is never the current waqt', () {
      final current = day.currentAt(DateTime(2026, 7, 19, 6, 30));
      expect(current?.slot, PrayerSlot.fajr,
          reason: 'sunrise ends Fajr but is not itself a prayer');
    });
  });

  group('notifiability (FR-N-23)', () {
    test('the five prayers are notifiable', () {
      for (final slot in [
        PrayerSlot.fajr,
        PrayerSlot.dhuhr,
        PrayerSlot.asr,
        PrayerSlot.maghrib,
        PrayerSlot.isha,
      ]) {
        expect(slot.isNotifiable, isTrue, reason: slot.name);
      }
    });

    test('sunrise is NOT notifiable', () {
      expect(PrayerSlot.sunrise.isNotifiable, isFalse);
    });
  });

  group('notification ids', () {
    test('every slot has a distinct base id', () {
      final ids = PrayerSlot.values.map((s) => s.notificationBaseId).toSet();
      expect(ids.length, PrayerSlot.values.length);
    });

    test('azan and pre-reminder ids never collide across a 7-day window', () {
      // rescheduleAzan uses base+dayIndex for azan and base+50+dayIndex for the
      // reminder. A collision would make one silently cancel the other.
      final used = <int>{};
      for (final slot in PrayerSlot.values) {
        for (var day = 0; day < 7; day++) {
          expect(used.add(slot.notificationBaseId + day), isTrue,
              reason: 'azan id clash: ${slot.name} day $day');
          expect(used.add(slot.notificationBaseId + 50 + day), isTrue,
              reason: 'reminder id clash: ${slot.name} day $day');
        }
      }
    });

    test('base ids are spaced enough for the id scheme to hold', () {
      final sorted = PrayerSlot.values.map((s) => s.notificationBaseId).toList()
        ..sort();
      for (var i = 1; i < sorted.length; i++) {
        expect(sorted[i] - sorted[i - 1], greaterThanOrEqualTo(57),
            reason: 'need room for 7 azan ids + 50 offset + 7 reminder ids');
      }
    });
  });

  group('bangla labels', () {
    test('every slot has a Bangla name', () {
      for (final slot in PrayerSlot.values) {
        expect(slot.bangla, isNotEmpty);
      }
    });

    test('names are the expected ones', () {
      expect(PrayerSlot.fajr.bangla, 'ফজর');
      expect(PrayerSlot.dhuhr.bangla, 'যোহর');
      expect(PrayerSlot.asr.bangla, 'আসর');
      expect(PrayerSlot.maghrib.bangla, 'মাগরিব');
      expect(PrayerSlot.isha.bangla, 'এশা');
    });
  });

  group('model lookups', () {
    test('timeFor returns the right slot', () {
      expect(day.timeFor(PrayerSlot.maghrib), DateTime(2026, 7, 19, 18, 5));
    });

    test('location name is carried through (FR-N-18)', () {
      expect(day.locationName, 'ঢাকা');
    });
  });
}
