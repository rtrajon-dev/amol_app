/// A Bangladeshi district headquarters (FR-N-05).
class CityModel {
  const CityModel({
    required this.bangla,
    required this.english,
    required this.division,
    required this.latitude,
    required this.longitude,
  });

  final String bangla;
  final String english;
  final String division;
  final double latitude;
  final double longitude;

  factory CityModel.fromJson(Map<String, dynamic> json) => CityModel(
        bangla: (json['bn'] ?? '').toString(),
        english: (json['en'] ?? '').toString(),
        division: (json['division'] ?? '').toString(),
        latitude: (json['lat'] as num?)?.toDouble() ?? 0,
        longitude: (json['lng'] as num?)?.toDouble() ?? 0,
      );

  /// FR-N-05 — searchable in BOTH scripts. A user typing "syl" and a user
  /// typing "সিল" must both find Sylhet; many Bangladeshi users type city
  /// names in English on a Bangla phone.
  bool matches(String query) => matchRank(query) != null;

  /// Relevance for [query], lower is better; null means no match.
  ///
  /// Division matching is deliberately included — searching "Khulna" should
  /// surface the districts in that division. But it must rank BELOW a city
  /// name match: typing "Sylhet" also matches the three other districts of
  /// Sylhet division, and the city itself has to come first or the exact
  /// answer is buried among near-misses.
  int? matchRank(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return 2;
    final q = trimmed.toLowerCase();

    if (bangla == trimmed || english.toLowerCase() == q) return 0; // exact
    if (bangla.startsWith(trimmed) || english.toLowerCase().startsWith(q)) return 1;
    if (bangla.contains(trimmed) || english.toLowerCase().contains(q)) return 2;
    if (division.toLowerCase().contains(q)) return 3; // division only
    return null;
  }
}
