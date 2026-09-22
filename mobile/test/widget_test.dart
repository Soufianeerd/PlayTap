import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtap/app/app.dart';
import 'package:playtap/app/providers/database_providers.dart';
import 'package:playtap/core/time/app_clock.dart';
import 'package:playtap/data/local/app_database.dart';
import 'package:playtap/l10n/app_localizations.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

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

/// Looks up the app's current localized strings from a pumped widget tree —
/// tests assert against these rather than hardcoded French/English text, so
/// they stay valid regardless of which language the app resolves to (see
/// docs/LOCALIZATION.md "Tests"). A [Scaffold] always exists once the app
/// has rendered its first page.
AppLocalizations l10nOf(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(Scaffold).first))!;

Future<void> startFreeScoreSession(
  WidgetTester tester, {
  required int participantCount,
}) async {
  final l10n = l10nOf(tester);
  await tester.tap(find.text(l10n.categoryScore));
  await tester.pumpAndSettle();
  await tester.tap(find.text(l10n.presetFreeScore));
  await tester.pumpAndSettle();

  await tester.tap(find.text('$participantCount'));
  await tester.pumpAndSettle();

  await tester.tap(find.text(l10n.startButton));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    // The locale preference is persisted via shared_preferences (see
    // app/locale/locale_repository.dart) — this in-memory fake avoids
    // MissingPluginException in tests and keeps each test isolated.
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  testWidgets('Home shows the PlayTap title and the 1.0.0 sections', (
    tester,
  ) async {
    await tester.pumpWidget(appWithFreshDb());
    await tester.pumpAndSettle();
    final l10n = l10nOf(tester);

    expect(find.text('PlayTap'), findsOneWidget);
    expect(find.text(l10n.categoryScore), findsOneWidget);
    expect(find.text(l10n.categoryTimer), findsOneWidget);
    expect(find.text('Training'), findsNothing);
    expect(find.text('Custom'), findsNothing);
  });

  testWidgets('Bottom navigation switches between the three tabs', (
    tester,
  ) async {
    await tester.pumpWidget(appWithFreshDb());
    await tester.pumpAndSettle();
    final l10n = l10nOf(tester);

    await tester.tap(find.text(l10n.navActivities));
    await tester.pumpAndSettle();
    expect(find.text(l10n.categoryScore), findsWidgets);

    await tester.tap(find.text(l10n.navHistory));
    await tester.pumpAndSettle();
    expect(find.text(l10n.emptyHistoryTitle), findsOneWidget);
  });

  testWidgets('Tapping Timer navigates to the Timer presets page', (
    tester,
  ) async {
    await tester.pumpWidget(appWithFreshDb());
    await tester.pumpAndSettle();
    final l10n = l10nOf(tester);

    await tester.tap(find.text(l10n.categoryTimer));
    await tester.pumpAndSettle();

    expect(find.text(l10n.timerModeStopwatch), findsOneWidget);
    expect(find.text(l10n.timerModeCountdown), findsOneWidget);
    expect(find.text(l10n.timerModeLaps), findsOneWidget);
  });

  testWidgets('FLOW 1 — 2 participants: score, undo, complete, history', (
    tester,
  ) async {
    await tester.pumpWidget(appWithFreshDb());
    await tester.pumpAndSettle();
    final l10n = l10nOf(tester);
    final player1 = l10n.defaultParticipantName(1);
    final player2 = l10n.defaultParticipantName(2);

    await startFreeScoreSession(tester, participantCount: 2);

    expect(find.text(player1), findsOneWidget);
    expect(find.text(player2), findsOneWidget);
    expect(find.text('0'), findsNWidgets(2));

    await tester.tap(find.text(player1));
    await tester.pumpAndSettle();
    await tester.tap(find.text(player1));
    await tester.pumpAndSettle();
    await tester.tap(find.text(player2));
    await tester.pumpAndSettle();

    expect(find.text('2'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);

    // Undo removes the last scoring action (player2's point).
    await tester.tap(find.byIcon(Icons.undo));
    await tester.pumpAndSettle();

    expect(find.text('2'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);

    await tester.tap(find.text(l10n.finishGameButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.finishButton));
    await tester.pumpAndSettle();

    // Summary screen.
    expect(find.text(l10n.presetFreeScore), findsOneWidget);
    expect(find.text('2'), findsOneWidget);

    await tester.tap(find.text(l10n.viewHistoryButton));
    await tester.pumpAndSettle();

    // Landed on History with the completed session.
    expect(find.textContaining('$player1 2'), findsOneWidget);
  });

  testWidgets('FLOW 2 — 3 participants can all be scored', (tester) async {
    await tester.pumpWidget(appWithFreshDb());
    await tester.pumpAndSettle();
    final l10n = l10nOf(tester);
    final player1 = l10n.defaultParticipantName(1);
    final player2 = l10n.defaultParticipantName(2);
    final player3 = l10n.defaultParticipantName(3);

    await startFreeScoreSession(tester, participantCount: 3);

    expect(find.text(player1), findsOneWidget);
    expect(find.text(player2), findsOneWidget);
    expect(find.text(player3), findsOneWidget);

    await tester.tap(find.text(player1));
    await tester.pumpAndSettle();
    await tester.tap(find.text(player3));
    await tester.pumpAndSettle();
    await tester.tap(find.text(player3));
    await tester.pumpAndSettle();

    expect(find.text('1'), findsOneWidget); // player1
    expect(find.text('0'), findsOneWidget); // player2
    expect(find.text('2'), findsOneWidget); // player3
  });

  testWidgets(
    'FLOW 3 — 4 participants render as a 2x2 grid and can be scored',
    (tester) async {
      await tester.pumpWidget(appWithFreshDb());
      await tester.pumpAndSettle();
      final l10n = l10nOf(tester);

      await startFreeScoreSession(tester, participantCount: 4);

      for (var i = 1; i <= 4; i++) {
        expect(find.text(l10n.defaultParticipantName(i)), findsOneWidget);
      }

      await tester.tap(find.text(l10n.defaultParticipantName(4)));
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
    final l10n = l10nOf(tester);
    final player1 = l10n.defaultParticipantName(1);
    final player2 = l10n.defaultParticipantName(2);

    await startFreeScoreSession(tester, participantCount: 2);
    await tester.tap(find.text(player1));
    await tester.pumpAndSettle();
    await tester.tap(find.text(player1));
    await tester.pumpAndSettle();
    await tester.tap(find.text(player2));
    await tester.pumpAndSettle();

    // Simulate an app restart: tear the whole tree down first (otherwise
    // Flutter just updates the existing PlayTapApp element in place and its
    // router keeps whatever route it was on) so PlayTapApp's State — and
    // the router it creates in initState — are genuinely recreated, over
    // the SAME underlying database.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(appWithDb(db));
    await tester.pumpAndSettle();

    expect(find.text(l10n.resumeActivity), findsOneWidget);

    await tester.tap(find.text(l10n.resumeActivity));
    await tester.pumpAndSettle();

    expect(find.text('2'), findsOneWidget); // player1, recovered exactly
    expect(find.text('1'), findsOneWidget); // player2, recovered exactly

    await tester.tap(find.text(player1));
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
      final l10n = l10nOf(tester);

      await tester.tap(find.text(l10n.navActivities));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.categoryTimer));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.timerModeStopwatch));
      await pumpTimer(tester); // now on the ticker-driven session page

      expect(find.text('00:00.00'), findsOneWidget);

      clock.advance(const Duration(seconds: 3));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('00:03.00'), findsOneWidget);

      await tester.tap(find.text(l10n.pauseButtonLabel));
      await pumpTimer(tester);

      // Frozen while paused, even though the clock keeps moving.
      clock.advance(const Duration(seconds: 5));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('00:03.00'), findsOneWidget);

      await tester.tap(find.text(l10n.resumeTimerButtonLabel));
      await pumpTimer(tester);

      clock.advance(const Duration(seconds: 2));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('00:05.00'), findsOneWidget);

      await tester.tap(find.text(l10n.finishSessionButton));
      await pumpTimer(tester); // confirmation dialog
      await tester.tap(find.text(l10n.finishButton));
      await pumpTimer(tester); // leaves the ticker page for good
      // The ticker is gone now — safe to let any in-flight page
      // transition fully settle before asserting on the result.
      await tester.pumpAndSettle();

      // Summary screen.
      expect(find.text(l10n.timerModeStopwatch), findsOneWidget);
      expect(find.text('00:05'), findsOneWidget);

      await tester.tap(find.text(l10n.viewHistoryButton));
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
      final l10n = l10nOf(tester);

      await tester.tap(find.text(l10n.navActivities));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.categoryTimer));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.timerModeCountdown));
      await tester.pumpAndSettle(); // config page, no live ticker yet

      await tester.tap(find.text(l10n.quickPresetSeconds(30)));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.startButton));
      await pumpTimer(tester); // now on the ticker-driven session page

      expect(find.text('00:30.00'), findsOneWidget);

      // Cross the finish line — the live ticker must detect this and
      // persist TIMER_COMPLETED exactly once, then navigate on its own.
      clock.advance(const Duration(seconds: 30));
      await pumpTimer(tester);
      // The ticker page auto-navigated away on completion — safe to let
      // any in-flight page transition fully settle now.
      await tester.pumpAndSettle();

      expect(find.text(l10n.timerModeCountdown), findsOneWidget);
      expect(find.text('00:30'), findsOneWidget); // full duration elapsed
    },
  );

  testWidgets('TIMER FLOW — Lap Timer records laps with correct splits', (
    tester,
  ) async {
    final clock = FakeClock();
    await tester.pumpWidget(appWithClock(freshTestDb(), clock));
    await tester.pumpAndSettle();
    final l10n = l10nOf(tester);

    await tester.tap(find.text(l10n.navActivities));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.categoryTimer));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.timerModeLaps));
    await pumpTimer(tester); // now on the ticker-driven session page

    clock.advance(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text(l10n.lapButton));
    await pumpTimer(tester);

    expect(find.text(l10n.lapRowLabel(1)), findsOneWidget);
    expect(find.text('00:03.00'), findsWidgets); // main display + split

    clock.advance(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text(l10n.lapButton));
    await pumpTimer(tester);

    expect(find.text(l10n.lapRowLabel(2)), findsOneWidget);
    expect(find.text('00:04.00'), findsOneWidget); // split, not cumulative

    await tester.tap(find.text(l10n.finishSessionButton));
    await pumpTimer(tester); // confirmation dialog
    await tester.tap(find.text(l10n.finishButton));
    await pumpTimer(tester); // leaves the ticker page for good
    // The ticker is gone now — safe to let any in-flight page transition
    // fully settle before asserting on the result.
    await tester.pumpAndSettle();

    expect(find.text(l10n.timerModeLaps), findsOneWidget);
    expect(find.text('00:07'), findsOneWidget);
    expect(find.text(l10n.lapsCountPlural(2)), findsOneWidget);

    await tester.tap(find.text(l10n.viewHistoryButton));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('00:07 — ${l10n.lapsCountPlural(2)}'),
      findsOneWidget,
    );
  });

  testWidgets(
    'TIMER FLOW — a Timer session resumes after simulated app restart, '
    'elapsed accounts for wall-clock time while the process was dead',
    (tester) async {
      final clock = FakeClock();
      final db = freshTestDb();

      await tester.pumpWidget(appWithClock(db, clock));
      await tester.pumpAndSettle();
      final l10n = l10nOf(tester);

      await tester.tap(find.text(l10n.navActivities));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.categoryTimer));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.timerModeStopwatch));
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

      expect(find.text(l10n.resumeActivity), findsOneWidget);

      await tester.tap(find.text(l10n.resumeActivity));
      await pumpTimer(tester); // now on the ticker-driven session page

      expect(find.text('00:10.00'), findsOneWidget);
    },
  );

  testWidgets('HISTORY FLOW — a second completed session appears in Historique '
      'without restarting the app (regression: historyProvider used to '
      'freeze on whichever session completed first)', (tester) async {
    await tester.pumpWidget(appWithFreshDb());
    await tester.pumpAndSettle();
    final l10n = l10nOf(tester);
    final player1 = l10n.defaultParticipantName(1);
    final player2 = l10n.defaultParticipantName(2);

    // Session 1: player1 scores once, then the match is finished.
    await startFreeScoreSession(tester, participantCount: 2);
    await tester.tap(find.text(player1));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.finishGameButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.finishButton));
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.viewHistoryButton));
    await tester.pumpAndSettle();
    expect(find.textContaining('$player1 1'), findsOneWidget);

    // Back to Home — Historique stays mounted the whole time in the
    // bottom-nav's IndexedStack, which is exactly what a plain
    // FutureProvider failed to account for.
    await tester.tap(find.text(l10n.navHome));
    await tester.pumpAndSettle();

    // Session 2: a different, fresh match — player2 scores twice.
    await startFreeScoreSession(tester, participantCount: 2);
    await tester.tap(find.text(player2));
    await tester.pumpAndSettle();
    await tester.tap(find.text(player2));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.finishGameButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.finishButton));
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.viewHistoryButton));
    await tester.pumpAndSettle();

    // Both completed sessions are visible — the bug showed only the
    // first one until the whole app process was killed and relaunched.
    expect(find.textContaining('$player1 1'), findsOneWidget);
    expect(find.textContaining('$player2 2'), findsOneWidget);
  });
}
