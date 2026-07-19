import 'entitlement.dart';

/// FR-S-01, FR-R-01, FR-R-03 — the seam BDApps is removed behind.
///
/// Replacing BDApps means writing a new class that implements this interface
/// and binding it to `subscriptionRepositoryProvider`. Candidates named in the
/// SRS: `AlwaysPremiumRepository` (billing withdrawn), `IapSubscriptionRepository`
/// (Play Billing / StoreKit — required for iOS, see SRS OQ-05), or
/// `ServerEntitlementRepository` (entitlement from /auth/me alone).
///
/// Everything here throws `ApiException` on failure; its message is Bangla and
/// displayable verbatim.
abstract class SubscriptionRepository {
  /// Locally cached entitlement. Synchronous-ish and never hits the network —
  /// feature gating must not await I/O (NFR-S-04).
  Future<Entitlement> cached();

  /// FR-S-03 — ask the server about a phone number.
  ///
  /// FR-S-19: a number subscribed on the Amol365 *web* app returns premium
  /// here with no OTP and no second charge.
  Future<Entitlement> checkStatus(String msisdn);

  /// FR-S-04 — begin an OTP subscribe. Returns an opaque transaction id; the
  /// BDApps referenceNo never reaches this device (FR-BE-06).
  Future<OtpChallenge> requestOtp(String msisdn);

  /// FR-S-06 — complete the subscribe.
  Future<Entitlement> verifyOtp({required String txnId, required String otp});

  /// FR-S-11 / FR-S-20 — cancel. This is GLOBAL: it ends web access too.
  Future<Entitlement> cancel();

  /// Revalidate the cached entitlement if it is past its TTL.
  ///
  /// FR-S-15 — a network or carrier failure must NOT downgrade the user; only
  /// an authoritative `free` from the server does.
  Future<Entitlement> refreshIfStale();

  /// Drop local entitlement (called on logout).
  Future<void> clear();
}

/// The client-visible half of an OTP request. Deliberately carries no
/// carrier state — no referenceNo, no subscriberId.
class OtpChallenge {
  const OtpChallenge({
    required this.txnId,
    this.resendAfterSeconds = 60,
    this.expiresInSeconds = 600,
  });

  final String txnId;
  final int resendAfterSeconds;
  final int expiresInSeconds;

  factory OtpChallenge.fromJson(Map<String, dynamic> json) => OtpChallenge(
        txnId: (json['txnId'] ?? '').toString(),
        resendAfterSeconds: (json['resendAfterSeconds'] as num?)?.toInt() ?? 60,
        expiresInSeconds: (json['expiresInSeconds'] as num?)?.toInt() ?? 600,
      );
}
