import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

import 'firebase_service.dart';

/// Firebase Remote Config (FR-P-07) — feature flags and kill switches.
///
/// Every flag has a local default that is used verbatim when Firebase is
/// unavailable, so behaviour is fully defined without a network fetch. The
/// defaults are chosen so that a fetch failure preserves the shipped
/// behaviour rather than silently changing it.
class RemoteConfigService {
  RemoteConfigService._();
  static final instance = RemoteConfigService._();

  FirebaseRemoteConfig? _config;

  bool get _ready => FirebaseService.instance.isAvailable && _config != null;

  static const _defaults = <String, dynamic>{
    // FR-P-07 — kill switch. Lets the subscription gate be disabled entirely
    // without an app release, e.g. if BDApps has an outage or billing is
    // suspended. Default true = shipped behaviour.
    Flags.subscriptionGateEnabled: true,

    // Lets the automatic prompt count be tuned from the console once real
    // conversion data exists, without shipping a new APK.
    Flags.subscriptionGateMaxPrompts: 3,

    // Daily hadith push, once content exists (M-5).
    Flags.dailyHadithPushEnabled: false,
  };

  Future<void> initialize() async {
    if (!FirebaseService.instance.isAvailable) return;

    try {
      _config = FirebaseRemoteConfig.instance;
      await _config?.setDefaults(_defaults);
      await _config?.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        // Cheap enough to refresh hourly; a kill switch that takes a day to
        // take effect is not a kill switch.
        minimumFetchInterval: const Duration(hours: 1),
      ));
      await _config?.fetchAndActivate();
    } catch (e) {
      // Defaults remain in force.
      debugPrint('RemoteConfig: unavailable ($e) — using local defaults');
    }
  }

  bool getBool(String key) {
    if (!_ready) return _defaults[key] as bool? ?? false;
    try {
      return _config!.getBool(key);
    } catch (_) {
      return _defaults[key] as bool? ?? false;
    }
  }

  int getInt(String key) {
    if (!_ready) return _defaults[key] as int? ?? 0;
    try {
      return _config!.getInt(key);
    } catch (_) {
      return _defaults[key] as int? ?? 0;
    }
  }
}

abstract class Flags {
  static const subscriptionGateEnabled = 'subscription_gate_enabled';
  static const subscriptionGateMaxPrompts = 'subscription_gate_max_prompts';
  static const dailyHadithPushEnabled = 'daily_hadith_push_enabled';
}
