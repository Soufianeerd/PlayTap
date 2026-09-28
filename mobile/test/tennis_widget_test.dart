// Tennis UI flows — kept in its own file rather than appended to the
// already-large widget_test.dart, mirroring petanque_widget_test.dart's
// standalone-file shape (see that file's header for why the small test
// harness is duplicated rather than shared).
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtap/app/app.dart';
import 'package:playtap/app/providers/database_providers.dart';
import 'package:playtap/data/local/app_database.dart';
import 'package:playtap/domain/events/session_event.dart';
import 'package:playtap/domain/models/racket_state.dart';
import 'package:playtap/features/score_tennis/tennis_actions.dart';
import 'package:playtap/features/score_tennis/tennis_session_controller.dart';
import 'package:playtap/features/shared/pill_selector.dart';
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

AppLocalizations l10nOf(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(Scaffold).first))!;

/// Navigates Activités -> Score -> Tennis -> config. Leaves the tester on
/// the config page so the caller can pick type/scoring/deciding-set before
/// tapping START.
Future<void> openTennisConfig(WidgetTester tester) async {
  final l10n = l10nOf(tester);
  await tester.tap(find.text(l10n.categoryScore));
  await tester.pumpAndSettle();
  await tester.tap(find.text(l10n.presetTennis));
  await tester.pumpAndSettle();
}

