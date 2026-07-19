abstract class AppRoutes {
  static const home = '/';
  static const splash = '/splash';
  static const onboarding = '/onboarding';

  // Auth (M-2). These sit between onboarding and Home in the startup
  // sequence; the subscription gate (M-3/M-4) will be inserted before them.
  /// M-3/M-4 — the optional subscription gate. Sits before login in the
  /// startup sequence, and is also reachable from Settings and locked
  /// features (FR-S-10).
  static const subscription = '/subscription';

  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';

  static const prayerTime = '/prayer-time';
  static const tasbeeh = '/tasbeeh';
  static const amalTracker = '/amal-tracker';
  static const qibla = '/qibla';
  static const hadith = '/hadith';
  static const islamicCalendar = '/calendar';
  static const namesOfAllah = '/names-of-allah';
  static const surah = '/surah';
  static const surahDetail = '/surah/:id';
  static const ramadan = '/ramadan';
  static const settings = '/settings';
}
