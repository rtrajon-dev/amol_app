/// What the rest of the application is allowed to know about billing.
///
/// FR-S-01 — this is the ONLY public concept. No feature module may reference
/// BDApps, MSISDN, OTP, or carrier state. When BDApps is withdrawn (M-7), this
/// file and the repository interface survive unchanged; only the data layer is
/// deleted.
library;

enum Tier { free, premium }

class Entitlement {
  const Entitlement({
    required this.tier,
    this.checkedAt,
    this.maskedMsisdn,
    this.isStale = false,
  });

  final Tier tier;

  /// When the server last confirmed this. Null means never checked.
  final DateTime? checkedAt;

  /// NFR-S-03 — masked (`017XXXXX678`); the full number is never held here.
  final String? maskedMsisdn;

  /// FR-S-15 — true when we are honouring a cached premium past its TTL
  /// because the carrier or server could not be reached. The user keeps
  /// access; the app knows the answer is old.
  final bool isStale;

  static const free = Entitlement(tier: Tier.free);

  bool get isPremium => tier == Tier.premium;

  /// FR-S-14 — cached entitlement is honoured for 24 hours before the app
  /// tries to revalidate. The frozen listener does not persist carrier
  /// callbacks (SRS O-05), so the carrier must be polled rather than trusted
  /// to push.
  static const ttl = Duration(hours: 24);

  /// FR-S-15 — after the TTL, a failure to reach the server extends access by
  /// a further 7 days rather than downgrading. A subscriber who paid must not
  /// lose premium because a shared host blipped or because they are somewhere
  /// with no signal.
  static const grace = Duration(days: 7);

  bool get isFresh {
    final at = checkedAt;
    if (at == null) return false;
    return DateTime.now().difference(at) < ttl;
  }

  /// True once even the grace period has lapsed. Only then does an unreachable
  /// server stop being an acceptable reason to keep premium.
  bool get isBeyondGrace {
    final at = checkedAt;
    if (at == null) return true;
    return DateTime.now().difference(at) > (ttl + grace);
  }

  Entitlement copyWith({Tier? tier, DateTime? checkedAt, String? maskedMsisdn, bool? isStale}) =>
      Entitlement(
        tier: tier ?? this.tier,
        checkedAt: checkedAt ?? this.checkedAt,
        maskedMsisdn: maskedMsisdn ?? this.maskedMsisdn,
        isStale: isStale ?? this.isStale,
      );

  Map<String, dynamic> toJson() => {
        'tier': tier.name,
        'checkedAt': checkedAt?.toIso8601String(),
        'maskedMsisdn': maskedMsisdn,
      };

  factory Entitlement.fromJson(Map<String, dynamic> json) {
    final rawCheckedAt = json['checkedAt'];
    return Entitlement(
      tier: json['tier'] == Tier.premium.name ? Tier.premium : Tier.free,
      checkedAt: rawCheckedAt is String ? DateTime.tryParse(rawCheckedAt) : null,
      maskedMsisdn: json['maskedMsisdn'] as String?,
    );
  }

  /// Server payload → domain. The server already speaks in tiers (FR-BE-05),
  /// so no carrier vocabulary is interpreted here.
  factory Entitlement.fromApi(Map<String, dynamic> json) {
    final rawCheckedAt = json['checkedAt'];
    return Entitlement(
      tier: json['tier'] == 'premium' ? Tier.premium : Tier.free,
      checkedAt: rawCheckedAt is String
          ? (DateTime.tryParse(rawCheckedAt)?.toLocal() ?? DateTime.now())
          : DateTime.now(),
      maskedMsisdn: json['msisdn'] as String?,
    );
  }
}
