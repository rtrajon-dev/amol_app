import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/viewmodel/auth_viewmodel.dart';
import '../../features/subscription/presentation/viewmodel/subscription_viewmodel.dart';
import '../network/api_exception.dart';
import '../services/push_service.dart';
import '../services/telemetry_service.dart';
import 'providers.dart';

/// Keeps the backend's copy of this device's FCM token current (FR-P-01).
///
/// Registration is deliberately best-effort: a failure here means the user
/// misses an optional daily hadith, which must never surface as an error or
/// block anything. Azan notifications are local and unaffected (FR-P-04).
final pushRegistrarProvider = Provider<void>((ref) {
  StreamSubscription<String>? refreshSubscription;

  Future<void> register(String token) async {
    try {
      await ref.read(apiClientProvider).post(
        '/device/register',
        body: {'fcmToken': token},
      );
    } on ApiException {
      // Silent by design.
    } catch (_) {}
  }

  Future<void> syncToken() async {
    final token = await PushService.instance.token();
    if (token != null && token.isNotEmpty) await register(token);
  }

  // Register once a session exists, so the token is bound to the account.
  ref.listen(authProvider, (previous, next) {
    final justSignedIn =
        !(previous?.isAuthenticated ?? false) && next.isAuthenticated;
    if (justSignedIn) {
      syncToken();
      TelemetryService.instance.setUser(next.user?.id);
    }
    if ((previous?.isAuthenticated ?? false) && !next.isAuthenticated) {
      TelemetryService.instance.setUser(null);
    }
  });

  // Keep the analytics tier property in step with entitlement.
  ref.listen(entitlementProvider, (_, next) {
    TelemetryService.instance.setPremium(next.isPremium);
  });

  // FCM rotates tokens; without this, pushes silently stop reaching a device.
  refreshSubscription = PushService.instance.tokenRefreshes.listen(register);
  ref.onDispose(() => refreshSubscription?.cancel());
});
