import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'app/app.dart';
import 'app/di/providers.dart';
import 'app/services/notification_service.dart';
import 'app/services/storage_service.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Must precede runApp: the router reads StorageKeys.onboardingDone
  // synchronously on the very first redirect.
  await StorageService.instance.init();

  await NotificationService.instance.initialize();

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
