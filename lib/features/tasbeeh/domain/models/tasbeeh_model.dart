class TasbeehModel {
  final String arabic;
  final String bangla;
  final String transliteration;
  final int target;
  final int count;

  const TasbeehModel({
    required this.arabic,
    required this.bangla,
    required this.transliteration,
    this.target = 33,
    this.count = 0,
  });

  TasbeehModel copyWith({int? count}) => TasbeehModel(
        arabic: arabic,
        bangla: bangla,
        transliteration: transliteration,
        target: target,
        count: count ?? this.count,
      );

  static const presets = [
    TasbeehModel(arabic: 'سُبْحَانَ اللّٰهِ', bangla: 'সুবহানাল্লাহ', transliteration: 'Subhanallah', target: 33),
    TasbeehModel(arabic: 'اَلْحَمْدُ لِلّٰهِ', bangla: 'আলহামদুলিল্লাহ', transliteration: 'Alhamdulillah', target: 33),
    TasbeehModel(arabic: 'اَللّٰهُ اَكْبَرُ', bangla: 'আল্লাহু আকবার', transliteration: 'Allahu Akbar', target: 34),
    TasbeehModel(arabic: 'لَا إِلٰهَ إِلَّا اللّٰهُ', bangla: 'লা ইলাহা ইল্লাল্লাহ', transliteration: 'La ilaha illallah', target: 100),
    TasbeehModel(arabic: 'أَسْتَغْفِرُ اللّٰهَ', bangla: 'আস্তাগফিরুল্লাহ', transliteration: 'Astaghfirullah', target: 100),
  ];
}
