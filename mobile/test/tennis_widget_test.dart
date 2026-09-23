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
    'FLOW — doubles: 4 player fields, 4-way server picker, chosen server '
    'shown on the active session, Match Tie-Break 10 selectable',
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

      // 4-way initial-server picker, defaulting to player 1. Scoped to the
      // PillSelector explicitly (not `.last`): the same name also appears
      // in its own TextField, and relying on tree-traversal order between
      // the two would be fragile.
      final player3 = l10n.defaultParticipantName(3);
      expect(find.text(player3), findsWidgets); // field + pill option.
      final player3Pill = find.descendant(
        of: find.byType(PillSelector<String>),
        matching: find.text(player3),
      );
      expect(player3Pill, findsOneWidget);

      // The picker sits below the fold in the config page's scroll view —
      // tapping it without scrolling first hits an off-screen coordinate
      // and silently no-ops (no exception, `_initialServerId` just never
      // changes).
      await tester.ensureVisible(player3Pill);
      await tester.tap(player3Pill);
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n.startButton));
      await tester.pumpAndSettle();

      expect(find.text(l10n.tennisServerLabel(player3)), findsOneWidget);
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
}
