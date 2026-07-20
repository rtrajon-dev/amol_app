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
import '../../features/prayer_time/presentation/view/azan_settings_screen.dart';
import '../../features/prayer_time/presentation/view/city_selector_screen.dart';
import '../../features/prayer_time/presentation/view/prayer_time_screen.dart';
import '../../features/qibla/presentation/view/qibla_screen.dart';
import '../../features/ramadan/presentation/view/ramadan_screen.dart';
import '../../features/settings/presentation/view/settings_screen.dart';
import '../../features/subscription/presentation/view/subscription_gate_screen.dart';
import '../../features/subscription/presentation/viewmodel/subscription_viewmodel.dart';
import '../../features/surah/presentation/view/surah_detail_screen.dart';
import '../../features/surah/presentation/view/surah_screen.dart';
import '../../features/tasbeeh/presentation/view/tasbeeh_screen.dart';
import '../config/feature_flags.dart';
import '../services/storage_service.dart';
import '../shell/main_shell.dart';
import 'app_routes.dart';

/// Bridges Riverpod state changes into something `GoRouter` will listen to.
class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(Ref ref) {
    ref.listen(authProvider, (_, _) => notifyListeners());
    // Entitlement restores asynchronously from secure storage; without this
    // the gate would still be showing after the cache says "premium".
    ref.listen(entitlementProvider, (_, _) => notifyListeners());
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

      final flags = ref.read(featureFlagsProvider);

      // 2. Onboarding, once per install (FR-G-04).
      final onboardingDone =
          StorageService.instance.getBool(StorageKeys.onboardingDone);
      if (!onboardingDone) {
        return path == AppRoutes.onboarding ? null : AppRoutes.onboarding;
      }
      if (path == AppRoutes.onboarding) {
        // Phase 1 has no gate to show, so onboarding leads straight on
        // (FR-PH-02) rather than bouncing off a withheld route.
        if (!flags.subscriptionEnabled) {
          return auth.isAuthenticated ? AppRoutes.home : AppRoutes.login;
        }
        return AppRoutes.subscription;
      }

      // 3. FR-PH-07 — routes belonging to a withheld feature refuse to render.
      //    Hiding the entry tile is not enough: a deep link, a notification, or
      //    a back-stack entry from an earlier build can each target a route
      //    directly.
      //
      //    This precedes the subscription block deliberately. That block lets
      //    `?manual=1` through unconditionally (FR-S-10), which is right when a
      //    tier exists and wrong when Phase 1 has nothing to sell.
      if (flags.isRouteWithheld(path)) {
        return auth.isAuthenticated ? AppRoutes.home : AppRoutes.login;
      }

      // 4. Subscription gate (FR-G-01, FR-G-02) — OPTIONAL. It precedes login,
      //    and the ✕ dismisses it straight through to the next step. It is
      //    shown automatically at most three times (FR-S-09); after that it is
      //    reachable only from Settings or a locked feature (FR-S-10).
      final entitlement = ref.read(entitlementProvider);
      final gateIsDue = SubscriptionGatePolicy.shouldShow(entitlement);

      if (path == AppRoutes.subscription) {
        // FR-S-10 — a MANUAL entry (Settings row, locked feature) must always
        // open, even after FR-S-09 has silenced the automatic prompt. Without
        // this the only two remaining conversion paths would be dead.
        final isManual = state.uri.queryParameters['manual'] == '1';
        if (isManual) return null;

        // Automatic entry: never trap the user here if it is no longer due.
        if (!gateIsDue) {
          return auth.isAuthenticated ? AppRoutes.home : AppRoutes.login;
        }
        return null;
      }

      if (gateIsDue && !auth.isAuthenticated && !authRoutes.contains(path)) {
        return AppRoutes.subscription;
      }

      // 4. Authentication (FR-G-03). A persisted session satisfies this, and
      //    the check is local, so an offline user is never blocked (FR-A-06).
      if (!auth.isAuthenticated) {
        return authRoutes.contains(path) ? null : AppRoutes.login;
      }

      // 5. Authenticated users never sit on splash or an auth screen.
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
        path: AppRoutes.subscription,
        builder: (context, state) {
          final isManual = state.uri.queryParameters['manual'] == '1';
          return SubscriptionGateScreen(
            isAutomaticPrompt: !isManual,
            onDone: ({required bool subscribed}) {
              // Opened manually from Settings or a locked feature: just go
              // back where they came from.
              if (isManual && context.canPop()) {
                context.pop();
                return;
              }
              // Startup gate: both dismiss and success converge, and the
              // redirect decides the destination — one source of truth for
              // the sequence (FR-G-05).
              final auth = ref.read(authProvider);
              context.go(auth.isAuthenticated ? AppRoutes.home : AppRoutes.login);
            },
          );
        },
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
            path: AppRoutes.azanSettings,
            builder: (_, _) => const AzanSettingsScreen(),
          ),
          GoRoute(
            path: AppRoutes.citySelector,
            builder: (_, _) => const CitySelectorScreen(),
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
