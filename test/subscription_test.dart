import 'dart:io';

import 'package:amol365/app/config/feature_flags.dart';
import 'package:amol365/app/services/storage_service.dart';
import 'package:amol365/features/subscription/domain/entitlement.dart';
import 'package:amol365/features/subscription/presentation/viewmodel/subscription_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Removes comment lines so the isolation checks test CODE, not prose.
///
/// A comment explaining *why* BDApps is isolated is good documentation, not a
/// dependency — flagging it would push people toward vaguer comments, which is
/// the opposite of what this check is for.
///
/// Deliberately does not strip trailing `//` after code: that would also eat
/// the `//` inside a string like `'https://amol.patawise.com/bdapps/...'`,
/// which is exactly the kind of direct carrier call C-BE-03 forbids and this
/// test must still catch.
String _stripComments(String source) {
  final withoutBlocks = source.replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '');
  return withoutBlocks
      .split('\n')
      .where((line) {
        final trimmed = line.trimLeft();
        return !trimmed.startsWith('//') && !trimmed.startsWith('*');
      })
      .join('\n');
}

void main() {
  group('MSISDN normalisation (FR-S-02, mirrors server O-01)', () {
    String? n(String raw) => SubscriptionNotifier.normaliseMsisdn(raw);

    test('accepts local format', () => expect(n('01712345678'), '01712345678'));
    test('strips 880 country code', () => expect(n('8801712345678'), '01712345678'));
    test('strips 88 prefix', () => expect(n('881712345678'), '01712345678'));
    test('ignores separators', () => expect(n('+880 1712-345678'), '01712345678'));
    test('rejects 012 prefix', () => expect(n('01212345678'), isNull));
    test('rejects too short', () => expect(n('0171234567'), isNull));
    test('rejects too long', () => expect(n('017123456789'), isNull));
    test('rejects letters', () => expect(n('017abcdefgh'), isNull));
    test('rejects empty', () => expect(n(''), isNull));
    test('accepts 013 through 019', () {
      for (final p in ['013', '014', '015', '016', '017', '018', '019']) {
        expect(n('${p}12345678'), '${p}12345678', reason: p);
      }
    });
  });

  group('Entitlement TTL and grace (FR-S-14, FR-S-15)', () {
    Entitlement premiumCheckedAgo(Duration ago) => Entitlement(
          tier: Tier.premium,
          checkedAt: DateTime.now().subtract(ago),
        );

    test('fresh inside the 24h TTL', () {
      expect(premiumCheckedAgo(const Duration(hours: 23)).isFresh, isTrue);
    });

    test('stale past the TTL', () {
      expect(premiumCheckedAgo(const Duration(hours: 25)).isFresh, isFalse);
    });

    test('still within grace 5 days after the TTL lapses', () {
      final e = premiumCheckedAgo(const Duration(days: 5));
      expect(e.isFresh, isFalse);
      expect(e.isBeyondGrace, isFalse,
          reason: 'a paying subscriber must not lose access because the '
              'server was unreachable for a few days');
    });

    test('beyond grace after TTL + 7 days', () {
      expect(premiumCheckedAgo(const Duration(days: 9)).isBeyondGrace, isTrue);
    });

    test('never-checked entitlement is beyond grace', () {
      expect(const Entitlement(tier: Tier.premium).isBeyondGrace, isTrue);
    });

    test('free is free', () {
      expect(Entitlement.free.isPremium, isFalse);
    });
  });

  group('Entitlement serialisation', () {
    test('round-trips through JSON', () {
      final original = Entitlement(
        tier: Tier.premium,
        checkedAt: DateTime.parse('2026-07-19T10:00:00Z'),
        maskedMsisdn: '017XXXXX678',
      );

      final restored = Entitlement.fromJson(original.toJson());

      expect(restored.tier, Tier.premium);
      expect(restored.maskedMsisdn, '017XXXXX678');
      expect(restored.checkedAt?.toUtc(), DateTime.parse('2026-07-19T10:00:00Z'));
    });

    test('unknown tier decodes as free, never premium', () {
      expect(Entitlement.fromJson({'tier': 'nonsense'}).tier, Tier.free);
      expect(Entitlement.fromJson({}).tier, Tier.free);
    });

    test('server payload maps tier without carrier vocabulary', () {
      final e = Entitlement.fromApi({
        'tier': 'premium',
        'checkedAt': '2026-07-19T10:00:00Z',
        'msisdn': '017XXXXX678',
      });
      expect(e.isPremium, isTrue);
      expect(e.maskedMsisdn, '017XXXXX678');
    });
  });

  group('module isolation (FR-R-02)', () {
    // Decommissioning BDApps must be: delete lib/features/subscription/data/
    // and swap one provider. That only holds if nothing outside the feature
    // reaches into its data layer. A convention nobody checks decays, so this
    // is enforced rather than documented.
    test('no feature module imports the subscription DATA layer', () {
      final offenders = <String>[];

      final libDir = Directory('lib');
      for (final entity in libDir.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;

        // The feature itself and the DI layer are allowed to.
        if (entity.path.startsWith('lib/features/subscription/')) continue;
        if (entity.path == 'lib/app/di/providers.dart') continue;

        final source = entity.readAsStringSync();
        if (source.contains('features/subscription/data/') ||
            source.contains('BdappsSubscriptionRepository')) {
          offenders.add(entity.path);
        }
      }

      expect(offenders, isEmpty,
          reason: 'These files reach into the subscription data layer and would '
              'break when BDApps is removed (SRS M-7). Depend on '
              'entitlementProvider or SubscriptionRepository instead.');
    });

    test('no feature module references BDApps or carrier vocabulary in CODE', () {
      final offenders = <String>[];
      final banned = ['bdapps', 'BDApps', 'referenceNo', 'subscriberId', 'S1000'];

      for (final entity in Directory('lib').listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        if (entity.path.startsWith('lib/features/subscription/')) continue;
        if (entity.path == 'lib/app/di/providers.dart') continue;

        final source = _stripComments(entity.readAsStringSync());
        for (final term in banned) {
          if (source.contains(term)) {
            offenders.add('${entity.path} → $term');
          }
        }
      }

      expect(offenders, isEmpty,
          reason: 'FR-S-01: no module outside lib/features/subscription/ may '
              'know about BDApps, MSISDN, OTP, or carrier state.');
    });
  });

  group('mandatory gate (FR-G-06)', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await StorageService.instance.init();
    });

    test('an unsubscribed user is gated', () {
      expect(
        FeatureFlags.phase1.requiresSubscription(isPremium: false),
        isTrue,
        reason: 'the whole app is the paid product',
      );
    });

    test('a subscriber is never gated', () {
      expect(
        FeatureFlags.phase1.requiresSubscription(isPremium: true),
        isFalse,
      );
    });

    test('there is no prompt cap — the gate does not stop appearing', () async {
      // FR-S-09's three-prompt limit is gone. Showing the gate ten times and
      // still gating proves the cap cannot strand a user in a blank app.
      for (var i = 0; i < 10; i++) {
        await SubscriptionGatePolicy.recordShown();
      }

      expect(FeatureFlags.phase1.requiresSubscription(isPremium: false), isTrue);
    });

    test('the kill switch releases everyone', () {
      // FR-P-07 — the only protection if BDApps billing fails: without it a
      // carrier outage locks every user out of an app they cannot buy.
      const killed = FeatureFlags(
        hadithEnabled: false,
        surahEnabled: false,
        subscriptionEnabled: false,
      );

      expect(killed.requiresSubscription(isPremium: false), isFalse);
    });

    test('a stale cached subscriber is not gated', () {
      // FR-S-15 — an offline subscriber inside the 7-day grace keeps access.
      // Gating them would lock a paying user out over a lost network.
      const stale = Entitlement(tier: Tier.premium, isStale: true);

      expect(FeatureFlags.phase1.requiresSubscription(isPremium: stale.isPremium), isFalse);
    });
  });

  group('gate telemetry counters', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await StorageService.instance.init();
    });

    int promptCount() =>
        StorageService.instance.getInt(StorageKeys.subGatePromptCount);

    test('recordShown increments the counter', () async {
      await SubscriptionGatePolicy.recordShown();
      await SubscriptionGatePolicy.recordShown();

      expect(promptCount(), 2);
    });

    test('reset clears the counter and the dismissal stamp', () async {
      await SubscriptionGatePolicy.recordShown();
      await SubscriptionGatePolicy.recordDismissed();

      await SubscriptionGatePolicy.reset();

      // Cleared on logout so the next account's funnel is measured from zero
      // rather than inheriting the previous user's tally on a shared phone.
      expect(promptCount(), 0);
      expect(StorageService.instance.getInt(StorageKeys.subGateDismissedAt), 0);
    });

    test('the counter never affects whether the gate appears', () async {
      for (var i = 0; i < 25; i++) {
        await SubscriptionGatePolicy.recordShown();
      }

      // Telemetry only. Gating follows from entitlement alone (FR-G-06).
      expect(FeatureFlags.phase1.requiresSubscription(isPremium: false), isTrue);
    });
  });
}
