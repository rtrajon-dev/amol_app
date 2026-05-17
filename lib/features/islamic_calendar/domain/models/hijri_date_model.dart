class HijriDateModel {
  final int day;
  final int month;
  final int year;
  final String monthName;
  final String monthNameBangla;

  const HijriDateModel({
    required this.day,
    required this.month,
    required this.year,
    required this.monthName,
    required this.monthNameBangla,
  });

  static const monthNames = [
    'Muharram', 'Safar', 'Rabi al-Awwal', 'Rabi al-Thani',
    'Jumada al-Awwal', 'Jumada al-Thani', 'Rajab', 'Shaban',
    'Ramadan', 'Shawwal', 'Dhul Qadah', 'Dhul Hijjah',
  ];

  static const monthNamesBangla = [
    'মুহাররম', 'সফর', 'রবিউল আউয়াল', 'রবিউস সানি',
    'জুমাদাল উলা', 'জুমাদাল উখরা', 'রজব', 'শাবান',
    'রমজান', 'শাওয়াল', 'জিলকদ', 'জিলহজ',
  ];
}

class IslamicEvent {
  final String name;
  final String nameBangla;
  final int hijriMonth;
  final int hijriDay;

  const IslamicEvent({required this.name, required this.nameBangla, required this.hijriMonth, required this.hijriDay});

  static const events = [
    IslamicEvent(name: 'Eid ul Fitr', nameBangla: 'ঈদুল ফিতর', hijriMonth: 10, hijriDay: 1),
    IslamicEvent(name: 'Eid ul Adha', nameBangla: 'ঈদুল আযহা', hijriMonth: 12, hijriDay: 10),
    IslamicEvent(name: 'Shab-e-Barat', nameBangla: 'শবে বরাত', hijriMonth: 8, hijriDay: 15),
    IslamicEvent(name: 'Shab-e-Qadr', nameBangla: 'শবে কদর', hijriMonth: 9, hijriDay: 27),
    IslamicEvent(name: 'Ramadan Start', nameBangla: 'রমজান শুরু', hijriMonth: 9, hijriDay: 1),
    IslamicEvent(name: 'Ashura', nameBangla: 'আশুরা', hijriMonth: 1, hijriDay: 10),
  ];
}
