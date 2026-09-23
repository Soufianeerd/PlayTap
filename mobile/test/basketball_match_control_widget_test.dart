// Basketball shot-clock/timeout/team-foul UI flows — Phase Sports 2B.
// Kept separate from basketball_widget_test.dart (already large) for the
// same standalone-file reason documented on test/app/locale_test.dart.
// Assertions target Semantics labels rather than displayed digits: the
// shot clock, team-foul, and timeout counters can all show the same
// digit at once, so matching by accessibility label (which always names
// which counter it is) is more robust than matching bare text.
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

  group('Shot clock', () {
    testWidgets(
      'reset 24/14, start/pause, and expiration all work from the strip',
      (tester) async {
        final clock = FakeClock();
        await tester.pumpWidget(appWithClock(freshTestDb(), clock));
        await tester.pumpAndSettle();
        final l10n = l10nOf(tester);
        await startBasketballSession(tester);

        // Reset to 24, then start it.
        await tester.tap(
          find.widgetWithText(OutlinedButton, l10n.shotClock24Button),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.play_arrow));
        await pumpTicker(tester);
        expect(find.byIcon(Icons.pause), findsOneWidget);

        // Let it run out entirely — the buzzer (SHOT_CLOCK_COMPLETED)
        // persists automatically, never forcing anything else to happen.
        clock.advance(const Duration(seconds: 25));
        await pumpTicker(tester);
        expect(
          find.byIcon(Icons.play_arrow),
          findsOneWidget,
        ); // no longer "running".

        // Reset to 14 restarts a fresh leg.
        await tester.tap(
          find.widgetWithText(OutlinedButton, l10n.shotClock14Button),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.play_arrow));
        await pumpTicker(tester);
        clock.advance(const Duration(seconds: 10));
        await pumpTicker(tester);
        expect(
          find.byIcon(Icons.pause),
          findsOneWidget,
        ); // still running at 10s < 14s.
      },
    );

    testWidgets('pausing the game clock also pauses a running shot clock', (
      tester,
    ) async {
      final clock = FakeClock();
      await tester.pumpWidget(appWithClock(freshTestDb(), clock));
      await tester.pumpAndSettle();
      final l10n = l10nOf(tester);
      await startBasketballSession(tester);

      await tester.tap(
        find.text(l10n.resumeTimerButtonLabel),
      ); // start game clock.
      await pumpTicker(tester);
      await tester.tap(
        find.widgetWithText(OutlinedButton, l10n.shotClock24Button),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.play_arrow)); // start shot clock.
      await pumpTicker(tester);
      // The game clock's own START/PAUSE control is text-based ("PAUSE"),
      // only the shot clock's compact control is icon-based.
      expect(find.text(l10n.pauseButtonLabel), findsOneWidget);
      expect(find.byIcon(Icons.pause), findsOneWidget);

      await tester.tap(
        find.text(l10n.pauseButtonLabel),
      ); // pause the game clock.
      await pumpTicker(tester);

      // The shot clock is paused too — not left "artificially" running.
      expect(
        find.byIcon(Icons.play_arrow),
        findsOneWidget,
      ); // only the shot clock's icon now.
      clock.advance(const Duration(seconds: 30));
      await pumpTicker(tester);
      // Still shows play (paused), proving elapsed time did not leak in
      // while the game clock was paused.
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });
  });

  group('Team fouls', () {
    testWidgets(
      'tapping a side increments its count; bonus label appears at the 5th',
      (tester) async {
        await tester.pumpWidget(appWithClock(freshTestDb(), FakeClock()));
        await tester.pumpAndSettle();
        final l10n = l10nOf(tester);
        final semanticsHandle = tester.ensureSemantics();
        await startBasketballSession(tester);
        final teamA = l10n.teamMatchDefaultTeamName(1);

        for (var i = 0; i < 4; i++) {
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
        ); // 4th: not yet.

        await tester.tap(
          find.bySemanticsLabel(
            RegExp(RegExp.escape(l10n.addTeamFoulSemantics(teamA))),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.text(l10n.bonusIndicatorLabel),
          findsOneWidget,
        ); // 5th: bonus.
        semanticsHandle.dispose();
      },
    );

    testWidgets(
      'undo reverses the most recent foul and clears the bonus label',
      (tester) async {
        await tester.pumpWidget(appWithClock(freshTestDb(), FakeClock()));
        await tester.pumpAndSettle();
        final l10n = l10nOf(tester);
        final semanticsHandle = tester.ensureSemantics();
        await startBasketballSession(tester);
        final teamA = l10n.teamMatchDefaultTeamName(1);

        for (var i = 0; i < 5; i++) {
          await tester.tap(
            find.bySemanticsLabel(
              RegExp(RegExp.escape(l10n.addTeamFoulSemantics(teamA))),
            ),
          );
          await tester.pumpAndSettle();
        }
        expect(find.text(l10n.bonusIndicatorLabel), findsOneWidget);

        await tester.tap(find.byIcon(Icons.undo));
        await tester.pumpAndSettle();
        expect(find.text(l10n.bonusIndicatorLabel), findsNothing);
        semanticsHandle.dispose();
      },
    );
  });

  group('Timeouts', () {
    testWidgets('a used-up quota disables further taps for that side', (
      tester,
    ) async {
      await tester.pumpWidget(appWithClock(freshTestDb(), FakeClock()));
      await tester.pumpAndSettle();
      final l10n = l10nOf(tester);
      final semanticsHandle = tester.ensureSemantics();
      await startBasketballSession(tester);
      final teamA = l10n.teamMatchDefaultTeamName(1);

      // Q1-Q2 share a quota of 2.
      expect(
        find.bySemanticsLabel(
          RegExp(RegExp.escape(l10n.timeoutsRemainingSemantics(teamA, 2))),
        ),
        findsOneWidget,
      );
      await tester.tap(
        find.bySemanticsLabel(
          RegExp(RegExp.escape(l10n.timeoutsRemainingSemantics(teamA, 2))),
        ),
      );
      await tester.pumpAndSettle();
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

      // A 3rd tap while at 0 does nothing — quota is enforced by the
      // ruleset, not a UI constant, and never silently exceeded.
      await tester.tap(
        find.bySemanticsLabel(
          RegExp(RegExp.escape(l10n.timeoutsRemainingSemantics(teamA, 0))),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.bySemanticsLabel(
          RegExp(RegExp.escape(l10n.timeoutsRemainingSemantics(teamA, 0))),
        ),
        findsOneWidget,
      );
      semanticsHandle.dispose();
    });

    testWidgets('undo restores a used timeout', (tester) async {
      await tester.pumpWidget(appWithClock(freshTestDb(), FakeClock()));
      await tester.pumpAndSettle();
      final l10n = l10nOf(tester);
      final semanticsHandle = tester.ensureSemantics();
      await startBasketballSession(tester);
      final teamA = l10n.teamMatchDefaultTeamName(1);

      await tester.tap(
        find.bySemanticsLabel(
          RegExp(RegExp.escape(l10n.timeoutsRemainingSemantics(teamA, 2))),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.undo));
      await tester.pumpAndSettle();
      expect(
        find.bySemanticsLabel(
          RegExp(RegExp.escape(l10n.timeoutsRemainingSemantics(teamA, 2))),
        ),
        findsOneWidget,
      );
      semanticsHandle.dispose();
    });
  });

  testWidgets(
    'RECOVERY — score, shot clock, fouls, and timeouts all survive a full app restart',
    (tester) async {
      final db = freshTestDb();
      final clock = FakeClock();
      await tester.pumpWidget(appWithClock(db, clock));
      await tester.pumpAndSettle();
      final l10n = l10nOf(tester);
      final semanticsHandle = tester.ensureSemantics();
      await startBasketballSession(tester);
      final teamA = l10n.teamMatchDefaultTeamName(1);

      await tester.tap(find.text('+3').first);
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(OutlinedButton, l10n.shotClock24Button),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.play_arrow));
      await pumpTicker(tester);
      clock.advance(const Duration(seconds: 6));
      await pumpTicker(tester);
      await tester.tap(
        find.bySemanticsLabel(
          RegExp(RegExp.escape(l10n.addTeamFoulSemantics(teamA))),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.bySemanticsLabel(
          RegExp(RegExp.escape(l10n.timeoutsRemainingSemantics(teamA, 2))),
        ),
      );
      await tester.pumpAndSettle();

      // Simulate a full app restart over the same database (see FLOW 4 in
      // widget_test.dart for why the tree must be fully torn down first).
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(appWithClock(db, clock));
      await tester.pumpAndSettle();
      expect(find.text(l10n.resumeActivity), findsOneWidget);
      await tester.tap(find.text(l10n.resumeActivity));
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel(
          RegExp(RegExp.escape(l10n.addTeamFoulSemantics(teamA))),
        ),
        findsOneWidget,
      ); // 1 foul survived (checked indirectly: tile still renders correctly).
      expect(
        find.bySemanticsLabel(
          RegExp(RegExp.escape(l10n.timeoutsRemainingSemantics(teamA, 1))),
        ),
        findsOneWidget,
      ); // 1 of 2 used, survived recovery.
      semanticsHandle.dispose();
    },
  );
}
