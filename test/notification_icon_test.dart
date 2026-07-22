import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The notification icon is resolved BY NAME at runtime, so nothing in the
/// Dart or Android build can catch a mismatch — not the compiler, not
/// `flutter analyze`, not a widget test that stubs the plugin.
///
/// It went wrong exactly once and cost the whole app: `NotificationService`
/// asked for `@mipmap/ic_launcher`, flutter_launcher_icons renamed that
/// resource to `launcher_icon`, and the plugin threw PlatformException from
/// initialize(). Because that ran inside `bootstrap()` before `runApp()`, the
/// app did not crash — it froze on the launch theme with no Flutter view, so
/// every user saw an endless splash.
///
/// These tests re-derive the name from the source rather than hard-coding it,
/// so renaming the resource without moving the file fails here instead of on a
/// user's phone.
void main() {
  final source = File('lib/app/services/notification_service.dart');
  final res = Directory('android/app/src/main/res');

  /// The resource string actually passed to AndroidInitializationSettings.
  ({String type, String name}) declaredIcon() {
    final match = RegExp(r"AndroidInitializationSettings\('@(\w+)/(\w+)'\)")
        .firstMatch(source.readAsStringSync());
    expect(
      match,
      isNotNull,
      reason: 'Could not find the AndroidInitializationSettings icon literal. '
          'If its shape changed, update this test — do not delete it.',
    );
    return (type: match!.group(1)!, name: match.group(2)!);
  }

  test('the declared notification icon exists in the Android resources', () {
    final icon = declaredIcon();

    // Density-qualified directories, e.g. drawable-xxhdpi, plus the bare one.
    final matches = res
        .listSync()
        .whereType<Directory>()
        .where((d) {
          final dir = d.path.split(Platform.pathSeparator).last;
          return dir == icon.type || dir.startsWith('${icon.type}-');
        })
        .expand((d) => d.listSync().whereType<File>())
        .where((f) {
          final file = f.path.split(Platform.pathSeparator).last;
          return file == '${icon.name}.png' || file == '${icon.name}.xml';
        })
        .toList();

    expect(
      matches,
      isNotEmpty,
      reason: 'NotificationService declares @${icon.type}/${icon.name}, but no '
          'such resource exists under android/app/src/main/res. The plugin '
          'resolves this by name at runtime and throws PlatformException when '
          'it is missing, which hangs the app on the splash screen. '
          'Run: python3 tool/generate_logo.py',
    );
  });

  test('the notification icon is protected from resource shrinking', () {
    // The check that actually matters, and the one a source-tree test misses.
    //
    // Release builds shrink resources, keeping only what is referenced from the
    // manifest, another resource, or the dex. This icon is named in a Dart
    // string and resolved via getIdentifier(), so the shrinker sees no
    // reference and drops it — the file sits in res/ looking perfectly fine
    // while being absent from every release APK.
    //
    // That is precisely how the original bug hid: ic_launcher.png was still in
    // the source tree, so nothing looked wrong.
    final icon = declaredIcon();
    final keep = File('android/app/src/main/res/raw/keep.xml');

    expect(
      keep.existsSync(),
      isTrue,
      reason: 'android/app/src/main/res/raw/keep.xml is missing. Without it '
          'the notification icon is shrunk out of release builds and the app '
          'hangs on the splash screen.',
    );
    // The tools:keep attribute specifically — not the file text. keep.xml
    // explains itself in a comment that names the old broken resource, and a
    // substring search over the whole file matches that comment and passes
    // while the attribute says something else entirely.
    final attr = RegExp(r'tools:keep\s*=\s*"([^"]*)"')
        .firstMatch(keep.readAsStringSync());
    expect(attr, isNotNull, reason: 'keep.xml has no tools:keep attribute.');

    final kept = attr!
        .group(1)!
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet();

    expect(
      kept,
      contains('@${icon.type}/${icon.name}'),
      reason: 'keep.xml keeps $kept, but NotificationService asks for '
          '@${icon.type}/${icon.name}. Release builds will shrink it away and '
          'the app will hang on the splash screen.',
    );
  });

  test('the notification icon ships at every launcher density', () {
    final icon = declaredIcon();

    // A status-bar icon missing its density renders upscaled and blurry on
    // exactly the devices most users have.
    for (final density in ['mdpi', 'hdpi', 'xhdpi', 'xxhdpi', 'xxxhdpi']) {
      final file =
          File('${res.path}/${icon.type}-$density/${icon.name}.png');
      expect(
        file.existsSync(),
        isTrue,
        reason: 'Missing ${file.path}. Run: python3 tool/generate_logo.py',
      );
    }
  });

  test('the manifest launcher icon exists too', () {
    final manifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    final match =
        RegExp(r'android:icon="@(\w+)/(\w+)"').firstMatch(manifest);
    expect(match, isNotNull, reason: 'No android:icon in the manifest.');

    final type = match!.group(1)!;
    final name = match.group(2)!;

    final found = res
        .listSync()
        .whereType<Directory>()
        .where((d) {
          final dir = d.path.split(Platform.pathSeparator).last;
          return dir == type || dir.startsWith('$type-');
        })
        .expand((d) => d.listSync().whereType<File>())
        .any((f) {
          final file = f.path.split(Platform.pathSeparator).last;
          return file == '$name.png' || file == '$name.xml';
        });

    expect(
      found,
      isTrue,
      reason: 'The manifest declares @$type/$name but it is not in res/. '
          'The app would not install or would show a blank launcher icon.',
    );
  });
}
