enum AmalType { namaz, quran, tasbeeh, tahajjud, sunnah, dua, fasting }

class AmalItemModel {
  final String id;
  final String title;
  final String subtitle;
  final AmalType type;
  final bool isCompleted;
  final bool isPremium;

  const AmalItemModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    this.isCompleted = false,
    this.isPremium = false,
  });

  AmalItemModel copyWith({bool? isCompleted}) => AmalItemModel(
        id: id,
        title: title,
        subtitle: subtitle,
        type: type,
        isCompleted: isCompleted ?? this.isCompleted,
        isPremium: isPremium,
      );

  static List<AmalItemModel> get defaultList => const [
        AmalItemModel(id: 'fajr', title: 'ফজর নামাজ', subtitle: 'সময়মতো আদায় করুন', type: AmalType.namaz),
        AmalItemModel(id: 'dhuhr', title: 'যোহর নামাজ', subtitle: 'জামাতে আদায় করুন', type: AmalType.namaz),
        AmalItemModel(id: 'asr', title: 'আসর নামাজ', subtitle: 'সময়মতো আদায় করুন', type: AmalType.namaz),
        AmalItemModel(id: 'maghrib', title: 'মাগরিব নামাজ', subtitle: 'সময়মতো আদায় করুন', type: AmalType.namaz),
        AmalItemModel(id: 'isha', title: 'এশা নামাজ', subtitle: 'সময়মতো আদায় করুন', type: AmalType.namaz),
        AmalItemModel(id: 'quran', title: 'কুরআন তিলাওয়াত', subtitle: 'কমপক্ষে ১ পৃষ্ঠা', type: AmalType.quran),
        AmalItemModel(id: 'morning_azkar', title: 'সকালের আযকার', subtitle: 'ফজরের পরে', type: AmalType.dua),
        AmalItemModel(id: 'evening_azkar', title: 'সন্ধ্যার আযকার', subtitle: 'আসরের পরে', type: AmalType.dua),
        AmalItemModel(id: 'tahajjud', title: 'তাহাজ্জুদ', subtitle: 'রাতের শেষ তৃতীয়াংশে', type: AmalType.tahajjud, isPremium: true),
      ];
}
