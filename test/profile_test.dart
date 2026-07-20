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

  group('account', () {
    testWidgets('offers logout and account deletion', (tester) async {
      await pumpProfile(tester, flags: FeatureFlags.phase1);

      expect(find.text('লগআউট'), findsOneWidget);
      expect(find.text('অ্যাকাউন্ট মুছে ফেলুন'), findsOneWidget);
    });

    testWidgets('says progress survives a logout', (tester) async {
      await pumpProfile(tester, flags: FeatureFlags.phase1);

      // FR-A-08 — users who fear losing a long streak will not log out.
      expect(find.textContaining('এই ডিভাইসেই থাকবে'), findsOneWidget);
    });

    testWidgets('reaches Settings, which has no other entry point',
        (tester) async {
      await pumpProfile(tester, flags: FeatureFlags.phase1);

      expect(find.text('সেটিংস'), findsOneWidget);
    });
  });

  group('subscription is for subscribers only', () {
    testWidgets('a free user sees no subscription section at all',
        (tester) async {
      await pumpProfile(tester, flags: FeatureFlags.phase1);

      expect(find.text('সাবস্ক্রিপশন'), findsNothing);
      expect(find.text('স্ট্যাটাস চেক করুন'), findsNothing);
      expect(find.text('আনসাবস্ক্রাইব'), findsNothing);
    });

    testWidgets('a free user is never asked for a phone number',
        (tester) async {
      await pumpProfile(tester, flags: FeatureFlags.phase1);

      // Entitlement arrives from /auth/me on launch (FR-S-21), so there is
      // nothing for the user to type.
      expect(find.byType(TextField), findsNothing);
    });

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

    testWidgets('a subscriber can cancel even in a phase that sells nothing',
        (tester) async {
      await pumpProfile(
        tester,
        flags: FeatureFlags.phase1,
        entitlement: premium,
      );

      // Someone being charged must always have a way to stop it.
      expect(find.text('আনসাবস্ক্রাইব'), findsOneWidget);
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

    testWidgets('shows no upgrade offer in Phase 1', (tester) async {
      await pumpProfile(tester, flags: FeatureFlags.phase1);

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
