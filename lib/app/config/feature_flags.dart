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

  /// FR-G-06 — the mandatory paywall.
  ///
  /// The whole app is the paid product, so this is `true` in Phase 1 rather
  /// than waiting on premium *content*. It doubles as the FR-P-07 kill switch,
  /// and that role matters more under a hard gate than it did under a soft
  /// one: if BDApps billing fails, turning this off from the console is the
  /// only way to stop locking every user out of an app they cannot buy.
  final bool subscriptionEnabled;

  factory FeatureFlags.fromRemoteConfig(RemoteConfigService config) {
    return FeatureFlags(
      hadithEnabled: config.getBool(Flags.hadithEnabled),
      surahEnabled: config.getBool(Flags.surahEnabled),
      subscriptionEnabled: config.getBool(Flags.subscriptionGateEnabled),
    );
  }

  /// Phase 1 as shipped: content withheld, paywall on.
  static const phase1 = FeatureFlags(
    hadithEnabled: false,
    surahEnabled: false,
    subscriptionEnabled: true,
  );

  /// Whether an authenticated user must subscribe before entering the app
  /// (FR-G-06).
  ///
  /// Takes a bool rather than an `Entitlement` so `app/` keeps no dependency
  /// on the subscription feature. Stale-but-premium counts as premium: an
  /// offline subscriber inside the FR-S-15 grace window must not be locked out
  /// of something they have paid for.
  bool requiresSubscription({required bool isPremium}) =>
      subscriptionEnabled && !isPremium;

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
