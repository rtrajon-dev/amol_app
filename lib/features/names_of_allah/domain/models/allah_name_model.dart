class AllahNameModel {
  final int number;
  final String arabic;
  final String transliteration;
  final String bangla;
  final String meaning;

  const AllahNameModel({
    required this.number,
    required this.arabic,
    required this.transliteration,
    required this.bangla,
    required this.meaning,
  });

  factory AllahNameModel.fromJson(Map<String, dynamic> json) => AllahNameModel(
        number: (json['number'] as num?)?.toInt() ?? 0,
        arabic: (json['arabic'] ?? '').toString(),
        transliteration: (json['transliteration'] ?? '').toString(),
        bangla: (json['bangla'] ?? '').toString(),
        meaning: (json['meaning'] ?? '').toString(),
      );
}
