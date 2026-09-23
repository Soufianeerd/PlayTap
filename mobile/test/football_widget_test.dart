// Football UI flows — exercises the RUNNING_CLOCK and shootout paths
// Basketball's stopped-clock/no-shootout flow never touches. Mirrors
// basketball_widget_test.dart's harness.
import 'package:drift/drift.dart' hide isNotNull, isNull;
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

AppDatabase freshTestDb() => AppDatabase(
  DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true),
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

Future<void> pumpTicker(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 30));
  }
}

Future<void> startFootballSession(
  WidgetTester tester, {
  required String format,
}) async {
  final l10n = l10nOf(tester);
  await tester.tap(find.text(l10n.categoryScore));
  await tester.pumpAndSettle();
  await tester.tap(find.text(l10n.presetFootball));
  await tester.pumpAndSettle();
  await tester.tap(find.text(format));
  await tester.pumpAndSettle();
  await tester.tap(find.text(l10n.startButton));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  testWidgets(
    'FLOW — league: running clock keeps counting past 45:00 (added time); '
    'a level score at 90:00 ends in a draw',
    (tester) async {
      final clock = FakeClock();
      await tester.pumpWidget(appWithClock(freshTestDb(), clock));
      await tester.pumpAndSettle();
      final l10n = l10nOf(tester);

      await startFootballSession(tester, format: l10n.teamMatchFormatLeague);
      expect(find.text(l10n.periodLabelFirstHalf), findsOneWidget);
      expect(
        find.text('00:00'),
        findsOneWidget,
      ); // running clock shows elapsed, starts at 0.

      await tester.tap(find.text(l10n.resumeTimerButtonLabel));
      await pumpTicker(tester);

      // Past the nominal 45:00 — a running clock never clamps (45+3-style).
      clock.advance(const Duration(minutes: 47));
      await pumpTicker(tester);
      expect(find.text('47:00'), findsOneWidget);

      // Referee's whistle ends the first half manually (nothing auto-expires
      // a running clock) via the secondary menu.
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.endPeriodManuallyButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.endPeriodManuallyButton));
      await tester.pumpAndSettle();

      expect(find.text(l10n.periodLabelSecondHalf), findsOneWidget);
      expect(find.text('00:00'), findsOneWidget); // fresh 2nd-half clock.

      await tester.tap(find.text(l10n.resumeTimerButtonLabel));
      await pumpTicker(tester);
      clock.advance(const Duration(minutes: 45));
      await pumpTicker(tester);

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.endPeriodManuallyButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.endPeriodManuallyButton));
      await tester.pumpAndSettle();

      // Level 0-0 at the end of a league match: a draw, never overtime.
      expect(find.text(l10n.summaryTitle), findsOneWidget);
      expect(find.text(l10n.matchDrawResultLabel), findsOneWidget);
    },
  );

  testWidgets(
    'FLOW — knockout: added time announced shows a badge; a level match '
    'goes to extra time then a penalty shootout, kept separate from the score',
    (tester) async {
      final clock = FakeClock();
      await tester.pumpWidget(appWithClock(freshTestDb(), clock));
      await tester.pumpAndSettle();
      final l10n = l10nOf(tester);

      await startFootballSession(tester, format: l10n.teamMatchFormatKnockout);

      await tester.tap(find.text(l10n.resumeTimerButtonLabel));
      await pumpTicker(tester);

      await tester.tap(find.byIcon(Icons.timer_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.addedTimeMinutesOption(3)));
      await tester.pumpAndSettle();
      expect(find.text(l10n.addedTimeBadge(3)), findsOneWidget);

      Future<void> endCurrentPeriod() async {
        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();
        await tester.tap(find.text(l10n.endPeriodManuallyButton));
        await tester.pumpAndSettle();
        await tester.tap(find.text(l10n.endPeriodManuallyButton));
        await tester.pumpAndSettle();
      }

      await endCurrentPeriod(); // end of 1st half.
      await tester.tap(find.text(l10n.resumeTimerButtonLabel));
      await pumpTicker(tester);
      await endCurrentPeriod(); // end of 2nd half — 0-0, knockout, no draw.

      // Extra time, period 1 of 2 (fixed-length block).
      expect(find.text(l10n.overtimeLabel(1)), findsOneWidget);
      await tester.tap(find.text(l10n.resumeTimerButtonLabel));
      await pumpTicker(tester);
      await endCurrentPeriod();

      // Extra time period 2 of 2 — still level after this ends -> shootout.
      expect(find.text(l10n.overtimeLabel(2)), findsOneWidget);
      await tester.tap(find.text(l10n.resumeTimerButtonLabel));
      await pumpTicker(tester);
      await endCurrentPeriod();

      expect(find.text(l10n.shootoutLabel), findsOneWidget);

      // Team A scores 3 straight kicks while B misses 3 — mathematically
      // decided after the 3rd pair: B's 2 remaining kicks (5-3) can no
      // longer catch A's 3 (2 < 3), so the shootout ends there, never
      // needing all 5 kicks each.
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.text(l10n.shootoutScoreButton));
        await tester.pumpAndSettle();
        await tester.tap(find.text(l10n.shootoutMissButton));
        await tester.pumpAndSettle();
      }

      expect(find.text(l10n.summaryTitle), findsOneWidget);
      final teamA = l10n.teamMatchDefaultTeamName(1);
      expect(find.text(l10n.winnerAnnouncement(teamA)), findsOneWidget);
      // Match score is still 0-0 — the shootout never merges into it.
      expect(find.text(l10n.shootoutScoreLine(3, 0)), findsOneWidget);
    },
  );
}
