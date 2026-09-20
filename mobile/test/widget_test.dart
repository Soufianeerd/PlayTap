import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtap/app/app.dart';
import 'package:playtap/app/providers/database_providers.dart';
import 'package:playtap/core/time/app_clock.dart';
import 'package:playtap/data/local/app_database.dart';

/// A fresh in-memory database per test (see the Phase 1B.1 brief, section
/// 27 — no data persists between tests). `closeStreamsSynchronously` avoids
/// a documented drift/flutter_test interaction: without it, closing a
/// watched query schedules a zero-duration Timer that can outlive the
/// widget tree and trip flutter_test's "pending timer" check.
AppDatabase freshTestDb() => AppDatabase(
  DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true),
);

Widget appWithDb(AppDatabase db) {
  return ProviderScope(
    overrides: [databaseProvider.overrideWithValue(db)],
    child: const PlayTapApp(),
  );
}

Widget appWithFreshDb() => appWithDb(freshTestDb());

/// For Timer flow tests: overrides both the database and the clock so
/// elapsed time is driven by [FakeClock.advance] rather than real wall-clock
/// waits (see the Phase 1B.2 brief, section 31 — no real-time sleeps).
Widget appWithClock(AppDatabase db, AppClock clock) {
  return ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      clockProvider.overrideWithValue(clock),
    ],
    child: const PlayTapApp(),
  );
}

/// The active Timer session page runs a live ~200ms repaint ticker for as
/// long as it's the current screen (see `active_timer_session_page.dart`),
/// so `pumpAndSettle` never sees "no more frames pending" while it's
/// mounted — entering it, acting on it, and leaving it must all pump a
/// bounded number of frames instead.
Future<void> pumpTimer(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 30));
  }
}

