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

  // ---- Location (SRS docs/SRS.md §4.9) ----

  /// FR-N-01 — 'auto' | 'manual'.
  static const locationSource = 'location_source';
  static const locationLat = 'location_lat';
  static const locationLng = 'location_lng';
  static const locationName = 'location_name';
  static const locationTimestamp = 'location_timestamp';

  /// FR-N-12 — 'hanafi' | 'shafi'. Affects Asr only.
  static const madhab = 'madhab';

  /// FR-N-13 — JSON map of per-prayer offsets in minutes, −30..+30.
  static const prayerOffsets = 'prayer_offsets';

  // ---- Azan (SRS docs/SRS.md §4.9) ----

  /// FR-N-23 — comma-separated list of prayers with azan enabled.
  /// Empty = never configured (defaults apply); a single space = explicitly none.
  static const azanPerPrayer = 'azan_per_prayer';

  /// FR-N-24 — minutes before each prayer to send a reminder. 0 = off.
  static const preReminderMinutes = 'pre_reminder_minutes';

  /// FR-N-28 — 'default' | 'silent' (azan audio reserved for later).
  static const azanSoundMode = 'azan_sound_mode';

  /// Whether the user has been shown the battery-optimisation guidance.
  static const batteryGuidanceShown = 'battery_guidance_shown';

  static const selectedCity = 'selected_city';
  static const azanEnabled = 'azan_enabled';
  static const tasbeehCount = 'tasbeeh_count';
  static const lastAmalDate = 'last_amal_date';
  static const amalStreak = 'amal_streak';
  static const calculationMethod = 'calculation_method';
  static const themeMode = 'theme_mode';
}
