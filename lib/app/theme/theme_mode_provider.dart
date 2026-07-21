import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/storage_service.dart';

/// Light or dark. Nothing else.
///
/// `ThemeMode.system` is deliberately not offered. It reads well in a settings
/// list and badly as an icon: a two-state control cannot express three states,
/// and a user tapping a sun expects a moon next — not for the app to defer to a
/// phone setting they may not know they have.
///
/// **Light is the default**, rather than following the device. Most of this
/// audience runs the system default anyway, and a prayer app that opens dark
/// because the phone happens to be dark surprises more people than it pleases.
///
/// One consequence, accepted: an install that stored `system` before this
/// change resolves to light on next launch even if the phone is dark. It is a
/// one-time reset of a setting the user can flip in a single tap.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => _read();

  static ThemeMode _read() {
    // Anything that is not explicitly 'dark' — including the legacy 'system'
    // and an empty store — is light.
    return StorageService.instance.getString(StorageKeys.themeMode) == 'dark'
        ? ThemeMode.dark
        : ThemeMode.light;
  }

  bool get isDark => state == ThemeMode.dark;

  Future<void> toggle() =>
      set(state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);

  Future<void> set(ThemeMode mode) async {
    // Guards against a caller passing `system`, which has no meaning here and
    // would otherwise be stored and read back as light on the next launch —
    // a setting that silently forgets itself.
    final resolved = mode == ThemeMode.dark ? ThemeMode.dark : ThemeMode.light;

    state = resolved;
    await StorageService.instance.setString(
      StorageKeys.themeMode,
      resolved == ThemeMode.dark ? 'dark' : 'light',
    );
  }

  static String labelFor(ThemeMode mode) =>
      mode == ThemeMode.dark ? 'ডার্ক' : 'লাইট';
}

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);
