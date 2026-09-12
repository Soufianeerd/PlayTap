import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/activities/activities_page.dart';
import '../features/activities/score_presets_page.dart';
import '../features/history/history_page.dart';
import '../features/home/home_page.dart';
import '../features/score_free/active_free_score_session_page.dart';
import '../features/score_free/free_score_config_page.dart';
import '../features/score_free/score_summary_page.dart';
import '../features/settings/settings_page.dart';
import '../features/shared/coming_soon_page.dart';

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
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsPage(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/coming-soon',
      builder: (context, state) => ComingSoonPage(
        sectionLabel: state.extra as String? ?? 'Cette section',
      ),
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
  ],
);

class _RootScaffold extends StatelessWidget {
  const _RootScaffold({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view),
            label: 'Activités',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Historique',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Réglages',
          ),
        ],
      ),
    );
  }
}
