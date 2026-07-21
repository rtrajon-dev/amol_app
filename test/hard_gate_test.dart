import 'package:amol365/app/config/feature_flags.dart';
import 'package:amol365/app/router/app_routes.dart';
import 'package:amol365/features/subscription/domain/entitlement.dart';
import 'package:flutter_test/flutter_test.dart';

/// FR-G-06 — the whole app is the paid product.
///
/// These assert the gating RULE. The router applies it; keeping the rule in
/// `FeatureFlags.requiresSubscription` means it is stated once and can be
/// tested without standing up a navigator.
void main() {
  const gateOn = FeatureFlags.phase1;

  const gateOff = FeatureFlags(
    hadithEnabled: false,
    surahEnabled: false,
    subscriptionEnabled: false,
  );

  group('who is let in', () {
    test('an unsubscribed user is held at the gate', () {
      expect(gateOn.requiresSubscription(isPremium: false), isTrue);
    });

    test('a subscriber passes', () {
      expect(gateOn.requiresSubscription(isPremium: true), isFalse);
    });

    test('a subscriber whose check is stale still passes', () {
      // FR-S-15 — inside the 24h TTL + 7 day grace an offline subscriber keeps
      // access. Under a hard gate, downgrading them on a failed network call
      // would lock a paying user out of prayer times entirely.
      const stale = Entitlement(tier: Tier.premium, isStale: true);
      expect(gateOn.requiresSubscription(isPremium: stale.isPremium), isFalse);
    });

    test('the kill switch lets everyone in', () {
      // FR-P-07 — the only defence if BDApps billing breaks. Without it an
      // outage locks out every user of an app they cannot buy.
      expect(gateOff.requiresSubscription(isPremium: false), isFalse);
    });
  });

  group('the gate route itself', () {
    test('is reachable while billing is on', () {
      // Otherwise the redirect would send an unsubscribed user to a route that
      // immediately bounces them back — an infinite loop.
      expect(gateOn.isRouteWithheld(AppRoutes.subscription), isFalse);
    });

    test('is withheld when billing is off', () {
      expect(gateOff.isRouteWithheld(AppRoutes.subscription), isTrue);
    });
  });

  group('what the gate does not block', () {
    test('auth routes stay reachable so a gated user can sign out', () {
      // A user who will not pay must be able to leave. Withholding login would
      // trap them with no exit and no way to reach another account.
      for (final route in [
        AppRoutes.login,
        AppRoutes.register,
        AppRoutes.forgotPassword,
      ]) {
        expect(gateOn.isRouteWithheld(route), isFalse, reason: route);
      }
    });
  });
}
