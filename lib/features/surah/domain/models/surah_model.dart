class SurahModel {
  final int number;
  final String arabicName;
  final String banglaName;
  final String transliteration;
  final int verseCount;
  final String revelationType;
  final String banglaMeaning;

  /// True for a passage extracted from a longer surah (e.g. Ayat al-Kursi),
  /// so the UI can label it honestly rather than implying a complete surah.
  final bool isPassage;
  final String passageNote;

  final List<AyahModel> ayahs;

  const SurahModel({
    required this.number,
    required this.arabicName,
    required this.banglaName,
    required this.transliteration,
    required this.verseCount,
    required this.revelationType,
    this.banglaMeaning = '',
    this.isPassage = false,
    this.passageNote = '',
    this.ayahs = const [],
  });

  factory SurahModel.fromJson(Map<String, dynamic> json) {
    final rawAyahs = json['ayahs'];
    return SurahModel(
      number: (json['number'] as num?)?.toInt() ?? 0,
      arabicName: (json['arabicName'] ?? '').toString(),
      banglaName: (json['banglaName'] ?? '').toString(),
      transliteration: (json['transliteration'] ?? '').toString(),
      verseCount: (json['verseCount'] as num?)?.toInt() ?? 0,
      revelationType: (json['revelationType'] ?? '').toString(),
      banglaMeaning: (json['banglaMeaning'] ?? '').toString(),
      isPassage: json['isPassage'] == true,
      passageNote: (json['passageNote'] ?? '').toString(),
      ayahs: rawAyahs is List
          ? rawAyahs
              .whereType<Map>()
              .map((a) => AyahModel.fromJson(Map<String, dynamic>.from(a)))
              .toList()
          : const [],
    );
  }

  /// Bangla label for where the text was revealed.
  String get revelationBangla =>
      revelationType.toLowerCase() == 'meccan' ? 'মাক্কি' : 'মাদানি';
}

class AyahModel {
  final int number;
  final String arabic;
  final String bangla;
  final String transliteration;

  const AyahModel({
    required this.number,
    required this.arabic,
    required this.bangla,
    required this.transliteration,
  });

  factory AyahModel.fromJson(Map<String, dynamic> json) => AyahModel(
        number: (json['number'] as num?)?.toInt() ?? 0,
        arabic: (json['arabic'] ?? '').toString(),
        bangla: (json['bangla'] ?? '').toString(),
        transliteration: (json['transliteration'] ?? '').toString(),
      );
}
