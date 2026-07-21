import 'package:amol365/app/services/storage_service.dart';
import 'package:amol365/app/theme/theme_mode_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Light or dark only. `ThemeMode.system` is not offered — a two-state icon
/// cannot express three states.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> containerWith(Map<String, Object> prefs) async {
    SharedPreferences.setMockInitialValues(prefs);
    await StorageService.instance.init();
    final c = ProviderContainer();
    addTearDown(c.dispose);
    return c;
  }

  group('default', () {
    test('a fresh install is light, not the device setting', () async {
      final c = await containerWith({});

      expect(c.read(themeModeProvider), ThemeMode.light);
    });
  });

  group('toggle', () {
    test('flips light to dark and back', () async {
      final c = await containerWith({});
      final notifier = c.read(themeModeProvider.notifier);

      await notifier.toggle();
      expect(c.read(themeModeProvider), ThemeMode.dark);

      await notifier.toggle();
      expect(c.read(themeModeProvider), ThemeMode.light);
    });

    test('persists across a restart', () async {
      final c = await containerWith({});
      await c.read(themeModeProvider.notifier).toggle();

      // A second container reads back from storage, as a relaunch would.
      final restarted = ProviderContainer();
      addTearDown(restarted.dispose);

      expect(restarted.read(themeModeProvider), ThemeMode.dark);
    });
  });

  group('legacy and invalid values', () {
    test('a stored "system" resolves to light', () async {
      // Installs from before this change stored 'system'. Accepted one-time
      // reset of a setting the user can flip in a single tap.
      final c = await containerWith({'theme_mode': 'system'});

      expect(c.read(themeModeProvider), ThemeMode.light);
    });

    test('nonsense resolves to light rather than crashing', () async {
      final c = await containerWith({'theme_mode': 'aubergine'});

      expect(c.read(themeModeProvider), ThemeMode.light);
    });

    test('passing system to set() is coerced, not stored', () async {
      final c = await containerWith({});

      // Otherwise it would be written and read back as light next launch — a
      // setting that silently forgets itself.
      await c.read(themeModeProvider.notifier).set(ThemeMode.system);

      expect(c.read(themeModeProvider), ThemeMode.light);
      expect(StorageService.instance.getString(StorageKeys.themeMode), 'light');
    });
  });
}
