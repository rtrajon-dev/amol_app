import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'di/azan_bootstrap.dart';
import 'di/push_registrar.dart';
import 'di/session_coordinator.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class Amol365App extends ConsumerWidget {
  const Amol365App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    // Keeps the auth ↔ entitlement coordination alive for the app's lifetime
    // (EC-17). Watching it here is what instantiates the listener.
    ref.watch(sessionCoordinatorProvider);

    // FCM token registration and telemetry user/tier properties (M-6).
    ref.watch(pushRegistrarProvider);

    // Keeps scheduled azan in step with location and the date (FR-N-15).
    ref.watch(azanBootstrapProvider);

    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      builder: (_, _) => MaterialApp.router(
        title: 'ইসলামিক আমল',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        routerConfig: router,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('bn', 'BD'),
          Locale('en', 'US'),
          Locale('ar'),
        ],
        locale: const Locale('bn', 'BD'),
      ),
    );
  }
}
