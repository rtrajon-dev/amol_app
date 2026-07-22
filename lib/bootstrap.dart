import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'app/app.dart';
import 'app/di/providers.dart';
import 'app/services/firebase_service.dart';
import 'app/services/notification_service.dart';
import 'app/services/push_service.dart';
import 'app/services/remote_config_service.dart';
import 'app/services/storage_service.dart';
import 'app/services/telemetry_service.dart';

/// Runs a startup step, absorbing anything it throws.
///
/// Nothing between `main()` and `runApp()` may fail fatally. An exception
/// escaping here does not crash the app in the way a user could recognise —
/// the process stays alive on the Android launch theme with no Flutter view
/// ever created, so the app hangs on the splash forever with no error and no
/// way out but force-quit. That is exactly how a renamed launcher icon
/// (`@mipmap/ic_launcher` → `launcher_icon`) took the whole app down: the
/// notification plugin threw PlatformException from its initialize().
///
/// Every step below is optional to the core of the app. Prayer times, qibla,
/// tasbeeh and the amal tracker need none of them, and a user who cannot open
/// the app is worse off than one whose analytics are missing.
Future<void> _guarded(String step, Future<void> Function() run) async {
  try {
    await run();
  } catch (e, stack) {
    debugPrint('bootstrap: "$step" failed and was skipped — $e');
    debugPrintStack(stackTrace: stack);
  }
}

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Must precede runApp: the router reads StorageKeys.onboardingDone
  // synchronously on the very first redirect.
  await StorageService.instance.init();

  // Local notifications — azan. Independent of Firebase and of the network
  // (FR-P-04); initialised first so a Firebase problem can never delay it.
  await _guarded('notifications', NotificationService.instance.initialize);

  // M-6. Every one of these degrades to a no-op without config files
  // (docs/FIREBASE.md), so the app starts normally either way.
  await _guarded('firebase', FirebaseService.instance.initialize);
  await _guarded('telemetry', TelemetryService.instance.initialize);
  await _guarded('remote-config', RemoteConfigService.instance.initialize);
  await _guarded('push', PushService.instance.initialize);

  // FR-BE-08 — X-App-Version. Read once; it cannot change at runtime.
  var appVersion = '0.0.0';
  try {
    appVersion = (await PackageInfo.fromPlatform()).version;
  } catch (_) {
    // Platform channel unavailable (e.g. under a widget test). The default is
    // fine — a wrong version header must never stop the app from starting.
  }

  runApp(
    ProviderScope(
      overrides: [appVersionProvider.overrideWithValue(appVersion)],
      child: const Amol365App(),
    ),
  );
}
