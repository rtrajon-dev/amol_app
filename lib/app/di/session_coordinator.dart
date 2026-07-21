import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/viewmodel/auth_viewmodel.dart';
import '../../features/prayer_time/presentation/viewmodel/prayer_time_viewmodel.dart';
import '../../features/subscription/presentation/viewmodel/subscription_viewmodel.dart';
import '../services/notification_service.dart';

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

  // FR-G-06 — the whole app is the paid product, azan included. Pending alarms
  // outlive the app process, so losing entitlement has to actively cancel them;
  // otherwise a lapsed user keeps receiving the paid feature indefinitely and
  // the only enforcement is a screen they never open.
  //
  // The reverse matters just as much: alarms are rescheduled the moment a
  // subscription lands, so a new subscriber does not silently miss prayers
  // until something else happens to trigger a reschedule.
  ref.listen(entitlementProvider, (previous, next) {
    final was = previous?.isPremium ?? false;
    if (was == next.isPremium) return;

    if (next.isPremium) {
      ref.read(azanSchedulerProvider).rescheduleAll();
    } else {
      NotificationService.instance.cancelAzan();
    }
  });
});
