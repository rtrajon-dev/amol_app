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
import '../../features/profile/presentation/view/profile_screen.dart';
import '../../features/qibla/presentation/view/qibla_screen.dart';
import '../../features/ramadan/presentation/view/ramadan_screen.dart';
import '../../features/settings/presentation/view/settings_screen.dart';
import '../../features/subscription/presentation/view/subscription_gate_screen.dart';
import '../../features/subscription/presentation/viewmodel/subscription_viewmodel.dart';
import '../../features/surah/presentation/view/surah_detail_screen.dart';
import '../../features/surah/presentation/view/surah_screen.dart';
import '../../features/tasbeeh/presentation/view/tasbeeh_screen.dart';
import '../config/feature_flags.dart';
import '../di/registration_coordinator.dart';
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
    // Registration holds routing until the subscription lookup answers, so the
    // router has to re-evaluate when that flag clears.
    ref.listen(subscriptionResolvingProvider, (_, _) => notifyListeners());
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
        // Onboarding leads to login; the gate now sits behind it (step 5).
        return auth.isAuthenticated ? AppRoutes.home : AppRoutes.login;
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

      // 4. Authentication (FR-G-03). A persisted session satisfies this, and
      //    the check is local, so an offline user is never blocked (FR-A-06).
      if (!auth.isAuthenticated) {
        // The gate sits behind login now, so an unauthenticated visit to it is
        // a stale back-stack entry rather than a step in the flow.
        return authRoutes.contains(path) ? null : AppRoutes.login;
      }

      // 5. Hold while a just-registered session learns whether it already has
      //    a subscription. Routing now would send a paying web subscriber to
      //    the paywall for the moment it takes the check to return.
      if (ref.read(subscriptionResolvingProvider)) {
        return null;
      }

      // 6. Subscription (FR-G-06) — MANDATORY, and after login rather than
      //    before it. The whole app is the paid product, so an authenticated
      //    user without entitlement has nothing to be let through to.
      //
      //    `subscriptionEnabled` remains the FR-P-07 kill switch and matters
      //    more now than it did as a soft gate: if BDApps billing fails, this
      //    is the only way to stop locking every user out of an app they
      //    cannot buy.
      final entitlement = ref.read(entitlementProvider);
      final needsSubscription =
          flags.requiresSubscription(isPremium: entitlement.isPremium);

      if (path == AppRoutes.subscription) {
        // Never strand a subscriber on the gate — including the moment their
        // payment lands and entitlement flips.
        return needsSubscription ? null : AppRoutes.home;
      }

      if (needsSubscription) {
        return AppRoutes.subscription;
      }

      // 7. Subscribed users never sit on splash or an auth screen.
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

          // FR-G-06 — the startup gate is mandatory: the whole app is the paid
          // product, so there is nowhere to dismiss to. Only a manual visit by
          // someone already inside the app can be closed.
          final canDismiss = isManual;

          return SubscriptionGateScreen(
            isAutomaticPrompt: !isManual,
            canDismiss: canDismiss,
            initialMsisdn: ref.read(authProvider).user?.msisdn,
            // The one way out of a mandatory gate. Without it a user who
            // cannot or will not pay is trapped with no exit and no way to
            // reach a different account.
            onSignOut: canDismiss
                ? null
                : () => ref.read(authProvider.notifier).logout(),
            onDone: ({required bool subscribed}) {
              if (isManual && context.canPop()) {
                context.pop();
                return;
              }
              // The redirect decides the destination — one source of truth for
              // the sequence (FR-G-05).
              context.go(AppRoutes.home);
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
            path: AppRoutes.profile,
            builder: (_, _) => const ProfileScreen(),
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
