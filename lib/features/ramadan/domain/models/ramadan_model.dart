class RamadanModel {
  final int dayNumber;
  final String sehriTime;
  final String iftarTime;
  final bool isSehriCompleted;
  final bool isIftarCompleted;

  const RamadanModel({
    required this.dayNumber,
    required this.sehriTime,
    required this.iftarTime,
    this.isSehriCompleted = false,
    this.isIftarCompleted = false,
  });
}

class RamadanAmalItem {
  final String id;
  final String title;
  final bool isCompleted;

  const RamadanAmalItem({required this.id, required this.title, this.isCompleted = false});

  RamadanAmalItem copyWith({bool? isCompleted}) => RamadanAmalItem(
        id: id,
        title: title,
        isCompleted: isCompleted ?? this.isCompleted,
      );

  static const defaultList = [
    RamadanAmalItem(id: 'tarawih', title: 'তারাবির নামাজ'),
    RamadanAmalItem(id: 'quran_page', title: 'কুরআন তিলাওয়াত (১ পারা)'),
    RamadanAmalItem(id: 'sehri', title: 'সেহরি করা'),
    RamadanAmalItem(id: 'iftar_dua', title: 'ইফতারের দোয়া'),
    RamadanAmalItem(id: 'tahajjud', title: 'তাহাজ্জুদ'),
    RamadanAmalItem(id: 'laylat_qadr', title: 'শবে কদরের ইবাদত'),
  ];
}
