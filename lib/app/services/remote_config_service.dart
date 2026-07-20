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
    // FR-PH-01 — FALSE for Phase 1. Both features that carried premium value
    // (Hadith, Surah) are withheld, so there is nothing for the gate to sell
    // and charging for it would be a refund liability. Raised to true in
    // Phase 2, from the console, once the content exists.
    //
    // Also still the FR-P-07 kill switch: it turns the gate off during a
    // BDApps outage or suspended billing without shipping an APK.
    Flags.subscriptionGateEnabled: false,

    // Lets the automatic prompt count be tuned from the console once real
    // conversion data exists, without shipping a new APK.
    Flags.subscriptionGateMaxPrompts: 3,

    // Daily hadith push, once content exists (M-5).
    Flags.dailyHadithPushEnabled: false,

    // FR-PH-06 — Phase 2 features. False in the shipped binary so a device
    // that never reaches Firebase behaves exactly like Phase 1.
    Flags.hadithEnabled: false,
    Flags.surahEnabled: false,
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

  // ---- Release phasing (docs/SRS-Release-Phasing.md) ----

  /// FR-PH-10 — Hadith collection. Phase 2.
  static const hadithEnabled = 'hadith_enabled';

  /// FR-PH-11 — Surah collection. Phase 2.
  static const surahEnabled = 'surah_enabled';
}
