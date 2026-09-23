// Futsal timeout/accumulated-foul UI flows — Phase Sports 2B. Futsal has
// no shot clock (that's Basketball/FIBA-only); what's distinctly Futsal
// here is the *per-period* (not per-half) timeout grouping and the DFKSAF
// threshold of 6 (not Basketball's 5). Mirrors
// basketball_match_control_widget_test.dart's harness and the substring-
// RegExp semantics-label matching it settled on.
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

Widget appWithClock(AppDatabase db, AppClock clock) => ProviderScope(
  overrides: [
    databaseProvider.overrideWithValue(db),
    clockProvider.overrideWithValue(clock),
  ],
  child: const PlayTapApp(),
);

AppDatabase freshTestDb() => AppDatabase(
  DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true),
);

AppLocalizations l10nOf(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(Scaffold).first))!;

Future<void> pumpTicker(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 30));
  }
}

Future<void> startFutsalSession(
  WidgetTester tester, {
  required String format,
}) async {
  final l10n = l10nOf(tester);
  await tester.tap(find.text(l10n.categoryScore));
  await tester.pumpAndSettle();
  await tester.tap(find.text(l10n.presetFutsal));
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
    'no shot clock strip is shown for Futsal (Basketball/FIBA-only)',
    (tester) async {
      await tester.pumpWidget(appWithClock(freshTestDb(), FakeClock()));
      await tester.pumpAndSettle();
      final l10n = l10nOf(tester);
      await startFutsalSession(tester, format: l10n.teamMatchFormatLeague);

      expect(find.text(l10n.shotClockLabel), findsNothing);
    },
  );

  testWidgets(
    'timeouts: 1 per period (not per half) — using period 1s resets fresh for period 2',
    (tester) async {
      final clock = FakeClock();
      await tester.pumpWidget(appWithClock(freshTestDb(), clock));
      await tester.pumpAndSettle();
      final l10n = l10nOf(tester);
      final semanticsHandle = tester.ensureSemantics();
      await startFutsalSession(tester, format: l10n.teamMatchFormatLeague);
      final teamA = l10n.teamMatchDefaultTeamName(1);

      expect(
        find.bySemanticsLabel(
          RegExp(RegExp.escape(l10n.timeoutsRemainingSemantics(teamA, 1))),
        ),
        findsOneWidget,
      );
      await tester.tap(
        find.bySemanticsLabel(
          RegExp(RegExp.escape(l10n.timeoutsRemainingSemantics(teamA, 1))),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.bySemanticsLabel(
          RegExp(RegExp.escape(l10n.timeoutsRemainingSemantics(teamA, 0))),
        ),
        findsOneWidget,
      );

      // Play out all of period 1 (20 minutes) and auto-advance to period 2.
      await tester.tap(find.text(l10n.resumeTimerButtonLabel));
      await pumpTicker(tester);
      clock.advance(const Duration(minutes: 20, seconds: 1));
      await pumpTicker(tester);
      expect(find.text(l10n.periodLabelSecondHalf), findsOneWidget);

      // Period 2 has its own fresh quota of 1 — not the exhausted period 1 group.
      expect(
        find.bySemanticsLabel(
          RegExp(RegExp.escape(l10n.timeoutsRemainingSemantics(teamA, 1))),
        ),
        findsOneWidget,
      );
      semanticsHandle.dispose();
    },
  );

  testWidgets(
    'accumulated fouls: DFKSAF threshold is the 6th foul, not the 5th',
    (tester) async {
      await tester.pumpWidget(appWithClock(freshTestDb(), FakeClock()));
      await tester.pumpAndSettle();
      final l10n = l10nOf(tester);
      final semanticsHandle = tester.ensureSemantics();
      await startFutsalSession(tester, format: l10n.teamMatchFormatLeague);
      final teamA = l10n.teamMatchDefaultTeamName(1);

      for (var i = 0; i < 5; i++) {
        await tester.tap(
          find.bySemanticsLabel(
            RegExp(RegExp.escape(l10n.addTeamFoulSemantics(teamA))),
          ),
        );
        await tester.pumpAndSettle();
      }
      expect(
        find.text(l10n.bonusIndicatorLabel),
        findsNothing,
      ); // 5th: not yet (unlike Basketball).

      await tester.tap(
        find.bySemanticsLabel(
          RegExp(RegExp.escape(l10n.addTeamFoulSemantics(teamA))),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(l10n.bonusIndicatorLabel),
        findsOneWidget,
      ); // 6th: DFKSAF applies.
      semanticsHandle.dispose();
    },
  );

  testWidgets(
    'accumulated fouls reset at the start of period 2, and carry unchanged into extra time',
    (tester) async {
      final clock = FakeClock();
      await tester.pumpWidget(appWithClock(freshTestDb(), clock));
      await tester.pumpAndSettle();
      final l10n = l10nOf(tester);
      final semanticsHandle = tester.ensureSemantics();
      // Knockout format to reach extra time on a level score.
      await startFutsalSession(tester, format: l10n.teamMatchFormatKnockout);
      final teamA = l10n.teamMatchDefaultTeamName(1);

      Future<void> addFoul() async {
        await tester.tap(
          find.bySemanticsLabel(
            RegExp(RegExp.escape(l10n.addTeamFoulSemantics(teamA))),
          ),
        );
        await tester.pumpAndSettle();
      }

      Future<void> playOutCurrentPeriod() async {
        await tester.tap(find.text(l10n.resumeTimerButtonLabel));
        await pumpTicker(tester);
        clock.advance(const Duration(minutes: 20, seconds: 1));
        await pumpTicker(tester);
      }

      await addFoul();
      await addFoul();
      await addFoul(); // 3 fouls in period 1.

      await playOutCurrentPeriod(); // -> period 2, level 0-0.
      expect(find.text(l10n.periodLabelSecondHalf), findsOneWidget);

      // Reset to 0 at the start of period 2 — not carried from period 1.
      for (var i = 0; i < 5; i++) {
        await addFoul();
      }
      expect(
        find.text(l10n.bonusIndicatorLabel),
        findsNothing,
      ); // 5 fouls in P2: not yet.

      await playOutCurrentPeriod(); // level 0-0 at 90:00 (knockout) -> extra time.
      expect(find.text(l10n.overtimeLabel(1)), findsOneWidget);

      // Extra time carries P2's tally forward unchanged (5) — one more
      // foul here reaches the 6th and triggers DFKSAF, proving it was
      // never reset entering extra time.
      await addFoul();
      expect(find.text(l10n.bonusIndicatorLabel), findsOneWidget);
      semanticsHandle.dispose();
    },
  );
}