/// Plays [gameCount] straight-4-0 games for [winnerName] against the
/// active session's big tap zones — the minimal point sequence that wins
/// each game outright, used to drive a set/match to completion quickly.
Future<void> playStraightGames(
  WidgetTester tester,
  String winnerName,
  int gameCount,
) async {
  for (var g = 0; g < gameCount; g++) {
    for (var p = 0; p < 4; p++) {
      await tester.tap(find.text(winnerName));
      await tester.pumpAndSettle();
    }
  }
}

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  testWidgets(
    'FLOW — singles: deuce/advantage/undo, a full match to summary and '
    'history',
    (tester) async {
      await tester.pumpWidget(appWithFreshDb());
      await tester.pumpAndSettle();
      final l10n = l10nOf(tester);
      final semanticsHandle = tester.ensureSemantics();

      await openTennisConfig(tester);
      // Singles is the default TYPE selection — no extra tap needed.
      await tester.tap(find.text(l10n.startButton));
      await tester.pumpAndSettle();

      final playerA = l10n.defaultParticipantName(1);
      final playerB = l10n.defaultParticipantName(2);
      expect(find.text(playerA), findsOneWidget);
      expect(find.text(playerB), findsOneWidget);

      // Semantics nodes here merge with their child Text's own label (see
      // futsal_match_control_widget_test.dart for the same pattern), so the
      // match is by substring, not exact equality.
      expect(
        find.bySemanticsLabel(
          RegExp(RegExp.escape(l10n.tennisPointSemantics(playerA))),
        ),
        findsOneWidget,
      );

      Future<void> tapA() async {
        await tester.tap(find.text(playerA));
        await tester.pumpAndSettle();
      }

      Future<void> tapB() async {
        await tester.tap(find.text(playerB));
        await tester.pumpAndSettle();
      }

      // Reach deuce (3-3 points).
      await tapA();
      await tapB();
      await tapA();
      await tapB();
      await tapA();
      await tapB();
      // Both cells read "Deuce" — the label is symmetric (see
      // `RacketLabels.gamePointLabels`), not just shown on one side.
      expect(find.text(l10n.tennisDeuceLabel), findsNWidgets(2));

      // Advantage side_a — only the leading side gets the "Advantage" label,
      // the other reads "40".
      await tapA();
      expect(find.text(l10n.tennisAdvantageLabel), findsOneWidget);
      expect(find.text('40'), findsOneWidget);

      // Undo reverts to deuce — obligatory undo, section 16.
      await tester.tap(find.text(l10n.tennisUndoLastPoint));
      await tester.pumpAndSettle();
      expect(find.text(l10n.tennisDeuceLabel), findsNWidgets(2));

      // side_a closes game 1 (advantage, then the winning point).
      await tapA();
      await tapA();
      expect(find.text('1'), findsOneWidget); // Games row: 1-0.

      // 5 more straight games close set 1 at 6-0.
      await playStraightGames(tester, playerA, 5);
      expect(find.text(l10n.tennisSetLabel(2)), findsOneWidget);

      // 6 straight games close set 2 at 6-0 — match complete, Best of 3.
      await playStraightGames(tester, playerA, 6);

      expect(find.text(l10n.summaryTitle), findsOneWidget);
      expect(find.text(l10n.winnerAnnouncement(playerA)), findsOneWidget);
      expect(find.text('6-0, 6-0'), findsOneWidget);

      await tester.tap(find.text(l10n.viewHistoryButton));
      await tester.pumpAndSettle();

      expect(find.text(l10n.presetTennis), findsOneWidget);
      expect(find.textContaining('$playerA 2'), findsOneWidget);
      expect(find.textContaining('6-0, 6-0'), findsOneWidget);
      semanticsHandle.dispose();
    },
  );

  testWidgets(
    'FLOW — doubles: 4 player fields, independent first-server choice per '
    'side, chosen server shown on the active session, Match Tie-Break 10 '
    'selectable',
    (tester) async {
      await tester.pumpWidget(appWithFreshDb());
      await tester.pumpAndSettle();
      final l10n = l10nOf(tester);

      await openTennisConfig(tester);
      await tester.tap(find.text(l10n.tennisTypeDoubles));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.tennisDecidingSetMatchTieBreak));
      await tester.pumpAndSettle();

      // 2 sides x 2 players.
      expect(find.text(l10n.participantNameLabel(1)), findsNWidgets(2));
      expect(find.text(l10n.participantNameLabel(2)), findsNWidgets(2));

      // 3 int pickers once doubles is selected: first serving side, side
      // A's own first-server choice, side B's own — each independent, per
      // ITF Rule 14 (CLAUDE.md brief section 6: never infer side B's pick
      // from side A's).
      final pickers = find.byType(PillSelector<int>);
      expect(pickers, findsNWidgets(3));
      final sideAServerPicker = pickers.at(1);
      final sideBServerPicker = pickers.at(2);

      final player3 = l10n.defaultParticipantName(3); // side A's 2nd player.
      final player4 = l10n.defaultParticipantName(4); // side B's 2nd player.

      final player3Pill = find.descendant(
        of: sideAServerPicker,
        matching: find.text(player3),
      );
      expect(player3Pill, findsOneWidget);
      await tester.ensureVisible(player3Pill);
      await tester.tap(player3Pill);
      await tester.pumpAndSettle();

      final player4Pill = find.descendant(
        of: sideBServerPicker,
        matching: find.text(player4),
      );
      expect(player4Pill, findsOneWidget);
      await tester.ensureVisible(player4Pill);
      await tester.tap(player4Pill);
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n.startButton));
      await tester.pumpAndSettle();

      // First serving side defaults to side A -> side A's own pick (player
      // 3) serves the match's first game, never side B's independent pick.
      expect(find.text(l10n.tennisServerLabel(player3)), findsOneWidget);
    },
  );

  testWidgets(
    'FLOW — doubles: closing set 1 blocks scoring behind a service-order '
    'sheet (ITF Rule 14), confirming it resumes scoring with the newly '
    'chosen server',
    (tester) async {
      await tester.pumpWidget(appWithFreshDb());
      await tester.pumpAndSettle();
      final l10n = l10nOf(tester);

      await openTennisConfig(tester);
      await tester.tap(find.text(l10n.tennisTypeDoubles));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.startButton));
      await tester.pumpAndSettle();

      final player1 = l10n.defaultParticipantName(1);
      final player3 = l10n.defaultParticipantName(3);
      final player4 = l10n.defaultParticipantName(4);
      final sideAName = '$player1 / $player3';

      // Default config: side A serves first, via player 1. Straight 6-0
      // closes set 1 with an even total (6 games) — side A mechanically
      // opens set 2's service too.
      await playStraightGames(tester, sideAName, 6);

      // Scoring is blocked behind the (non-dismissible) sheet: the big tap
      // zones underneath a real modal barrier can't be reached, but assert
      // the sheet itself is what's showing.
      expect(find.text(l10n.tennisServiceOrderSheetTitle(2)), findsOneWidget);
      expect(find.text(l10n.tennisContinueButton), findsOneWidget);

      // Reconfigure: side A's 2nd player (player 3) and side B's 2nd
      // player (player 4) open set 2's service instead of the set 1
      // defaults.
      final sheetPickers = find.byType(PillSelector<int>);
      expect(sheetPickers, findsNWidgets(2));
      await tester.tap(
        find.descendant(of: sheetPickers.at(0), matching: find.text(player3)),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(of: sheetPickers.at(1), matching: find.text(player4)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n.tennisContinueButton));
      await tester.pumpAndSettle();

      // Sheet dismissed, scoring resumed, server is the newly chosen one.
      expect(find.text(l10n.tennisServiceOrderSheetTitle(2)), findsNothing);
      expect(find.text(l10n.tennisServerLabel(player3)), findsOneWidget);

      // One more game (side B) rotates locally within set 2's own order:
      // side B's newly chosen player (player 4) serves next.
      final sideBName = '${l10n.defaultParticipantName(2)} / $player4';
      await playStraightGames(tester, sideBName, 1);
      expect(find.text(l10n.tennisServerLabel(player4)), findsOneWidget);
    },
  );

  testWidgets(
    'FLOW — change-of-ends indicator appears after odd games and clears on '
    "the next game's first point (ITF Rule 10)",
    (tester) async {
      await tester.pumpWidget(appWithFreshDb());
      await tester.pumpAndSettle();
      final l10n = l10nOf(tester);

      await openTennisConfig(tester);
      await tester.tap(find.text(l10n.startButton));
      await tester.pumpAndSettle();

      final playerA = l10n.defaultParticipantName(1);
      final playerB = l10n.defaultParticipantName(2);

      expect(find.text(l10n.tennisChangeEndsLabel), findsNothing);

      await playStraightGames(tester, playerA, 1); // game 1: odd -> due.
      expect(find.text(l10n.tennisChangeEndsLabel), findsOneWidget);

      await tester.tap(find.text(playerA)); // 1st point of game 2.
      await tester.pumpAndSettle();
      expect(find.text(l10n.tennisChangeEndsLabel), findsNothing);

      await playStraightGames(tester, playerB, 2); // finishes game 2, then 3.
      expect(find.text(l10n.tennisChangeEndsLabel), findsOneWidget);
    },
  );

  testWidgets('FLOW — manual abandon before match completion lands back on '
      'History', (tester) async {
    await tester.pumpWidget(appWithFreshDb());
    await tester.pumpAndSettle();
    final l10n = l10nOf(tester);

    await openTennisConfig(tester);
    await tester.tap(find.text(l10n.startButton));
    await tester.pumpAndSettle();

    final playerA = l10n.defaultParticipantName(1);
    await tester.tap(find.text(playerA));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.flag_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.abandonGameButton));
    await tester.pumpAndSettle();

    expect(find.text(l10n.navHistory), findsWidgets);
    expect(find.text(l10n.presetTennis), findsNothing);
  });

  testWidgets(
    'FLOW — rapid double-tap on the same zone records only one point',
    (tester) async {
      await tester.pumpWidget(appWithFreshDb());
      await tester.pumpAndSettle();
      final l10n = l10nOf(tester);

      await openTennisConfig(tester);
      await tester.tap(find.text(l10n.startButton));
      await tester.pumpAndSettle();

      final playerA = l10n.defaultParticipantName(1);
      // Two taps fired back-to-back, before the first's async body settles
      // (no pumpAndSettle between them) — simulates a finger-bounce
      // double-tap on the same big tap zone.
      await tester.tap(find.text(playerA));
      await tester.tap(find.text(playerA));
      await tester.pumpAndSettle();

      // Exactly one point recorded (15), not two (30).
      expect(find.text('15'), findsOneWidget);
      expect(find.text('30'), findsNothing);
    },
  );

  testWidgets(
    'CONTROLLER GUARD — TennisSessionController.addPoint() itself refuses '
    'a point while a doubles set needs service configuration, independent '
    "of the UI's tap-zone gating, and accepts one normally once configured",
    (tester) async {
      await tester.pumpWidget(appWithFreshDb());
      await tester.pumpAndSettle();
      final l10n = l10nOf(tester);

      await openTennisConfig(tester);
      await tester.tap(find.text(l10n.tennisTypeDoubles));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.startButton));
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(Scaffold).first),
      );
      final session = await container
          .read(sessionRepositoryProvider)
          .getActiveSession();
      final sessionId = session!.id;
      final notifier = container.read(
        tennisSessionControllerProvider(sessionId).notifier,
      );
      RacketMatchState currentMatchState() => container
          .read(tennisSessionControllerProvider(sessionId))
          .value!
          .matchState;

      final player1 = l10n.defaultParticipantName(1);
      final player3 = l10n.defaultParticipantName(3);
      final sideAName = '$player1 / $player3';

      // Close set 1 (6-0, even) through the UI — same as any real match —
      // leaving set 2 unconfigured behind the (already-tested) sheet.
      await playStraightGames(tester, sideAName, 6);
      expect(currentMatchState().needsServiceConfiguration, isTrue);

      Future<int> pointEventCount() async =>
          (await container
                  .read(eventRepositoryProvider)
                  .getEventsForSession(sessionId))
              .where((e) => e.type == SessionEventType.pointScored)
              .length;
      final pointsBefore = await pointEventCount();

      // Call the controller method directly — never through a tap — to
      // prove the guard lives in TennisSessionController.addPoint itself,
      // not merely in the UI disabling its tap zones (CLAUDE.md brief
      // section 2): a future caller (watch sync, a direct action) must not
      // be able to bypass it.
      await notifier.addPoint(sideATennisId);
      await tester.pumpAndSettle();

      expect(await pointEventCount(), pointsBefore); // no new POINT_SCORED.
      final blocked = currentMatchState();
      expect(blocked.needsServiceConfiguration, isTrue);
      expect(blocked.currentSetIndex, 1);
      expect(blocked.gamesWonInCurrentSet, {
        sideATennisId: 0,
        sideBTennisId: 0,
      });
      expect(blocked.currentGamePoints, {sideATennisId: 0, sideBTennisId: 0});

      // Configure service order (also directly through the controller) —
      // addPoint must now be accepted normally.
      await notifier.configureServiceOrder(
        segmentIndex: 1,
        order: buildDoublesSegmentServiceOrder(
          startingSideId: sideATennisId,
          startingSidePlayerIndex: 0,
          otherSidePlayerIndex: 0,
        ),
      );
      await tester.pumpAndSettle();
      expect(currentMatchState().needsServiceConfiguration, isFalse);

      await notifier.addPoint(sideATennisId);
      await tester.pumpAndSettle();

      expect(await pointEventCount(), pointsBefore + 1);
      expect(currentMatchState().currentGamePoints[sideATennisId], 1);
    },
  );
}
