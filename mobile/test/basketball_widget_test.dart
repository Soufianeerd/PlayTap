// Basketball UI flows — the reference Sport Pack proving the generic Match
// Engine end-to-end (see the Phase Sports 2 brief build order). Mirrors
// petanque_widget_test.dart's harness (freshTestDb/appWithClock/pumpTimer)
// for the same standalone-file reason documented on
// test/app/locale_test.dart.
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtap/app/app.dart';
import 'package:playtap/app/providers/database_providers.dart';
import 'package:playtap/core/time/app_clock.dart';
import 'package:playtap/data/local/app_database.dart';
import 'package:playtap/data/repositories/session_repository.dart';
import 'package:playtap/domain/models/session_status.dart';
import 'package:playtap/l10n/app_localizations.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

AppDatabase freshTestDb() => AppDatabase(
  DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true),
);

Widget appWithFreshDb() => ProviderScope(
  overrides: [databaseProvider.overrideWithValue(freshTestDb())],
  child: const PlayTapApp(),
);

Widget appWithClock(AppDatabase db, AppClock clock) => ProviderScope(
  overrides: [
    databaseProvider.overrideWithValue(db),
    clockProvider.overrideWithValue(clock),
  ],
  child: const PlayTapApp(),
);

AppLocalizations l10nOf(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(Scaffold).first))!;

/// The active session page runs a live ~200ms repaint ticker for as long
/// as it's the current screen (mirrors `active_timer_session_page.dart`),
/// so `pumpAndSettle` never sees "no more frames pending" while it's
/// mounted.
Future<void> pumpTicker(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 30));
  }
}

/// The big team-score digits (fontSize 88) — distinguishes a score from
/// the smaller foul/timeout counters (fontSize 24) now sharing the same
/// screen and, at small values, the same digits.
Finder scoreText(String value) => find.byWidgetPredicate(
  (w) => w is Text && w.data == value && w.style?.fontSize == 88,
);

/// The summary page's score digits use a smaller size (36) than the
/// active session's (88).
Finder summaryScoreText(String value) => find.byWidgetPredicate(
  (w) => w is Text && w.data == value && w.style?.fontSize == 36,
);

