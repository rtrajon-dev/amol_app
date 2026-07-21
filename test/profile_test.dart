import 'package:amol365/app/config/feature_flags.dart';
import 'package:amol365/app/di/providers.dart';
import 'package:amol365/app/services/storage_service.dart';
import 'package:amol365/features/profile/presentation/view/profile_screen.dart';
import 'package:amol365/features/subscription/domain/entitlement.dart';
import 'package:amol365/features/subscription/presentation/viewmodel/subscription_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const designSize = Size(390, 844);

  const premium = Entitlement(tier: Tier.premium, maskedMsisdn: '017XXXXX678');

  const phase2 = FeatureFlags(
    hadithEnabled: true,
    surahEnabled: true,
    subscriptionEnabled: true,
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.instance.init();
  });

  Future<void> pumpProfile(
    WidgetTester tester, {
    required FeatureFlags flags,
    Entitlement entitlement = Entitlement.free,
  }) async {
    tester.view.physicalSize = designSize * 3;
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          featureFlagsProvider.overrideWithValue(flags),
          appVersionProvider.overrideWithValue('0.0.0-test'),
          entitlementProvider.overrideWith(() => _StubEntitlement(entitlement)),
        ],
        child: ScreenUtilInit(
          designSize: designSize,
          builder: (_, _) => const MaterialApp(home: ProfileScreen()),
        ),
      ),
    );
    await tester.pump();
    while (tester.takeException() != null) {}
  }

  /// Profile absorbed Settings, so it now scrolls. ListView builds lazily, so
  /// a row below the fold does not exist in the tree until scrolled to —
  /// find.text would report it missing rather than off-screen.
  Future<void> scrollTo(WidgetTester tester, Finder target) async {
    await tester.scrollUntilVisible(
      target,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
  }

  group('account', () {
    testWidgets('offers logout and account deletion', (tester) async {
      await pumpProfile(tester, flags: FeatureFlags.phase1);
      await scrollTo(tester, find.text('অ্যাকাউন্ট মুছে ফেলুন'));

      expect(find.text('লগআউট'), findsOneWidget);
      expect(find.text('অ্যাকাউন্ট মুছে ফেলুন'), findsOneWidget);
    });

    testWidgets('says progress survives a logout', (tester) async {
      await pumpProfile(tester, flags: FeatureFlags.phase1);
      await scrollTo(tester, find.text('লগআউট'));

      // FR-A-08 — users who fear losing a long streak will not log out.
      expect(find.textContaining('এই ডিভাইসেই থাকবে'), findsOneWidget);
    });

    testWidgets('carries the prayer settings Settings used to hold',
        (tester) async {
      await pumpProfile(tester, flags: FeatureFlags.phase1);

      // Settings was merged in; these rows have no other home.
      expect(find.text('শহর নির্বাচন'), findsOneWidget);
      expect(find.text('হিসাব পদ্ধতি'), findsOneWidget);
      expect(find.text('মাযহাব'), findsOneWidget);
      expect(find.text('আযান নোটিফিকেশন'), findsOneWidget);
    });

    testWidgets('leaves theme and language to the home header',
        (tester) async {
      await pumpProfile(tester, flags: FeatureFlags.phase1);

      // Promoted to Home as icons. Keeping them here too would recreate the
      // duplication the Settings merge removed.
      expect(find.text('থিম'), findsNothing);
      expect(find.text('ভাষা'), findsNothing);
    });

    testWidgets('no longer links to a separate Settings screen',
        (tester) async {
      await pumpProfile(tester, flags: FeatureFlags.phase1);

      expect(find.text('সেটিংস'), findsNothing);
    });

    testWidgets('hides the hadith row while the feature is withheld',
        (tester) async {
      await pumpProfile(tester, flags: FeatureFlags.phase1);

      // FR-PH-09 — this row previously showed unconditionally, advertising a
      // Phase 2 feature and leading to a route that redirects away.
      expect(find.text('প্রতিদিনের হাদিস'), findsNothing);
    });
  });

  group('subscription section', () {
    // Under FR-G-06 an unsubscribed user never reaches Profile at all — the
    // router holds them on the gate. These pump the widget directly, so they
    // describe what it renders for a given entitlement, not a reachable state.

    testWidgets('a subscriber sees status and unsubscribe', (tester) async {
      await pumpProfile(
        tester,
        flags: FeatureFlags.phase1,
        entitlement: premium,
      );

      expect(find.text('প্রিমিয়াম সক্রিয়'), findsOneWidget);
      expect(find.text('স্ট্যাটাস চেক করুন'), findsOneWidget);
      expect(find.text('আনসাবস্ক্রাইব'), findsOneWidget);
    });

    testWidgets('a subscriber is never asked for a phone number',
        (tester) async {
      await pumpProfile(
        tester,
        flags: FeatureFlags.phase1,
        entitlement: premium,
      );

      // Entitlement arrives from /auth/me on launch (FR-S-21).
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('warns that cancelling also ends web access', (tester) async {
      await pumpProfile(
        tester,
        flags: FeatureFlags.phase1,
        entitlement: premium,
      );

      // FR-S-20 — the consequence must never be a surprise.
      expect(find.textContaining('ওয়েবসাইটেও'), findsOneWidget);
    });

    testWidgets('a lapsed user is offered the subscription, not unsubscribe',
        (tester) async {
      await pumpProfile(tester, flags: FeatureFlags.phase1);

      expect(find.text('প্রিমিয়াম সাবস্ক্রিপশন'), findsOneWidget);
      expect(find.text('আনসাবস্ক্রাইব'), findsNothing);
    });

    testWidgets('the kill switch hides the section entirely', (tester) async {
      // FR-P-07 — with billing disabled there is nothing to sell and nothing
      // to manage, so the section must not advertise a dead flow.
      await pumpProfile(
        tester,
        flags: const FeatureFlags(
          hadithEnabled: false,
          surahEnabled: false,
          subscriptionEnabled: false,
        ),
      );

      expect(find.text('সাবস্ক্রিপশন'), findsNothing);
      expect(find.text('প্রিমিয়াম সাবস্ক্রিপশন'), findsNothing);
    });
  });

  group('subscription — Phase 2', () {
    testWidgets('offers the upgrade once a tier exists', (tester) async {
      await pumpProfile(tester, flags: phase2);

      expect(find.text('প্রিমিয়াম সাবস্ক্রিপশন'), findsOneWidget);
    });

    testWidgets('shows the masked number for a subscriber', (tester) async {
      await pumpProfile(tester, flags: phase2, entitlement: premium);

      expect(find.textContaining('017XXXXX678'), findsOneWidget);
    });

    testWidgets('flags a stale entitlement rather than implying it is fresh',
        (tester) async {
      await pumpProfile(
        tester,
        flags: phase2,
        entitlement: const Entitlement(
          tier: Tier.premium,
          maskedMsisdn: '017XXXXX678',
          isStale: true,
        ),
      );

      // FR-S-15 — access is honoured, but the app knows the answer is old.
      expect(find.textContaining('যাচাই করা যায়নি'), findsOneWidget);
    });
  });
}

class _StubEntitlement extends EntitlementNotifier {
  _StubEntitlement(this.value);

  final Entitlement value;

  @override
  Entitlement build() => value;
}
