import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/viewmodel/auth_viewmodel.dart';
import '../../features/subscription/presentation/viewmodel/subscription_viewmodel.dart';

/// Cross-module coordination between auth (M-2) and subscription (M-3).
///
/// Those two modules must not import each other (SRS §4, dependency rule) —
/// M-4 is the only layer permitted to know about both, and this is it.
///
/// EC-17 — entitlement is bound to the ACCOUNT, not the device. When a session
/// ends, cached premium must be dropped, otherwise the next person to log in
/// on the same phone inherits the previous user's subscription.
final sessionCoordinatorProvider = Provider<void>((ref) {
  ref.listen(authProvider, (previous, next) {
    final wasSignedIn = previous?.isAuthenticated ?? false;
    final isSignedOut = !next.isAuthenticated;

    if (wasSignedIn && isSignedOut) {
      ref.read(entitlementProvider.notifier).clear();

      // The FR-S-09 prompt allowance starts over. That cap exists so the gate
      // cannot nag someone into uninstalling, and it still holds within a
      // session — but a logout begins a new one, often a different person on a
      // shared phone. Carrying an exhausted counter across it would mean the
      // next user is never offered the subscription at all.
      SubscriptionGatePolicy.reset();
    }

    // A new sign-in revalidates rather than trusting whatever was cached:
    // the incoming account may have a different entitlement entirely.
    final signedIn = !(previous?.isAuthenticated ?? false) && next.isAuthenticated;
    if (signedIn) {
      ref.read(entitlementProvider.notifier).unawaitedRevalidate();
    }
  });
});
