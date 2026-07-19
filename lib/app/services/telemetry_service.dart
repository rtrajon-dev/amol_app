import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import 'firebase_service.dart';

/// Crashlytics + Analytics (FR-P-05, FR-P-06).
///
/// Every method is a no-op when Firebase is unavailable, so callers never need
/// to check first.
///
/// **What must never be recorded here:** access or refresh tokens, passwords,
/// OTP values, `referenceNo`, BDApps credentials, or full phone numbers
/// (FR-P-05, NFR-BE-07). Location is never collected at all — coordinates do
/// not leave the device (`docs/SRS.md` NFR-09).
class TelemetryService {
  TelemetryService._();
  static final instance = TelemetryService._();

  FirebaseAnalytics? _analytics;
  FirebaseCrashlytics? _crashlytics;

  bool get _ready => FirebaseService.instance.isAvailable;

  Future<void> initialize() async {
    if (!_ready) return;

    try {
      _analytics = FirebaseAnalytics.instance;
      _crashlytics = FirebaseCrashlytics.instance;

      // Route Flutter framework errors and uncaught async errors to
      // Crashlytics. In debug they still print to the console.
      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        _crashlytics?.recordFlutterFatalError(details);
      };
      PlatformDispatcher.instance.onError = (error, stack) {
        _crashlytics?.recordError(error, stack, fatal: true);
        return true;
      };

      await _crashlytics?.setCrashlyticsCollectionEnabled(!kDebugMode);
    } catch (e) {
      debugPrint('Telemetry: initialisation failed ($e)');
    }
  }

  /// Ties crashes to an account for support. The user id is an opaque integer,
  /// never the email or phone number.
  Future<void> setUser(int? userId) async {
    if (!_ready) return;
    try {
      await _crashlytics?.setUserIdentifier(userId?.toString() ?? '');
      await _analytics?.setUserId(id: userId?.toString());
    } catch (_) {}
  }

  Future<void> setPremium(bool isPremium) async {
    if (!_ready) return;
    try {
      await _analytics?.setUserProperty(
        name: 'tier',
        value: isPremium ? 'premium' : 'free',
      );
    } catch (_) {}
  }

  Future<void> logEvent(String name, [Map<String, Object>? params]) async {
    if (!_ready) return;
    try {
      await _analytics?.logEvent(name: name, parameters: params);
    } catch (_) {}
  }

  Future<void> recordError(Object error, StackTrace? stack, {String? context}) async {
    if (!_ready) return;
    try {
      await _crashlytics?.recordError(error, stack, reason: context);
    } catch (_) {}
  }
}

/// FR-P-06 — the conversion funnel.
///
/// Named centrally so the events stay consistent; a funnel assembled from
/// ad-hoc string literals stops being comparable the moment someone typos one.
abstract class AnalyticsEvents {
  // Subscription funnel (FR-S-09/S-10 depend on reading this honestly).
  static const gateShown = 'sub_gate_shown';
  static const gateDismissed = 'sub_gate_dismissed';
  static const phoneSubmitted = 'sub_phone_submitted';
  static const alreadySubscribed = 'sub_already_subscribed';
  static const otpRequested = 'sub_otp_requested';
  static const otpFailed = 'sub_otp_failed';
  static const subscribed = 'sub_subscribed';
  static const cancelled = 'sub_cancelled';

  // Auth.
  static const registered = 'auth_registered';
  static const loggedIn = 'auth_logged_in';

  // Premium interest — which locked feature drove the tap.
  static const premiumLockTapped = 'premium_lock_tapped';
}
