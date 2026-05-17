/// Simple Hijri date calculator (Tabular Islamic Calendar approximation)
class HijriDate {
  final int day;
  final int month;
  final int year;

  const HijriDate({required this.day, required this.month, required this.year});

  static HijriDate now() => fromGregorian(DateTime.now());

  static HijriDate fromGregorian(DateTime date) {
    // Fliegel & Van Flandern algorithm
    final jd = _gregorianToJulian(date.year, date.month, date.day);
    return _julianToHijri(jd);
  }

  static int _gregorianToJulian(int y, int m, int d) {
    final a = ((14 - m) / 12).floor();
    final yr = y + 4800 - a;
    final mo = m + 12 * a - 3;
    return d + ((153 * mo + 2) / 5).floor() + 365 * yr + (yr / 4).floor() - (yr / 100).floor() + (yr / 400).floor() - 32045;
  }

  static HijriDate _julianToHijri(int jd) {
    final l = jd - 1948440 + 10632;
    final n = ((l - 1) / 10631).floor();
    final l2 = l - 10631 * n + 354;
    final j = (((10985 - l2) / 5316).floor() * ((50 * l2) / 17719).floor()) -
        (((l2) / 5670).floor() * ((43 * l2) / 15238).floor());
    final l3 = l2 - (((30 - j) / 15).floor() * ((17719 * j) / 50).floor()) +
        (((j) / 16).floor() * ((15238 * j) / 43).floor()) - 30;
    final m = ((24 * l3) / 709).floor();
    final d = l3 - ((709 * m) / 24).floor();
    final y = 30 * n + j - 30;
    return HijriDate(day: d, month: m, year: y);
  }

  static const monthNamesBangla = [
    'মুহাররম', 'সফর', 'রবিউল আউয়াল', 'রবিউস সানি',
    'জুমাদাল উলা', 'জুমাদাল উখরা', 'রজব', 'শাবান',
    'রমজান', 'শাওয়াল', 'জিলকদ', 'জিলহজ',
  ];

  static const monthNames = [
    'Muharram', 'Safar', 'Rabi al-Awwal', 'Rabi al-Thani',
    'Jumada al-Awwal', 'Jumada al-Thani', 'Rajab', 'Shaban',
    'Ramadan', 'Shawwal', 'Dhul Qadah', 'Dhul Hijjah',
  ];

  String get monthNameBangla => month >= 1 && month <= 12 ? monthNamesBangla[month - 1] : '';
  String get monthName => month >= 1 && month <= 12 ? monthNames[month - 1] : '';

  @override
  String toString() => '$day $monthNameBangla $year';
}
