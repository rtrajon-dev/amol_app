import 'package:amol365/app/config/feature_flags.dart';
import 'package:amol365/app/router/app_routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const allOff = FeatureFlags.phase1;

  const allOn = FeatureFlags(
    hadithEnabled: true,
    surahEnabled: true,
    subscriptionEnabled: true,
  );

  group('Phase 1 defaults', () {
    test('withholds both content features but sells the app', () {
      expect(allOff.hadithEnabled, isFalse);
      expect(allOff.surahEnabled, isFalse);
      // FR-G-06 — the whole app is the paid product, so the paywall ships on
      // even though Hadith and Surah are held back.
      expect(allOff.subscriptionEnabled, isTrue);
    });

    test('gates an unsubscribed user and lets a subscriber through', () {
      expect(allOff.requiresSubscription(isPremium: false), isTrue);
      expect(allOff.requiresSubscription(isPremium: true), isFalse);
    });
  });

  group('isRouteWithheld — Phase 1', () {
    test('withholds the hadith route', () {
      expect(allOff.isRouteWithheld(AppRoutes.hadith), isTrue);
    });

    test('withholds the surah list', () {
      expect(allOff.isRouteWithheld(AppRoutes.surah), isTrue);
    });

    test('withholds a surah detail route, not just the list', () {
      // AC-PH-02 — a deep link to a specific surah is the likeliest way in.
      expect(allOff.isRouteWithheld('/surah/1'), isTrue);
      expect(allOff.isRouteWithheld('/surah/114'), isTrue);
    });

    test('does not withhold the subscription route — it is the gate', () {
      expect(allOff.isRouteWithheld(AppRoutes.subscription), isFalse);
    });

    test('withholds the subscription route only when billing is off', () {
      const killed = FeatureFlags(
        hadithEnabled: false,
        surahEnabled: false,
        subscriptionEnabled: false,
      );

      // FR-P-07 — with billing disabled nobody should sit on a gate they
      // cannot complete.
      expect(killed.isRouteWithheld(AppRoutes.subscription), isTrue);
    });

    test('leaves every shipping feature reachable', () {
      for (final route in [
        AppRoutes.home,
        AppRoutes.prayerTime,
        AppRoutes.qibla,
        AppRoutes.tasbeeh,
        AppRoutes.amalTracker,
        AppRoutes.islamicCalendar,
        AppRoutes.namesOfAllah,
        AppRoutes.ramadan,
        AppRoutes.settings,
      ]) {
        expect(allOff.isRouteWithheld(route), isFalse,
            reason: '$route ships in Phase 1');
      }
    });
  });

  group('isRouteWithheld — Phase 2', () {
    test('allows everything once the flags are raised', () {
      for (final route in [
        AppRoutes.hadith,
        AppRoutes.surah,
        '/surah/1',
        AppRoutes.subscription,
      ]) {
        expect(allOn.isRouteWithheld(route), isFalse);
      }
    });
  });

  group('flag independence (AC-PH-04)', () {
    test('enabling Surah does not enable Hadith', () {
      const surahOnly = FeatureFlags(
        hadithEnabled: false,
        surahEnabled: true,
        subscriptionEnabled: false,
      );

      expect(surahOnly.isRouteWithheld(AppRoutes.surah), isFalse);
      expect(surahOnly.isRouteWithheld('/surah/12'), isFalse);
      expect(surahOnly.isRouteWithheld(AppRoutes.hadith), isTrue);
    });

    test('enabling Hadith does not enable Surah', () {
      const hadithOnly = FeatureFlags(
        hadithEnabled: true,
        surahEnabled: false,
        subscriptionEnabled: false,
      );

      expect(hadithOnly.isRouteWithheld(AppRoutes.hadith), isFalse);
      expect(hadithOnly.isRouteWithheld(AppRoutes.surah), isTrue);
    });

    test('content flags do not imply a paywall', () {
      const contentOnly = FeatureFlags(
        hadithEnabled: true,
        surahEnabled: true,
        subscriptionEnabled: false,
      );

      // Content can go live before the tier is switched on.
      expect(contentOnly.isRouteWithheld(AppRoutes.subscription), isTrue);
      expect(contentOnly.isRouteWithheld(AppRoutes.surah), isFalse);
    });
  });
}
