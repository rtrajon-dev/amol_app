import '../../../app/network/api_exception.dart';
import '../domain/entitlement.dart';
import '../domain/subscription_repository.dart';
import 'entitlement_cache.dart';
import 'subscription_api.dart';

/// BDApps-backed implementation.
///
/// This is the class M-7 deletes. Nothing outside `lib/features/subscription/`
/// may import it — an automated test enforces that (FR-R-02).
class BdappsSubscriptionRepository implements SubscriptionRepository {
  BdappsSubscriptionRepository({
    required SubscriptionApi api,
    required EntitlementCache cache,
  })  : _api = api,
        _cache = cache;

  final SubscriptionApi _api;
  final EntitlementCache _cache;

  @override
  Future<Entitlement> cached() => _cache.read();

  @override
  Future<Entitlement> checkStatus(String msisdn) async {
    final data = await _api.status(msisdn);
    return _store(data);
  }

  @override
  Future<OtpChallenge> requestOtp(String msisdn) async {
    final data = await _api.requestOtp(msisdn);
    final challenge = OtpChallenge.fromJson(data);
    if (challenge.txnId.isEmpty) {
      throw const ApiException(
        code: 'OTP_REQUEST_FAILED',
        message: 'ওটিপি পাঠানো যায়নি। আবার চেষ্টা করুন।',
      );
    }
    return challenge;
  }

  @override
  Future<Entitlement> verifyOtp({required String txnId, required String otp}) async {
    final data = await _api.verifyOtp(txnId: txnId, otp: otp);
    return _store(data);
  }

  @override
  Future<Entitlement> cancel() async {
    final data = await _api.cancel();
    return _store(data);
  }

  @override
  Future<Entitlement> refreshIfStale() async {
    final current = await _cache.read();

    // Inside the TTL there is nothing to do (FR-S-14).
    if (current.isFresh) return current;

    try {
      // Revalidate against the account, which needs no phone number.
      final data = await _api.entitlementForAccount();
      return _store(data);
    } on ApiException catch (e) {
      // FR-S-15 — a network or carrier failure NEVER downgrades. Keep premium,
      // flag it stale, and try again next launch. Only an authoritative `free`
      // from the server (handled in _store) takes access away.
      //
      // UNAUTHORIZED is included deliberately: the gate runs BEFORE login
      // (FR-G-01), so a user who subscribed but has not yet signed in cannot
      // be revalidated. That is a missing session, not a lapsed subscription.
      final cannotRevalidate = e.isNetworkFailure ||
          e.code == 'CARRIER_UNAVAILABLE' ||
          e.isSessionEnded;

      if (cannotRevalidate) {
        if (current.isPremium && !current.isBeyondGrace) {
          return current.copyWith(isStale: true);
        }
        return current;
      }
      rethrow;
    }
  }

  @override
  Future<void> clear() => _cache.clear();

  Future<Entitlement> _store(Map<String, dynamic> data) async {
    final raw = data['entitlement'];
    if (raw is! Map) throw const ApiException.unexpected();

    final entitlement = Entitlement.fromApi(Map<String, dynamic>.from(raw));
    await _cache.write(entitlement);
    return entitlement;
  }
}
