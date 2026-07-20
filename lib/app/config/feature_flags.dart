import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/remote_config_service.dart';

/// Which features the current release phase exposes
/// (`docs/SRS-Release-Phasing.md`).
///
/// FR-PH-05 — the single source of truth. A withheld feature is hidden here
/// and nowhere else: its code, routes, screens and tests all stay in the tree
/// and keep working (FR-PH-08), so enabling it in Phase 2 is a flag flip
/// rather than a re-implementation.
///
/// FR-PH-06 — every flag defaults to `false` in the shipped binary and may be
/// raised by Remote Config. A device that never reaches Firebase therefore
/// behaves exactly like Phase 1, which is the safe direction to fail: a
/// feature that stays hidden disappoints, a feature that appears without its
/// content misleads.
class FeatureFlags {
  const FeatureFlags({
    required this.hadithEnabled,
    required this.surahEnabled,
    required this.subscriptionEnabled,
  });

  /// FR-PH-10 — requires a sourced, graded corpus in `hadiths.json`.
  final bool hadithEnabled;

  /// FR-PH-11 — requires all 114 surahs in `surahs_full.json`.
  final bool surahEnabled;

  /// FR-PH-01 / FR-PH-02 — the paywall and every surface that advertises it.
  /// False for Phase 1, which has no premium content to sell.
  final bool subscriptionEnabled;

  factory FeatureFlags.fromRemoteConfig(RemoteConfigService config) {
    return FeatureFlags(
      hadithEnabled: config.getBool(Flags.hadithEnabled),
      surahEnabled: config.getBool(Flags.surahEnabled),
      subscriptionEnabled: config.getBool(Flags.subscriptionGateEnabled),
    );
  }

  /// Phase 1 as shipped. Used where no container is available.
  static const phase1 = FeatureFlags(
    hadithEnabled: false,
    surahEnabled: false,
    subscriptionEnabled: false,
  );

  /// Whether [route] belongs to a feature this phase withholds.
  ///
  /// FR-PH-07 — hiding a tile is not enough. A deep link, a notification, or a
  /// back-stack entry left over from an earlier build can all target a route
  /// directly, so the route itself has to refuse.
  bool isRouteWithheld(String route) {
    if (!hadithEnabled && route.startsWith('/hadith')) return true;
    // Covers the detail route `/surah/:id` as well as the list.
    if (!surahEnabled && route.startsWith('/surah')) return true;
    if (!subscriptionEnabled && route.startsWith('/subscription')) return true;
    return false;
  }
}

final featureFlagsProvider = Provider<FeatureFlags>((ref) {
  return FeatureFlags.fromRemoteConfig(RemoteConfigService.instance);
});
