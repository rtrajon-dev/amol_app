import '../../../app/network/api_client.dart';

/// Transport for `/appbackend/v1/subscription/*`.
///
/// The client sends a phone number and an OTP; it receives a tier. It never
/// sees statusCode, S1000, REGISTERED, referenceNo, or subscriberId — the
/// server translates all of that (FR-BE-05, FR-BE-06).
class SubscriptionApi {
  SubscriptionApi(this._client);

  final ApiClient _client;

  Future<Map<String, dynamic>> status(String msisdn) =>
      _client.post('/subscription/status', body: {'msisdn': msisdn});

  Future<Map<String, dynamic>> requestOtp(String msisdn) =>
      _client.post('/subscription/otp/request', body: {'msisdn': msisdn});

  Future<Map<String, dynamic>> verifyOtp({
    required String txnId,
    required String otp,
  }) =>
      _client.post('/subscription/otp/verify', body: {
        'txnId': txnId,
        'otp': otp,
      });

  Future<Map<String, dynamic>> cancel({String? msisdn}) =>
      _client.post('/subscription/cancel', body: {'msisdn': ?msisdn});

  /// Revalidation path for a logged-in user, which needs no phone number:
  /// `/auth/me` returns the entitlement bound to the account (FR-S-21).
  ///
  /// This is a URL, not a dependency on the auth feature — M-3 and M-2 remain
  /// independent modules (SRS §4, dependency rule).
  Future<Map<String, dynamic>> entitlementForAccount() => _client.get('/auth/me');
}
