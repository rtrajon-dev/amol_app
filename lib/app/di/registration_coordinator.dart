import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/viewmodel/auth_viewmodel.dart';
import '../../features/subscription/presentation/viewmodel/subscription_viewmodel.dart';
import 'providers.dart';

/// True while a freshly authenticated session is still waiting to learn whether
/// it has a subscription.
///
/// The router holds navigation on this. Without it, `authProvider` flipping to
/// authenticated would immediately redirect to the paywall, and the status
/// check would arrive a moment later and bounce the user to Home — so someone
/// who already pays would be shown a "৫ টাকা কাটা হবে" screen for a second
/// before it vanished. That flash is exactly what this flow exists to prevent.
final subscriptionResolvingProvider =
    NotifierProvider<_FlagNotifier, bool>(_FlagNotifier.new);

/// Set when a status check found an existing subscription, so Home can say so
/// once. Consumed by the reader.
final subscriptionRecognisedProvider =
    NotifierProvider<_FlagNotifier, bool>(_FlagNotifier.new);

/// Riverpod 3 has no StateProvider; a boolean still needs a Notifier.
class _FlagNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

/// Registration, plus the subscription lookup that has to follow it.
///
/// Lives in `app/di` because it spans auth (M-2) and subscription (M-3), which
/// are forbidden from importing each other (SRS §4). Same rule that puts
/// `sessionCoordinatorProvider` here.
class RegistrationCoordinator {
  RegistrationCoordinator(this._ref);

  final Ref _ref;

  /// Creates the account, then resolves entitlement for [msisdn] before the
  /// router is allowed to route anywhere.
  ///
  /// Returns false only when registration itself failed; the auth layer holds
  /// the Bangla message.
  Future<bool> register({
    required String email,
    required String password,
    required String msisdn,
    String? displayName,
  }) async {
    _ref.read(subscriptionResolvingProvider.notifier).set(true);

    try {
      final created = await _ref.read(authProvider.notifier).register(
            email: email,
            password: password,
            msisdn: msisdn,
            displayName: displayName,
          );

      if (!created) return false;

      await _resolveEntitlement(msisdn);
      return true;
    } finally {
      // Released in every path. Leaving this true would strand the user on the
      // registration screen behind a spinner with no way forward.
      _ref.read(subscriptionResolvingProvider.notifier).set(false);
    }
  }

  /// Asks the server whether [msisdn] already has a subscription.
  ///
  /// This is the web-subscriber path (FR-S-19): a number that already pays
  /// resolves to premium here with no OTP and no second charge.
  Future<void> _resolveEntitlement(String msisdn) async {
    try {
      final entitlement = await _ref
          .read(subscriptionRepositoryProvider)
          .checkStatus(msisdn);

      _ref.read(entitlementProvider.notifier).set(entitlement);

      if (entitlement.isPremium) {
        _ref.read(subscriptionRecognisedProvider.notifier).set(true);
      }
    } catch (_) {
      // Deliberately catches everything, not just ApiException. The account is
      // already created at this point, so ANY failure here — carrier down, a
      // malformed response, a bug in parsing — must leave the user registered
      // and simply send them to the gate, where they can try again. Letting it
      // propagate would report a failed registration that actually succeeded,
      // and they would be unable to register again with the same email.
    }
  }
}

final registrationCoordinatorProvider = Provider<RegistrationCoordinator>(
  RegistrationCoordinator.new,
);
