import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'di/azan_bootstrap.dart';
import 'di/push_registrar.dart';
import 'di/session_coordinator.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';
import 'theme/theme_mode_provider.dart';

class Amol365App extends ConsumerWidget {
  const Amol365App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

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
      // Caps runaway system font scaling. Above ~1.3 the Bangla type scale
      // starts clipping inside fixed-height rows; below 0.85 it is unreadable
      // on a small screen. Accessibility settings are still honoured, just
      // bounded to what the layout can actually render.
      builder: (_, _) => MaterialApp.router(
        title: 'ইসলামিক আমল',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,
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
        builder: (context, child) => MediaQuery.withClampedTextScaling(
          minScaleFactor: 0.85,
          maxScaleFactor: 1.3,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}
