import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/amal_tracker/presentation/view/amal_tracker_screen.dart';
import '../../features/auth/presentation/view/forgot_password_screen.dart';
import '../../features/auth/presentation/view/login_screen.dart';
import '../../features/auth/presentation/view/register_screen.dart';
import '../../features/auth/presentation/view/splash_screen.dart';
import '../../features/auth/presentation/viewmodel/auth_viewmodel.dart';
import '../../features/hadith/presentation/view/hadith_screen.dart';
import '../../features/home/presentation/view/home_screen.dart';
import '../../features/islamic_calendar/presentation/view/calendar_screen.dart';
import '../../features/names_of_allah/presentation/view/names_screen.dart';
import '../../features/onboarding/presentation/view/onboarding_screen.dart';
import '../../features/prayer_time/presentation/view/prayer_time_screen.dart';
import '../../features/qibla/presentation/view/qibla_screen.dart';
import '../../features/ramadan/presentation/view/ramadan_screen.dart';
import '../../features/settings/presentation/view/settings_screen.dart';
import '../../features/surah/presentation/view/surah_detail_screen.dart';
import '../../features/surah/presentation/view/surah_screen.dart';
import '../../features/tasbeeh/presentation/view/tasbeeh_screen.dart';
import '../services/storage_service.dart';
import '../shell/main_shell.dart';
import 'app_routes.dart';

/// Bridges Riverpod state changes into something `GoRouter` will listen to.
class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(Ref ref) {
    ref.listen(authProvider, (_, _) => notifyListeners());
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,

    /// FR-G-05 — the whole startup sequence is decided HERE, in one place,
    /// rather than by imperative navigation scattered across screens.
    ///
    /// Order (M-2):  Splash → Onboarding → Login → Home
    /// Order (M-4):  Splash → Onboarding → Subscription gate → Login → Home
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final path = state.matchedLocation;

      const authRoutes = {
        AppRoutes.login,
        AppRoutes.register,
        AppRoutes.forgotPassword,
      };

      // 1. Still reading the local session — hold on the splash so no screen
      //    flashes before the answer is known.
      if (auth.status == AuthStatus.unknown) {
        return path == AppRoutes.splash ? null : AppRoutes.splash;
      }

      // 2. Onboarding, once per install (FR-G-04).
      final onboardingDone =
          StorageService.instance.getBool(StorageKeys.onboardingDone);
      if (!onboardingDone) {
        return path == AppRoutes.onboarding ? null : AppRoutes.onboarding;
      }
      if (path == AppRoutes.onboarding) {
        return auth.isAuthenticated ? AppRoutes.home : AppRoutes.login;
      }

      // 3. Authentication (FR-G-03). A persisted session satisfies this, and
      //    the check is local, so an offline user is never blocked (FR-A-06).
      if (!auth.isAuthenticated) {
        return authRoutes.contains(path) ? null : AppRoutes.login;
      }

      // 4. Authenticated users never sit on splash or an auth screen.
      if (path == AppRoutes.splash || authRoutes.contains(path)) {
        return AppRoutes.home;
      }

      return null;
    },

    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, _) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, _) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, _) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, _) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (_, _) => const ForgotPasswordScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (_, _) => const HomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.prayerTime,
            builder: (_, _) => const PrayerTimeScreen(),
          ),
          GoRoute(
            path: AppRoutes.tasbeeh,
            builder: (_, _) => const TasbeehScreen(),
          ),
          GoRoute(
            path: AppRoutes.amalTracker,
            builder: (_, _) => const AmalTrackerScreen(),
          ),
          GoRoute(
            path: AppRoutes.qibla,
            builder: (_, _) => const QiblaScreen(),
          ),
          GoRoute(
            path: AppRoutes.hadith,
            builder: (_, _) => const HadithScreen(),
          ),
          GoRoute(
            path: AppRoutes.islamicCalendar,
            builder: (_, _) => const CalendarScreen(),
          ),
          GoRoute(
            path: AppRoutes.namesOfAllah,
            builder: (_, _) => const NamesScreen(),
          ),
          GoRoute(
            path: AppRoutes.surah,
            builder: (_, _) => const SurahScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, state) =>
                    SurahDetailScreen(id: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.ramadan,
            builder: (_, _) => const RamadanScreen(),
          ),
          GoRoute(
            path: AppRoutes.settings,
            builder: (_, _) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
});
