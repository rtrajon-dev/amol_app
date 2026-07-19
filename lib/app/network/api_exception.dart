/// A typed failure carrying a Bangla message that is safe to show the user.
///
/// FR-A-11 / C-BE-07 — every failure surfaces a specific Bangla message.
/// Generic exception text, HTTP status codes, and English server strings SHALL
/// NOT reach the UI. The server already sends Bangla in `error.message`; this
/// class supplies Bangla for failures that never reach the server (no network,
/// timeout, unparseable response).
class ApiException implements Exception {
  const ApiException({
    required this.code,
    required this.message,
    this.statusCode,
    this.retryAfterSeconds,
  });

  /// Stable machine code from the server envelope, or a client-side code.
  final String code;

  /// Bangla, displayable verbatim.
  final String message;

  final int? statusCode;
  final int? retryAfterSeconds;

  // ---- client-side codes (never produced by the server) ----
  static const codeNoNetwork = 'NO_NETWORK';
  static const codeTimeout = 'TIMEOUT';
  static const codeUnexpected = 'UNEXPECTED';

  // ---- server codes the client reacts to structurally ----
  static const codeTokenExpired = 'TOKEN_EXPIRED';
  static const codeTokenRevoked = 'TOKEN_REVOKED';
  static const codeUnauthorized = 'UNAUTHORIZED';
  static const codeUpdateRequired = 'APP_UPDATE_REQUIRED';

  const ApiException.noNetwork()
      : code = codeNoNetwork,
        message = 'ইন্টারনেট সংযোগ পাওয়া যাচ্ছে না।',
        statusCode = null,
        retryAfterSeconds = null;

  const ApiException.timeout()
      : code = codeTimeout,
        message = 'সার্ভারে সংযোগ করা যাচ্ছে না। আবার চেষ্টা করুন।',
        statusCode = null,
        retryAfterSeconds = null;

  const ApiException.unexpected()
      : code = codeUnexpected,
        message = 'কিছু একটা সমস্যা হয়েছে। আবার চেষ্টা করুন।',
        statusCode = null,
        retryAfterSeconds = null;

  /// True when the failure is a connectivity problem rather than a server
  /// verdict. FR-A-06 and FR-S-15 both hinge on this distinction: a network
  /// failure must never log the user out or downgrade their entitlement.
  bool get isNetworkFailure => code == codeNoNetwork || code == codeTimeout;

  /// True when the server has authoritatively ended the session.
  bool get isSessionEnded =>
      code == codeTokenRevoked || code == codeUnauthorized;

  @override
  String toString() => 'ApiException($code): $message';
}
