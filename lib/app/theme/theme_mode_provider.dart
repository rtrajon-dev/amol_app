import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/storage_service.dart';

/// Light / dark / follow-system, persisted.
///
/// `StorageKeys.themeMode` existed and was never read or written: both themes
/// were built, `ThemeMode.system` was hardcoded, and the Settings row that
/// claimed to change it had an empty `onTap`. So dark mode shipped, worked, and
/// could not be chosen.
///
/// Defaults to system. An app used before Fajr and after Isha should follow
/// whatever the phone already does at those hours rather than override it.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => _read();

  static ThemeMode _read() {
    final stored = StorageService.instance.getString(StorageKeys.themeMode);
    return switch (stored) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await StorageService.instance.setString(
      StorageKeys.themeMode,
      switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      },
    );
  }

  /// Bangla label for the current mode, for the settings subtitle.
  static String labelFor(ThemeMode mode) => switch (mode) {
        ThemeMode.light => 'লাইট',
        ThemeMode.dark => 'ডার্ক',
        ThemeMode.system => 'সিস্টেম অনুযায়ী',
      };
}

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);
