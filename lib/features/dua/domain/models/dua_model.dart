enum DuaCategory {
  morningAzkar,
  eveningAzkar,
  afterPrayer,
  dailyLife,
  protection,
  food,
  sleep,
  travel,
  sickness,
}

extension DuaCategoryExt on DuaCategory {
  String get banglaName {
    switch (this) {
      case DuaCategory.morningAzkar: return 'সকালের আযকার';
      case DuaCategory.eveningAzkar: return 'সন্ধ্যার আযকার';
      case DuaCategory.afterPrayer: return 'নামাজের পর';
      case DuaCategory.dailyLife: return 'দৈনন্দিন জীবন';
      case DuaCategory.protection: return 'সুরক্ষার দোয়া';
      case DuaCategory.food: return 'খাবারের দোয়া';
      case DuaCategory.sleep: return 'ঘুমের দোয়া';
      case DuaCategory.travel: return 'সফরের দোয়া';
      case DuaCategory.sickness: return 'অসুস্থতার দোয়া';
    }
  }
}

class DuaModel {
  final String id;
  final String arabic;
  final String transliteration;
  final String bangla;
  final String source;
  final DuaCategory category;
  final bool isFavorite;

  const DuaModel({
    required this.id,
    required this.arabic,
    required this.transliteration,
    required this.bangla,
    required this.source,
    required this.category,
    this.isFavorite = false,
  });

  DuaModel copyWith({bool? isFavorite}) => DuaModel(
        id: id,
        arabic: arabic,
        transliteration: transliteration,
        bangla: bangla,
        source: source,
        category: category,
        isFavorite: isFavorite ?? this.isFavorite,
      );
}
