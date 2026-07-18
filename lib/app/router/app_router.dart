import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/presentation/view/home_screen.dart';
import '../../features/onboarding/presentation/view/onboarding_screen.dart';
import '../../features/prayer_time/presentation/view/prayer_time_screen.dart';
import '../../features/tasbeeh/presentation/view/tasbeeh_screen.dart';
import '../../features/amal_tracker/presentation/view/amal_tracker_screen.dart';
import '../../features/qibla/presentation/view/qibla_screen.dart';
import '../../features/hadith/presentation/view/hadith_screen.dart';
import '../../features/islamic_calendar/presentation/view/calendar_screen.dart';
import '../../features/names_of_allah/presentation/view/names_screen.dart';
import '../../features/surah/presentation/view/surah_screen.dart';
import '../../features/surah/presentation/view/surah_detail_screen.dart';
import '../../features/ramadan/presentation/view/ramadan_screen.dart';
import '../../features/settings/presentation/view/settings_screen.dart';
import '../shell/main_shell.dart';
import 'app_routes.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, _) => const OnboardingScreen(),
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
