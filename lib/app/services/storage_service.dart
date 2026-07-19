import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  StorageService._();
  static final instance = StorageService._();

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> setBool(String key, bool value) => _prefs.setBool(key, value);
  bool getBool(String key, {bool defaultValue = false}) =>
      _prefs.getBool(key) ?? defaultValue;

  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);
  String getString(String key, {String defaultValue = ''}) =>
      _prefs.getString(key) ?? defaultValue;

  Future<void> setInt(String key, int value) => _prefs.setInt(key, value);
  int getInt(String key, {int defaultValue = 0}) =>
      _prefs.getInt(key) ?? defaultValue;

  Future<void> remove(String key) => _prefs.remove(key);
}

abstract class StorageKeys {
  static const onboardingDone = 'onboarding_done';

  /// FR-BE-08 — stable per-install id sent as `X-Device-Id`.
  static const deviceId = 'device_id';

  /// Convenience only: prefills the login field. Never a credential.
  static const lastAuthEmail = 'last_auth_email';

  /// FR-S-09 — how many times the subscription gate has been shown
  /// automatically. At 3 it stops for good.
  static const subGatePromptCount = 'sub_gate_prompt_count';
  static const subGateDismissedAt = 'sub_gate_dismissed_at';

  /// FR-P-02 — daily hadith push opt-in. Off by default: an unsolicited daily
  /// notification is the fastest way to get uninstalled.
  static const pushHadithEnabled = 'push_hadith_enabled';

  static const selectedCity = 'selected_city';
  static const azanEnabled = 'azan_enabled';
  static const tasbeehCount = 'tasbeeh_count';
  static const lastAmalDate = 'last_amal_date';
  static const amalStreak = 'amal_streak';
  static const calculationMethod = 'calculation_method';
  static const themeMode = 'theme_mode';
}