Future<void> startFreeScoreSession(
  WidgetTester tester, {
  required int participantCount,
}) async {
  await tester.tap(find.text('Compter un score'));
  await tester.pumpAndSettle();

  await tester.tap(find.text('$participantCount'));
  await tester.pumpAndSettle();

  await tester.tap(find.text('COMMENCER'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Home shows the PlayTap title and the 1.0.0 sections', (
    tester,
  ) async {
    await tester.pumpWidget(appWithFreshDb());
    await tester.pumpAndSettle();

    expect(find.text('PlayTap'), findsOneWidget);
    expect(find.text('Compter un score'), findsOneWidget);
    expect(find.text('Chronométrer'), findsOneWidget);
    expect(find.text('Training'), findsNothing);
    expect(find.text('Custom'), findsNothing);
  });

  testWidgets('Bottom navigation switches between the three tabs', (
    tester,
  ) async {
    await tester.pumpWidget(appWithFreshDb());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Activités'));
    await tester.pumpAndSettle();
    expect(find.text('Compter un score'), findsWidgets);

    await tester.tap(find.text('Historique'));
    await tester.pumpAndSettle();
    expect(find.text('Aucune activité pour le moment.'), findsOneWidget);
  });

  testWidgets('Tapping Timer navigates to the Timer presets page', (
    tester,
  ) async {
    await tester.pumpWidget(appWithFreshDb());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Chronométrer'));
    await tester.pumpAndSettle();

    expect(find.text('Chronomètre'), findsOneWidget);
    expect(find.text('Compte à rebours'), findsOneWidget);
    expect(find.text('Tours'), findsOneWidget);
  });

  testWidgets('FLOW 1 — 2 participants: score, undo, complete, history', (
    tester,
  ) async {
    await tester.pumpWidget(appWithFreshDb());
    await tester.pumpAndSettle();

    await startFreeScoreSession(tester, participantCount: 2);

    expect(find.text('Joueur 1'), findsOneWidget);
    expect(find.text('Joueur 2'), findsOneWidget);
    expect(find.text('0'), findsNWidgets(2));

    await tester.tap(find.text('Joueur 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Joueur 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Joueur 2'));
    await tester.pumpAndSettle();

    expect(find.text('2'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);

    // Undo removes the last scoring action (Joueur 2's point).
    await tester.tap(find.byIcon(Icons.undo));
    await tester.pumpAndSettle();

    expect(find.text('2'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);

    await tester.tap(find.text('TERMINER LA PARTIE'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('TERMINER'));
    await tester.pumpAndSettle();

    // Summary screen.
    expect(find.text('Score libre'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);

    await tester.tap(find.text('VOIR L\'HISTORIQUE'));
    await tester.pumpAndSettle();

    // Landed on History with the completed session.
    expect(find.textContaining('Joueur 1 2'), findsOneWidget);
  });

  testWidgets('FLOW 2 — 3 participants can all be scored', (tester) async {
    await tester.pumpWidget(appWithFreshDb());
    await tester.pumpAndSettle();

    await startFreeScoreSession(tester, participantCount: 3);

    expect(find.text('Joueur 1'), findsOneWidget);
    expect(find.text('Joueur 2'), findsOneWidget);
    expect(find.text('Joueur 3'), findsOneWidget);

    await tester.tap(find.text('Joueur 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Joueur 3'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Joueur 3'));
    await tester.pumpAndSettle();

    expect(find.text('1'), findsOneWidget); // Joueur 1
    expect(find.text('0'), findsOneWidget); // Joueur 2
    expect(find.text('2'), findsOneWidget); // Joueur 3
  });

  testWidgets(
    'FLOW 3 — 4 participants render as a 2x2 grid and can be scored',
    (tester) async {
      await tester.pumpWidget(appWithFreshDb());
      await tester.pumpAndSettle();

      await startFreeScoreSession(tester, participantCount: 4);

      for (var i = 1; i <= 4; i++) {
        expect(find.text('Joueur $i'), findsOneWidget);
      }

      await tester.tap(find.text('Joueur 4'));
      await tester.pumpAndSettle();

      expect(find.text('1'), findsOneWidget);
      expect(find.text('0'), findsNWidgets(3));
    },
  );

  testWidgets('FLOW 4 — an active session resumes with its exact score', (
    tester,
  ) async {
    final db = freshTestDb();

    await tester.pumpWidget(appWithDb(db));
    await tester.pumpAndSettle();

    await startFreeScoreSession(tester, participantCount: 2);
    await tester.tap(find.text('Joueur 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Joueur 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Joueur 2'));
    await tester.pumpAndSettle();

    // Simulate an app restart: tear the whole tree down first (otherwise
    // Flutter just updates the existing PlayTapApp element in place and its
    // router keeps whatever route it was on) so PlayTapApp's State — and
    // the router it creates in initState — are genuinely recreated, over
    // the SAME underlying database.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(appWithDb(db));
    await tester.pumpAndSettle();

    expect(find.text('REPRENDRE L\'ACTIVITÉ'), findsOneWidget);

    await tester.tap(find.text('REPRENDRE L\'ACTIVITÉ'));
    await tester.pumpAndSettle();

    expect(find.text('2'), findsOneWidget); // Joueur 1, recovered exactly
    expect(find.text('1'), findsOneWidget); // Joueur 2, recovered exactly

    await tester.tap(find.text('Joueur 1'));
    await tester.pumpAndSettle();
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets(
    'TIMER FLOW — Stopwatch: pause freezes elapsed, resume continues, '
    'terminer lands in history',
    (tester) async {
      final clock = FakeClock();
      await tester.pumpWidget(appWithClock(freshTestDb(), clock));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Activités'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chronométrer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chronomètre'));
      await pumpTimer(tester); // now on the ticker-driven session page

      expect(find.text('00:00.00'), findsOneWidget);

      clock.advance(const Duration(seconds: 3));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('00:03.00'), findsOneWidget);

      await tester.tap(find.text('PAUSE'));
      await pumpTimer(tester);

      // Frozen while paused, even though the clock keeps moving.
      clock.advance(const Duration(seconds: 5));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('00:03.00'), findsOneWidget);

      await tester.tap(find.text('REPRENDRE'));
      await pumpTimer(tester);

      clock.advance(const Duration(seconds: 2));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('00:05.00'), findsOneWidget);

      await tester.tap(find.text('TERMINER LA SESSION'));
      await pumpTimer(tester); // confirmation dialog
      await tester.tap(find.text('TERMINER'));
      await pumpTimer(tester); // leaves the ticker page for good
      // The ticker is gone now — safe to let any in-flight page
      // transition fully settle before asserting on the result.
      await tester.pumpAndSettle();

      // Summary screen.
      expect(find.text('Chronomètre'), findsOneWidget);
      expect(find.text('00:05'), findsOneWidget);

      await tester.tap(find.text('VOIR L\'HISTORIQUE'));
      await tester.pumpAndSettle();

      // Landed on History with the completed session.
      expect(find.textContaining('00:05'), findsOneWidget);
    },
  );

  testWidgets(
    'TIMER FLOW — Countdown completes on its own and lands on the summary',
    (tester) async {
      final clock = FakeClock();
      await tester.pumpWidget(appWithClock(freshTestDb(), clock));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Activités'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chronométrer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Compte à rebours'));
      await tester.pumpAndSettle(); // config page, no live ticker yet

      await tester.tap(find.text('30s'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('COMMENCER'));
      await pumpTimer(tester); // now on the ticker-driven session page

      expect(find.text('00:30.00'), findsOneWidget);

      // Cross the finish line — the live ticker must detect this and
      // persist TIMER_COMPLETED exactly once, then navigate on its own.
      clock.advance(const Duration(seconds: 30));
      await pumpTimer(tester);
      // The ticker page auto-navigated away on completion — safe to let
      // any in-flight page transition fully settle now.
      await tester.pumpAndSettle();

      expect(find.text('Compte à rebours'), findsOneWidget);
      expect(find.text('00:30'), findsOneWidget); // full duration elapsed
    },
  );

  testWidgets('TIMER FLOW — Lap Timer records laps with correct splits', (
    tester,
  ) async {
    final clock = FakeClock();
    await tester.pumpWidget(appWithClock(freshTestDb(), clock));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Activités'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chronométrer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tours'));
    await pumpTimer(tester); // now on the ticker-driven session page

    clock.advance(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text('LAP'));
    await pumpTimer(tester);

    expect(find.text('Lap 1'), findsOneWidget);
    expect(find.text('00:03.00'), findsWidgets); // main display + split

    clock.advance(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text('LAP'));
    await pumpTimer(tester);

    expect(find.text('Lap 2'), findsOneWidget);
    expect(find.text('00:04.00'), findsOneWidget); // split, not cumulative

    await tester.tap(find.text('TERMINER LA SESSION'));
    await pumpTimer(tester); // confirmation dialog
    await tester.tap(find.text('TERMINER'));
    await pumpTimer(tester); // leaves the ticker page for good
    // The ticker is gone now — safe to let any in-flight page transition
    // fully settle before asserting on the result.
    await tester.pumpAndSettle();

    expect(find.text('Tours'), findsOneWidget);
    expect(find.text('00:07'), findsOneWidget);
    expect(find.text('2 laps'), findsOneWidget);

    await tester.tap(find.text('VOIR L\'HISTORIQUE'));
    await tester.pumpAndSettle();

    expect(find.textContaining('00:07 — 2 laps'), findsOneWidget);
  });

  testWidgets(
    'TIMER FLOW — a Timer session resumes after simulated app restart, '
    'elapsed accounts for wall-clock time while the process was dead',
    (tester) async {
      final clock = FakeClock();
      final db = freshTestDb();

      await tester.pumpWidget(appWithClock(db, clock));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Activités'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chronométrer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chronomètre'));
      await pumpTimer(tester); // now on the ticker-driven session page

      clock.advance(const Duration(seconds: 4));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('00:04.00'), findsOneWidget);

      // Simulate the process dying while the stopwatch keeps "running"
      // (from the persisted log's point of view) and being relaunched 6s
      // of wall-clock time later — the monotonic clock resets, but
      // recovery must still account for the full 10s via timestamps.
      clock.simulateProcessRestart(
        wallClockAdvance: const Duration(seconds: 6),
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(appWithClock(db, clock));
      await tester.pumpAndSettle();

      expect(find.text('REPRENDRE L\'ACTIVITÉ'), findsOneWidget);

      await tester.tap(find.text('REPRENDRE L\'ACTIVITÉ'));
      await pumpTimer(tester); // now on the ticker-driven session page

      expect(find.text('00:10.00'), findsOneWidget);
    },
  );

  testWidgets('HISTORY FLOW — a second completed session appears in Historique '
      'without restarting the app (regression: historyProvider used to '
      'freeze on whichever session completed first)', (tester) async {
    await tester.pumpWidget(appWithFreshDb());
    await tester.pumpAndSettle();

    // Session 1: Joueur 1 scores once, then the match is finished.
    await startFreeScoreSession(tester, participantCount: 2);
    await tester.tap(find.text('Joueur 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('TERMINER LA PARTIE'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('TERMINER'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('VOIR L\'HISTORIQUE'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Joueur 1 1'), findsOneWidget);

    // Back to Home — Historique stays mounted the whole time in the
    // bottom-nav's IndexedStack, which is exactly what a plain
    // FutureProvider failed to account for.
    await tester.tap(find.text('Accueil'));
    await tester.pumpAndSettle();

    // Session 2: a different, fresh match — Joueur 2 scores twice.
    await startFreeScoreSession(tester, participantCount: 2);
    await tester.tap(find.text('Joueur 2'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Joueur 2'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('TERMINER LA PARTIE'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('TERMINER'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('VOIR L\'HISTORIQUE'));
    await tester.pumpAndSettle();

    // Both completed sessions are visible — the bug showed only the
    // first one until the whole app process was killed and relaunched.
    expect(find.textContaining('Joueur 1 1'), findsOneWidget);
    expect(find.textContaining('Joueur 2 2'), findsOneWidget);
  });
}
