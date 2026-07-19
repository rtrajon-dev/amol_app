import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'firebase_service.dart';

/// Firebase Cloud Messaging (FR-P-01 … FR-P-03).
///
/// **Azan notifications do NOT go through here** (FR-P-04). Those are local,
/// scheduled on-device via `flutter_local_notifications`, and must keep
/// working with no network — a prayer alert that depends on connectivity is
/// useless to the rural user this app is built for.
///
/// FCM carries only *optional* content: the daily hadith and Ramadan alerts.
class PushService {
  PushService._();
  static final instance = PushService._();

  FirebaseMessaging? _messaging;

  /// Set by the app layer so a tapped notification can navigate.
  void Function(String route)? onNotificationRoute;

  /// Held until the router is ready — a notification tapped on a cold start
  /// arrives before there is anything to navigate (FR-G-07).
  String? _pendingRoute;

  bool get _ready => FirebaseService.instance.isAvailable;

  Future<void> initialize() async {
    if (!_ready) return;

    try {
      _messaging = FirebaseMessaging.instance;

      // A notification that launched the app from terminated state.
      final initial = await _messaging?.getInitialMessage();
      if (initial != null) _handleTap(initial);

      FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);
    } catch (e) {
      debugPrint('Push: initialisation failed ($e)');
    }
  }

  /// FR-P-03 — permission is requested when the user first ENABLES a push
  /// feature, never at startup. Asking on launch, before any value has been
  /// shown, is how apps get permanently denied.
  ///
  /// Returns true when notifications are authorised.
  Future<bool> requestPermission() async {
    if (!_ready) return false;

    try {
      final settings = await _messaging?.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      final status = settings?.authorizationStatus;
      return status == AuthorizationStatus.authorized ||
          status == AuthorizationStatus.provisional;
    } catch (e) {
      debugPrint('Push: permission request failed ($e)');
      return false;
    }
  }

  Future<bool> hasPermission() async {
    if (!_ready) return false;
    try {
      final settings = await _messaging?.getNotificationSettings();
      return settings?.authorizationStatus == AuthorizationStatus.authorized;
    } catch (_) {
      return false;
    }
  }

  /// The device token to register with the backend (`/device/register`).
  Future<String?> token() async {
    if (!_ready) return null;
    try {
      return await _messaging?.getToken();
    } catch (e) {
      debugPrint('Push: token unavailable ($e)');
      return null;
    }
  }

  /// FCM rotates tokens; the backend must be told or pushes silently stop.
  Stream<String> get tokenRefreshes =>
      _ready ? FirebaseMessaging.instance.onTokenRefresh : const Stream.empty();

  /// Consume a route captured before the router existed (FR-G-07).
  String? takePendingRoute() {
    final route = _pendingRoute;
    _pendingRoute = null;
    return route;
  }

  void _handleTap(RemoteMessage message) {
    final route = message.data['route'];
    if (route is! String || route.isEmpty) return;

    final handler = onNotificationRoute;
    if (handler != null) {
      handler(route);
    } else {
      // Router not ready yet — hold it rather than dropping it.
      _pendingRoute = route;
    }
  }
}
