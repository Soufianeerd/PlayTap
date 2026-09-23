import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../features/activities/activities_page.dart';
import '../features/activities/score_presets_page.dart';
import '../features/activities/timer_presets_page.dart';
import '../features/history/history_page.dart';
import '../features/home/home_page.dart';
import '../features/score_basketball/basketball_config_page.dart';
import '../features/score_football/football_config_page.dart';
import '../features/score_free/active_free_score_session_page.dart';
import '../features/score_free/free_score_config_page.dart';
import '../features/score_free/score_summary_page.dart';
import '../features/score_futsal/futsal_config_page.dart';
import '../features/score_petanque/active_petanque_session_page.dart';
import '../features/score_petanque/petanque_config_page.dart';
import '../features/score_petanque/petanque_summary_page.dart';
import '../features/score_team_match/active_team_match_session_page.dart';
import '../features/score_team_match/team_match_summary_page.dart';
import '../features/settings/language_settings_page.dart';
import '../features/shared/coming_soon_page.dart';
import '../features/timer/active_timer_session_page.dart';
import '../features/timer/countdown_config_page.dart';
import '../features/timer/timer_summary_page.dart';
import '../l10n/app_localizations.dart';
import 'theme/theme.dart';

/// Builds a fresh root navigator. Kept as a factory (not a top-level
/// singleton) so each [PlayTapApp] instance — including each one created in
/// a widget test — owns its own router state instead of leaking navigation
/// state into the next instance.
GoRouter createAppRouter() => GoRouter(
  initialLocation: '/home',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          _RootScaffold(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomePage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/activities',
              builder: (context, state) => const ActivitiesPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/history',
              builder: (context, state) => const HistoryPage(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/coming-soon',
      builder: (context, state) => ComingSoonPage(
        sectionLabel:
            state.extra as String? ??
            AppLocalizations.of(context)!.comingSoonDefaultSection,
      ),
    ),
    GoRoute(
      path: '/settings/language',
      builder: (context, state) => const LanguageSettingsPage(),
    ),
    GoRoute(
      path: '/activities/score',
      builder: (context, state) => const ScorePresetsPage(),
    ),
    GoRoute(
      path: '/score/free/config',
      builder: (context, state) => const FreeScoreConfigPage(),
    ),
    GoRoute(
      path: '/score/free/session/:sessionId',
      builder: (context, state) => ActiveFreeScoreSessionPage(
        sessionId: state.pathParameters['sessionId']!,
      ),
    ),
    GoRoute(
      path: '/score/free/summary/:sessionId',
      builder: (context, state) =>
          ScoreSummaryPage(sessionId: state.pathParameters['sessionId']!),
    ),
    GoRoute(
      path: '/score/petanque/config',
      builder: (context, state) => const PetanqueConfigPage(),
    ),
    GoRoute(
      path: '/score/petanque/session/:sessionId',
      builder: (context, state) => ActivePetanqueSessionPage(
        sessionId: state.pathParameters['sessionId']!,
      ),
    ),
    GoRoute(
      path: '/score/petanque/summary/:sessionId',
      builder: (context, state) =>
          PetanqueSummaryPage(sessionId: state.pathParameters['sessionId']!),
    ),
    GoRoute(
      path: '/score/basketball/config',
      builder: (context, state) => const BasketballConfigPage(),
    ),
    GoRoute(
      path: '/score/basketball/session/:sessionId',
      builder: (context, state) => ActiveTeamMatchSessionPage(
        sessionId: state.pathParameters['sessionId']!,
        summaryRoute:
            '/score/basketball/summary/${state.pathParameters['sessionId']}',
      ),
    ),
    GoRoute(
      path: '/score/basketball/summary/:sessionId',
      builder: (context, state) => TeamMatchSummaryPage(
        sessionId: state.pathParameters['sessionId']!,
        sessionRoute:
            '/score/basketball/session/${state.pathParameters['sessionId']}',
      ),
    ),
    GoRoute(
      path: '/score/football/config',
      builder: (context, state) => const FootballConfigPage(),
    ),
    GoRoute(
      path: '/score/football/session/:sessionId',
      builder: (context, state) => ActiveTeamMatchSessionPage(
        sessionId: state.pathParameters['sessionId']!,
        summaryRoute:
            '/score/football/summary/${state.pathParameters['sessionId']}',
      ),
    ),
    GoRoute(
      path: '/score/football/summary/:sessionId',
      builder: (context, state) => TeamMatchSummaryPage(
        sessionId: state.pathParameters['sessionId']!,
        sessionRoute:
            '/score/football/session/${state.pathParameters['sessionId']}',
      ),
    ),
    GoRoute(
      path: '/score/futsal/config',
      builder: (context, state) => const FutsalConfigPage(),
    ),
    GoRoute(
      path: '/score/futsal/session/:sessionId',
      builder: (context, state) => ActiveTeamMatchSessionPage(
        sessionId: state.pathParameters['sessionId']!,
        summaryRoute:
            '/score/futsal/summary/${state.pathParameters['sessionId']}',
      ),
    ),
    GoRoute(
      path: '/score/futsal/summary/:sessionId',
      builder: (context, state) => TeamMatchSummaryPage(
        sessionId: state.pathParameters['sessionId']!,
        sessionRoute:
            '/score/futsal/session/${state.pathParameters['sessionId']}',
      ),
    ),
    GoRoute(
      path: '/activities/timer',
      builder: (context, state) => const TimerPresetsPage(),
    ),
    GoRoute(
      path: '/timer/countdown/config',
      builder: (context, state) => const CountdownConfigPage(),
    ),
    GoRoute(
      path: '/timer/session/:sessionId',
      builder: (context, state) =>
          ActiveTimerSessionPage(sessionId: state.pathParameters['sessionId']!),
    ),
    GoRoute(
      path: '/timer/summary/:sessionId',
      builder: (context, state) =>
          TimerSummaryPage(sessionId: state.pathParameters['sessionId']!),
    ),
  ],
);

class _RootScaffold extends StatelessWidget {
  const _RootScaffold({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).playTapColors;
    final l10n = AppLocalizations.of(context)!;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: PlayTapTheme.overlayStyleOf(context),
      child: Scaffold(
        body: navigationShell,
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: colors.border)),
          ),
          child: NavigationBar(
            elevation: 0,
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: (index) => navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            ),
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home),
                label: l10n.navHome,
              ),
              NavigationDestination(
                icon: const Icon(Icons.grid_view_outlined),
                selectedIcon: const Icon(Icons.grid_view),
                label: l10n.navActivities,
              ),
              NavigationDestination(
                icon: const Icon(Icons.history_outlined),
                selectedIcon: const Icon(Icons.history),
                label: l10n.navHistory,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