Future<void> startBasketballSession(WidgetTester tester) async {
  final l10n = l10nOf(tester);
  await tester.tap(find.text(l10n.categoryScore));
  await tester.pumpAndSettle();
  await tester.tap(find.text(l10n.presetBasketball));
  await tester.pumpAndSettle();
  await tester.tap(find.text(l10n.startButton));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  testWidgets('FLOW — config shows two default team names and starts a match', (
    tester,
  ) async {
    await tester.pumpWidget(appWithFreshDb());
    await tester.pumpAndSettle();
    final l10n = l10nOf(tester);

    await tester.tap(find.text(l10n.categoryScore));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.presetBasketball));
    await tester.pumpAndSettle();

    // "Team {n}" is both the section header label and the pre-filled
    // default value in that section's TextField — two on-screen matches by
    // design (mirrors Pétanque's identical config page), not one.
    expect(find.text(l10n.teamMatchDefaultTeamName(1)), findsWidgets);
    expect(find.text(l10n.teamMatchDefaultTeamName(2)), findsWidgets);

    await tester.tap(find.text(l10n.startButton));
    await tester.pumpAndSettle();

    // Active session: score buttons for +1/+2/+3, both teams at 0, Q1.
    expect(find.text('+1'), findsNWidgets(2));
    expect(find.text('+2'), findsNWidgets(2));
    expect(find.text('+3'), findsNWidgets(2));
    expect(scoreText('0'), findsNWidgets(2));
    expect(find.text(l10n.periodLabelQuarter(1)), findsOneWidget);
    expect(
      find.text('10:00'),
      findsOneWidget,
    ); // Q1 remaining, clock not started.
  });

  testWidgets('FLOW — scoring +1/+2/+3 updates each team independently', (
    tester,
  ) async {
    await tester.pumpWidget(appWithFreshDb());
    await tester.pumpAndSettle();
    await startBasketballSession(tester);

    await tester.tap(find.text('+3').first);
    await tester.pumpAndSettle();
    expect(scoreText('3'), findsOneWidget);

    await tester.tap(find.text('+2').last);
    await tester.pumpAndSettle();
    expect(scoreText('2'), findsOneWidget);

    await tester.tap(find.text('+1').first);
    await tester.pumpAndSettle();
    expect(scoreText('4'), findsOneWidget); // 3 + 1.
  });

  testWidgets(
    'FLOW — rapid double-tap on the same score button records only one point',
    (tester) async {
      await tester.pumpWidget(appWithFreshDb());
      await tester.pumpAndSettle();
      await startBasketballSession(tester);

      await tester.tap(find.text('+3').first);
      await tester.tap(find.text('+3').first);
      await tester.pumpAndSettle();

      expect(scoreText('3'), findsOneWidget);
      expect(scoreText('6'), findsNothing);
    },
  );

  testWidgets(
    'FLOW — START then the clock counts down; the period auto-advances to '
    'Q2 once it hits zero, and score carries over',
    (tester) async {
      final clock = FakeClock();
      await tester.pumpWidget(appWithClock(freshTestDb(), clock));
      await tester.pumpAndSettle();
      final l10n = l10nOf(tester);

      await startBasketballSession(tester);
      await tester.tap(find.text('+2').first);
      await tester.pumpAndSettle();

      // Clock hasn't started yet: RESUME is shown (elapsed == 0).
      expect(find.text(l10n.resumeTimerButtonLabel), findsOneWidget);
      await tester.tap(find.text(l10n.resumeTimerButtonLabel));
      await pumpTicker(tester);
      expect(find.text(l10n.pauseButtonLabel), findsOneWidget);

      // Advance past the full 10-minute quarter.
      clock.advance(const Duration(minutes: 10, seconds: 1));
      await pumpTicker(tester);

      expect(find.text(l10n.periodLabelQuarter(2)), findsOneWidget);
      expect(find.text('10:00'), findsOneWidget); // fresh Q2 clock.
      expect(scoreText('2'), findsOneWidget); // score survives the transition.
    },
  );

  testWidgets(
    'FLOW — a tie after Q4 goes to overtime; a decided OT ends the match on the summary page',
    (tester) async {
      final db = freshTestDb();
      final clock = FakeClock();
      await tester.pumpWidget(appWithClock(db, clock));
      await tester.pumpAndSettle();
      final l10n = l10nOf(tester);

      await startBasketballSession(tester);

      Future<void> playOutCurrentPeriod() async {
        await tester.tap(find.text(l10n.resumeTimerButtonLabel));
        await pumpTicker(tester);
        clock.advance(const Duration(minutes: 10, seconds: 1));
        await pumpTicker(tester);
      }

      // Q1-Q4: level score throughout (both teams +1 each quarter).
      for (var period = 0; period < 4; period++) {
        await tester.tap(find.text('+1').first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('+1').last);
        await tester.pumpAndSettle();
        await playOutCurrentPeriod();
      }

      // Tied 4-4 after Q4 -> overtime, never a draw.
      expect(find.text(l10n.overtimeLabel(1)), findsOneWidget);
      expect(scoreText('4'), findsNWidgets(2));
      expect(find.text('05:00'), findsOneWidget); // 5-minute OT.

      // Decide it in OT: team A scores.
      await tester.tap(find.text('+2').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.resumeTimerButtonLabel));
      await pumpTicker(tester);
      clock.advance(const Duration(minutes: 5, seconds: 1));
      await pumpTicker(tester);
      await tester.pumpAndSettle(); // let the summary route transition finish.

      expect(find.text(l10n.summaryTitle), findsOneWidget);
      final teamA = l10n.teamMatchDefaultTeamName(1);
      expect(find.text(l10n.winnerAnnouncement(teamA)), findsOneWidget);
      expect(summaryScoreText('6'), findsOneWidget); // 4 + 2.
      expect(summaryScoreText('4'), findsOneWidget); // team B unchanged.

      final completed = await SessionRepository(db).getCompletedSessions();
      expect(completed, hasLength(1));
      expect(completed.single.status, SessionStatus.completed);
    },
  );

  testWidgets('FLOW — manual abandon lands back on History', (tester) async {
    await tester.pumpWidget(appWithFreshDb());
    await tester.pumpAndSettle();
    final l10n = l10nOf(tester);

    await startBasketballSession(tester);
    await tester.tap(find.text('+2').first);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.abandonGameButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.abandonGameButton));
    await tester.pumpAndSettle();

    expect(find.text(l10n.navHistory), findsWidgets);
    expect(find.text(l10n.presetBasketball), findsNothing);
  });
}
