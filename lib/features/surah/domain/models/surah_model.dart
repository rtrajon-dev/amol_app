class SurahModel {
  final int number;
  final String arabicName;
  final String banglaName;
  final String transliteration;
  final int verseCount;
  final String revelationType;
  final List<AyahModel> ayahs;

  const SurahModel({
    required this.number,
    required this.arabicName,
    required this.banglaName,
    required this.transliteration,
    required this.verseCount,
    required this.revelationType,
    this.ayahs = const [],
  });
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
}

const popularSurahs = [
  SurahModel(number: 1, arabicName: 'الفاتحة', banglaName: 'আল-ফাতিহা', transliteration: 'Al-Fatihah', verseCount: 7, revelationType: 'Meccan'),
  SurahModel(number: 112, arabicName: 'الإخلاص', banglaName: 'আল-ইখলাস', transliteration: 'Al-Ikhlas', verseCount: 4, revelationType: 'Meccan'),
  SurahModel(number: 113, arabicName: 'الفلق', banglaName: 'আল-ফালাক', transliteration: 'Al-Falaq', verseCount: 5, revelationType: 'Meccan'),
  SurahModel(number: 114, arabicName: 'الناس', banglaName: 'আন-নাস', transliteration: 'An-Nas', verseCount: 6, revelationType: 'Meccan'),
  SurahModel(number: 2, arabicName: 'البقرة', banglaName: 'আল-বাকারা', transliteration: 'Al-Baqarah', verseCount: 286, revelationType: 'Medinan'),
  SurahModel(number: 36, arabicName: 'يس', banglaName: 'ইয়াসিন', transliteration: 'Ya-Sin', verseCount: 83, revelationType: 'Meccan'),
  SurahModel(number: 67, arabicName: 'الملك', banglaName: 'আল-মুলক', transliteration: 'Al-Mulk', verseCount: 30, revelationType: 'Meccan'),
  SurahModel(number: 55, arabicName: 'الرحمن', banglaName: 'আর-রাহমান', transliteration: 'Ar-Rahman', verseCount: 78, revelationType: 'Medinan'),
];
