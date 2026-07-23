import 'package:amol365/app/di/providers.dart';
import 'package:amol365/app/di/subscription_notice.dart';
import 'package:amol365/app/network/api_exception.dart';
import 'package:amol365/app/services/storage_service.dart';
import 'package:amol365/features/subscription/domain/entitlement.dart';
import 'package:amol365/features/subscription/domain/subscription_repository.dart';
import 'package:amol365/features/subscription/presentation/viewmodel/subscription_viewmodel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The gate ends by handing the user to Home, which then owes them a sentence
/// about what just happened. These tests pin which sentence.
///
/// The INITIAL CHARGING PENDING case is resolved server-side — the backend maps
/// it to tier `premium` — so from here it is indistinguishable from any other
/// successful subscribe, which is the point: the client holds no carrier
/// vocabulary (FR-S-01).
class ScriptedRepository implements SubscriptionRepository {
  ScriptedRepository({required this.statusResult, required this.verifyResult});

  Entitlement statusResult;
  Entitlement verifyResult;
  Object? throwOnVerify;

  @override
  Future<Entitlement> checkStatus(String msisdn) async => statusResult;

  @override
  Future<OtpChallenge> requestOtp(String msisdn) async =>
      const OtpChallenge(txnId: 'txn-1', resendAfterSeconds: 60);

  @override
  Future<Entitlement> verifyOtp({
    required String txnId,
    required String otp,
  }) async {
    if (throwOnVerify != null) throw throwOnVerify!;
    return verifyResult;
  }

  @override
  Future<Entitlement> cached() async => Entitlement.free;

  @override
  Future<Entitlement> refreshIfStale() async => Entitlement.free;

  @override
  Future<Entitlement> cancel() async => Entitlement.free;

  @override
  Future<void> clear() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ScriptedRepository repository;

  /// [entitlementProvider] restores itself from cache in a microtask, which
  /// would land after the gate has set its answer and overwrite it. Reading it
  /// here and letting that settle first is what the real app gets for free,
  /// since the provider is alive long before the gate opens.
  Future<ProviderContainer> build() async {
    final c = ProviderContainer(
      overrides: [subscriptionRepositoryProvider.overrideWithValue(repository)],
    );
    c.read(entitlementProvider);
    await Future<void>.delayed(Duration.zero);
    return c;
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.instance.init();
    repository = ScriptedRepository(
      statusResult: Entitlement.free,
      verifyResult: const Entitlement(tier: Tier.premium),
    );
  });

  group('a new subscription', () {
    test('verifying the OTP queues the congratulation', () async {
      final c = await build();
      addTearDown(c.dispose);

      await c.read(subscriptionProvider.notifier).submitPhone('01712345678');
      await c.read(subscriptionProvider.notifier).submitOtp('123456');

      expect(c.read(subscriptionProvider).step, GateStep.success);
      expect(c.read(entitlementProvider).isPremium, isTrue);
      expect(c.read(subscriptionNoticeProvider), SubscriptionNotice.activated);
    });

    test('a rejected OTP says nothing and grants nothing', () async {
      final c = await build();
      addTearDown(c.dispose);

      await c.read(subscriptionProvider.notifier).submitPhone('01712345678');
      // A wrong code is an error from the server, not a `free` entitlement.
      repository.throwOnVerify = const ApiException(
        code: 'OTP_INVALID',
        message: 'ভুল কোড।',
      );
      await c.read(subscriptionProvider.notifier).submitOtp('000000');

      expect(c.read(subscriptionProvider).step, GateStep.otp,
          reason: 'the user stays on the OTP screen to retry');
      expect(c.read(entitlementProvider).isPremium, isFalse);
      expect(c.read(subscriptionNoticeProvider), SubscriptionNotice.none);
    });
  });

  group('an existing subscription (FR-S-19)', () {
    test('is recognised without an OTP, and said so differently', () async {
      repository.statusResult = const Entitlement(tier: Tier.premium);

      final c = await build();
      addTearDown(c.dispose);

      await c.read(subscriptionProvider.notifier).submitPhone('01712345678');

      expect(c.read(subscriptionProvider).step, GateStep.success);
      expect(c.read(subscriptionNoticeProvider), SubscriptionNotice.recognised);
    });

    test('an unsubscribed number is sent to the OTP step instead', () async {
      final c = await build();
      addTearDown(c.dispose);

      await c.read(subscriptionProvider.notifier).submitPhone('01712345678');

      expect(c.read(subscriptionProvider).step, GateStep.otp);
      expect(c.read(subscriptionNoticeProvider), SubscriptionNotice.none);
    });
  });

  test('the notice is consumed by the first reader', () async {
    final c = await build();
    addTearDown(c.dispose);

    c.read(subscriptionNoticeProvider.notifier).set(SubscriptionNotice.activated);

    expect(c.read(subscriptionNoticeProvider.notifier).take(),
        SubscriptionNotice.activated);
    expect(c.read(subscriptionNoticeProvider.notifier).take(),
        SubscriptionNotice.none,
        reason: 'otherwise it reappears on every return to Home');
  });
}
