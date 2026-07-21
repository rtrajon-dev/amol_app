import 'app_user.dart';

/// The contract the presentation layer depends on.
///
/// C-BE-06 / FR-R-02 in spirit: screens and view-models talk to this
/// interface, never to `dio`, URLs, or JSON. Swapping the backend is an
/// implementation change behind this boundary.
///
/// Every method throws `ApiException` on failure — the message is Bangla and
/// displayable verbatim (FR-A-11).
abstract class AuthRepository {
  /// FR-A-01 — create an account and start a session.
  Future<AppUser> register({
    required String email,
    required String password,
    required String msisdn,
    String? displayName,
  });

  /// FR-A-03 — exchange credentials for a session.
  Future<AppUser> login({required String email, required String password});

  /// FR-A-08 — revoke the session server-side and clear local tokens.
  Future<void> logout();

  /// FR-A-09 — request a reset email. Always succeeds from the caller's point
  /// of view, whether or not the address is registered (anti-enumeration).
  Future<void> forgotPassword(String email);

  /// Fetch the current user from the server. Throws if the session is invalid.
  Future<AppUser> me();

  /// True when a session exists on this device.
  ///
  /// FR-A-06 — local check only. Never performs a network call, so a user with
  /// no connectivity still reaches Home.
  Future<bool> hasLocalSession();

  /// FR-A-12 — soft-delete the account and revoke all sessions.
  Future<void> deleteAccount(String password);
}
