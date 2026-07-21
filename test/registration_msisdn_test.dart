import 'dart:convert';

import 'package:amol365/app/di/providers.dart';
import 'package:amol365/app/di/registration_coordinator.dart';
import 'package:amol365/app/network/api_client.dart';
import 'package:amol365/app/services/secure_storage_service.dart';
import 'package:amol365/app/services/storage_service.dart';
import 'package:amol365/features/auth/data/token_store.dart';
import 'package:amol365/features/auth/domain/app_user.dart';
import 'package:amol365/features/auth/presentation/viewmodel/auth_viewmodel.dart';
import 'package:amol365/features/subscription/domain/entitlement.dart';
import 'package:amol365/features/subscription/domain/subscription_repository.dart';
import 'package:amol365/features/subscription/presentation/viewmodel/subscription_viewmodel.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeSecureStore implements SecureStore {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}

/// Captures what registration sent and answers with a session.
class RegisterAdapter implements HttpClientAdapter {
  Map<String, dynamic>? lastBody;

  @override
  Future<ResponseBody> fetch(RequestOptions options, _, _) async {
    lastBody = options.data is Map
        ? Map<String, dynamic>.from(options.data as Map)
        : jsonDecode(options.data.toString()) as Map<String, dynamic>;

    return ResponseBody.fromString(
      jsonEncode({
        'ok': true,
        'data': {
          'user': {
            'id': 1,
            'email': lastBody!['email'],
            'msisdn': lastBody!['msisdn'],
            'emailVerified': false,
          },
          'accessToken': 'a',
          'refreshToken': 'r',
          'expiresIn': 900,
        },
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Records the number checked and returns a scripted entitlement.
class FakeSubscriptionRepository implements SubscriptionRepository {
  FakeSubscriptionRepository(this.result);

  Entitlement result;
  String? checkedMsisdn;
  Object? throwOnCheck;

  @override
  Future<Entitlement> checkStatus(String msisdn) async {
    checkedMsisdn = msisdn;
    if (throwOnCheck != null) throw throwOnCheck!;
    return result;
  }

  @override
  Future<Entitlement> cached() async => Entitlement.free;

  @override
  Future<Entitlement> refreshIfStale() async => result;

  @override
  Future<void> clear() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RegisterAdapter adapter;
  late FakeSubscriptionRepository subscriptions;

  ProviderContainer build() {
    final dio = Dio();
    dio.httpClientAdapter = adapter;

    return ProviderContainer(
      overrides: [
        appVersionProvider.overrideWithValue('0.0.0-test'),
        apiClientProvider.overrideWithValue(
          ApiClient(
            tokenStore: TokenStore(FakeSecureStore()),
            deviceId: 'test-device',
            appVersion: '0.0.0-test',
            dio: dio,
          ),
        ),
        subscriptionRepositoryProvider.overrideWithValue(subscriptions),
      ],
    );
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.instance.init();
    adapter = RegisterAdapter();
    subscriptions = FakeSubscriptionRepository(Entitlement.free);
  });

  Future<bool> register(ProviderContainer c, {String phone = '01712345678'}) {
    return c.read(registrationCoordinatorProvider).register(
          email: 'a@b.com',
          password: 'password123',
          msisdn: phone,
        );
  }

  group('the number reaches the server', () {
    test('registration sends the msisdn', () async {
      final c = build();
      addTearDown(c.dispose);

      await register(c);

      expect(adapter.lastBody?['msisdn'], '01712345678');
    });

    test('the account carries it back', () async {
      final c = build();
      addTearDown(c.dispose);

      await register(c);

      expect(c.read(authProvider).user?.msisdn, '01712345678');
    });
  });

  group('web subscriber (FR-S-19)', () {
    test('an already-subscribed number resolves to premium', () async {
      subscriptions.result = const Entitlement(tier: Tier.premium);

      final c = build();
      addTearDown(c.dispose);

      await register(c);

      expect(subscriptions.checkedMsisdn, '01712345678');
      expect(c.read(entitlementProvider).isPremium, isTrue,
          reason: 'they must not be asked to pay a second time');
    });

    test('and is announced, so they know they were not charged', () async {
      subscriptions.result = const Entitlement(tier: Tier.premium);

      final c = build();
      addTearDown(c.dispose);

      await register(c);

      expect(c.read(subscriptionRecognisedProvider), isTrue);
    });

    test('a new number stays free and says nothing', () async {
      final c = build();
      addTearDown(c.dispose);

      await register(c);

      expect(c.read(entitlementProvider).isPremium, isFalse);
      expect(c.read(subscriptionRecognisedProvider), isFalse);
    });
  });

  group('routing is held until the answer arrives', () {
    test('the resolving flag is clear once registration completes', () async {
      final c = build();
      addTearDown(c.dispose);

      await register(c);

      // Left true, the user would sit behind a spinner with no way forward.
      expect(c.read(subscriptionResolvingProvider), isFalse);
    });

    test('it clears even when the status check throws', () async {
      subscriptions.throwOnCheck = Exception('carrier down');

      final c = build();
      addTearDown(c.dispose);

      await register(c);

      expect(c.read(subscriptionResolvingProvider), isFalse);
    });
  });

  group('a failed lookup does not fail the account', () {
    test('registration still succeeds when the carrier is unreachable',
        () async {
      subscriptions.throwOnCheck = Exception('carrier down');

      final c = build();
      addTearDown(c.dispose);

      final ok = await register(c);

      // The account exists and the number is stored; they simply meet the gate
      // and can retry there.
      expect(ok, isTrue);
      expect(c.read(authProvider).isAuthenticated, isTrue);
      expect(c.read(entitlementProvider).isPremium, isFalse);
    });
  });

  group('normalisation', () {
    test('+880 and separators reach the server canonicalised', () {
      expect(SubscriptionNotifier.normaliseMsisdn('+880 1712-345678'),
          '01712345678');
      expect(SubscriptionNotifier.normaliseMsisdn('8801712345678'),
          '01712345678');
    });

    test('a malformed number is rejected before any request', () {
      expect(SubscriptionNotifier.normaliseMsisdn('0121234'), isNull);
    });
  });

  group('AppUser', () {
    test('parses msisdn, and tolerates its absence on old accounts', () {
      expect(
        AppUser.fromJson({'id': 1, 'email': 'a@b.com', 'msisdn': '01712345678'})
            .msisdn,
        '01712345678',
      );
      expect(AppUser.fromJson({'id': 1, 'email': 'a@b.com'}).msisdn, isNull);
    });
  });
}
