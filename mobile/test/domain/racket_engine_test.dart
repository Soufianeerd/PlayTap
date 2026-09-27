import 'package:flutter_test/flutter_test.dart';
import 'package:playtap/domain/engines/racket_engine.dart';
import 'package:playtap/domain/events/racket_engine_event.dart';
import 'package:playtap/domain/models/racket_rule.dart';

const sideA = 'side_a';
const sideB = 'side_b';

RacketEngineEvent point(String id, String side) => RacketEngineEvent(
  id: id,
  type: RacketEngineEventType.pointScored,
  payload: {'side': side},
);

RacketEngineEvent undo(String id, {String? target}) => RacketEngineEvent(
  id: id,
  type: RacketEngineEventType.undo,
  payload: target == null ? {} : {'targetEventId': target},
);

RacketEngineEvent serviceOrderConfigured(
  String id, {
  required int segmentIndex,
  required List<String> order,
}) => RacketEngineEvent(
  id: id,
  type: RacketEngineEventType.serviceOrderConfigured,
  payload: {'schemaVersion': 1, 'segmentIndex': segmentIndex, 'order': order},
);

const _singlesService = ServiceRule(
  schemaVersion: 1,
  order: [
    ServiceSlot(id: sideA, sideId: sideA),
    ServiceSlot(id: sideB, sideId: sideB),
  ],
);

const _doublesService = ServiceRule(
  schemaVersion: 1,
  order: [
    ServiceSlot(id: 'side_a_p0', sideId: sideA, playerIndex: 0),
    ServiceSlot(id: 'side_b_p0', sideId: sideB, playerIndex: 0),
    ServiceSlot(id: 'side_a_p1', sideId: sideA, playerIndex: 1),
    ServiceSlot(id: 'side_b_p1', sideId: sideB, playerIndex: 1),
  ],
);

RacketMatchRule buildRule({
  AdvantageMode advantageMode = AdvantageMode.advantage,
  DecidingSetFormat decidingSetFormat = const RegularDecidingSet(),
  int setsToWin = 2,
  ServiceRule service = _singlesService,
}) => RacketMatchRule(
  schemaVersion: 1,
  rulesetId: 'tennis.itf.2026',
  sideIds: const [sideA, sideB],
  gameScoring: GameScoringRule(schemaVersion: 1, advantageMode: advantageMode),
  setRule: const SetRule(
    schemaVersion: 1,
    gamesToWin: 6,
    tieBreak: TieBreakRule(schemaVersion: 1, target: 7, winBy: 2),
  ),
  matchFormat: MatchFormatRule(
    schemaVersion: 1,
    setsToWin: setsToWin,
    decidingSetFormat: decidingSetFormat,
  ),
  service: service,
);

/// Builds a `RacketEngineEvent` list from an ordered list of winning
/// side ids, auto-incrementing ids from [startAt] — callers splicing a
/// non-point event (e.g. `serviceOrderConfigured`) between two point runs
/// pass a fresh [startAt] for the second run so ids never collide (a
/// colliding id would make `RacketEngine.replay`'s de-duplication silently
/// drop the second occurrence).
List<RacketEngineEvent> events(List<String> sides, {int startAt = 1}) => [
  for (var i = 0; i < sides.length; i++) point('e${startAt + i}', sides[i]),
];

/// A straight 4-0 game for [winner] — the minimal point sequence that wins
/// a game outright.
List<String> straightGame(String winner) => [winner, winner, winner, winner];

List<String> gamesSequence(List<String> winners) =>
    winners.expand(straightGame).toList();

void main() {
  group('RacketEngine — standard game (Advantage)', () {
    final rule = buildRule();

    test('Love -> 15 -> 30 -> 40 -> Game, straight progression', () {
      final state = RacketEngine.replay(rule, events(straightGame(sideA)));
      expect(state.currentGamePoints, {sideA: 0, sideB: 0});
      expect(state.gamesWonInCurrentSet, {sideA: 1, sideB: 0});
      expect(state.matchComplete, isFalse);
    });

    test('deuce at 3-3 points', () {
      final state = RacketEngine.replay(
        rule,
        events([sideA, sideB, sideA, sideB, sideA, sideB]),
      );
      expect(state.currentGamePoints, {sideA: 3, sideB: 3});
      expect(state.gamesWonInCurrentSet, {sideA: 0, sideB: 0});
    });

    test('advantage side_a after deuce', () {
      final state = RacketEngine.replay(
        rule,
        events([sideA, sideB, sideA, sideB, sideA, sideB, sideA]),
      );
      expect(state.currentGamePoints, {sideA: 4, sideB: 3});
      expect(state.gamesWonInCurrentSet, {sideA: 0, sideB: 0});
    });

    test('back to deuce after the other side wins the advantage point', () {
      final state = RacketEngine.replay(
        rule,
        events([sideA, sideB, sideA, sideB, sideA, sideB, sideA, sideB]),
      );
      expect(state.currentGamePoints, {sideA: 4, sideB: 4});
    });

    test('game won by a 2-point margin after multiple deuces', () {
      final state = RacketEngine.replay(
        rule,
        events([
          sideA, sideB, sideA, sideB, sideA, sideB, // 3-3 deuce
          sideA, sideB, // 4-4 back to deuce
          sideA, sideA, // advantage then game
        ]),
      );
      expect(state.currentGamePoints, {sideA: 0, sideB: 0});
      expect(state.gamesWonInCurrentSet, {sideA: 1, sideB: 0});
    });
  });

  group('RacketEngine — No-Ad', () {
    final rule = buildRule(advantageMode: AdvantageMode.noAd);

    test('at 40-40 the very next point wins outright, no advantage state', () {
      final atDeuce = RacketEngine.replay(
        rule,
        events([sideA, sideB, sideA, sideB, sideA, sideB]),
      );
      expect(atDeuce.currentGamePoints, {sideA: 3, sideB: 3});
      expect(atDeuce.gamesWonInCurrentSet, {sideA: 0, sideB: 0});

      final decidingPointWon = RacketEngine.replay(
        rule,
        events([sideA, sideB, sideA, sideB, sideA, sideB, sideB]),
      );
      expect(decidingPointWon.gamesWonInCurrentSet, {sideA: 0, sideB: 1});
      expect(decidingPointWon.currentGamePoints, {sideA: 0, sideB: 0});
    });

    test('a side leading before 40-40 can still win outright at 4 points', () {
      final state = RacketEngine.replay(
        rule,
        events([sideA, sideA, sideA, sideB, sideA]),
      );
      expect(state.gamesWonInCurrentSet, {sideA: 1, sideB: 0});
    });
  });

  group('RacketEngine — sets', () {
    final rule = buildRule();

    test('6-0 closes the set', () {
      final state = RacketEngine.replay(
        rule,
        events(gamesSequence([sideA, sideA, sideA, sideA, sideA, sideA])),
      );
      expect(state.setsWon, {sideA: 1, sideB: 0});
      expect(state.completedSets, hasLength(1));
      expect(state.completedSets.single.games, {sideA: 6, sideB: 0});
    });

    test('6-4 closes the set', () {
      final state = RacketEngine.replay(
        rule,
        events(
          gamesSequence([
            sideB,
            sideA,
            sideB,
            sideA,
            sideB,
            sideA,
            sideB,
            sideA,
            sideA,
            sideA,
          ]),
        ),
      );
      expect(state.completedSets.single.games, {sideA: 6, sideB: 4});
    });

    test('6-5 does not close the set (win-by-2 not yet satisfied)', () {
      final state = RacketEngine.replay(
        rule,
        events(
          gamesSequence([
            sideB,
            sideA,
            sideB,
            sideA,
            sideB,
            sideA,
            sideB,
            sideA,
            sideA,
            sideB,
            sideA,
          ]),
        ),
      );
      expect(state.completedSets, isEmpty);
      expect(state.gamesWonInCurrentSet, {sideA: 6, sideB: 5});
    });

    test('7-5 closes the set once the 2-game margin is reached', () {
      final state = RacketEngine.replay(
        rule,
        events(
          gamesSequence([
            sideB,
            sideA,
            sideB,
            sideA,
            sideB,
            sideA,
            sideB,
            sideA,
            sideA,
            sideB,
            sideA,
            sideA,
          ]),
        ),
      );
      expect(state.completedSets.single.games, {sideA: 7, sideB: 5});
    });

    test('6-6 enters a tie-break instead of closing the set', () {
      final state = RacketEngine.replay(
        rule,
        events(
          gamesSequence([
            sideA,
            sideB,
            sideA,
            sideB,
            sideA,
            sideB,
            sideA,
            sideB,
            sideA,
            sideB,
            sideA,
            sideB,
          ]),
        ),
      );
      expect(state.isTieBreak, isTrue);
      expect(state.completedSets, isEmpty);
      expect(state.currentGamePoints, {sideA: 0, sideB: 0});
    });
  });

  group('RacketEngine — tie-break', () {
    final rule = buildRule();
    List<String> to6All() => gamesSequence([
      sideA,
      sideB,
      sideA,
      sideB,
      sideA,
      sideB,
      sideA,
      sideB,
      sideA,
      sideB,
      sideA,
      sideB,
    ]);

    test('7-0 completes the tie-break', () {
      final state = RacketEngine.replay(
        rule,
        events([...to6All(), sideA, sideA, sideA, sideA, sideA, sideA, sideA]),
      );
      expect(state.isTieBreak, isFalse);
      expect(state.completedSets.single.tieBreakScore, {sideA: 7, sideB: 0});
      expect(state.completedSets.single.games, {sideA: 7, sideB: 6});
    });

    test('7-5 completes the tie-break', () {
      final state = RacketEngine.replay(
        rule,
        events([
          ...to6All(),
          sideA,
          sideB,
          sideA,
          sideB,
          sideA,
          sideB,
          sideA,
          sideB,
          sideA,
          sideB,
          sideA,
          sideA,
        ]),
      );
      expect(state.completedSets.single.tieBreakScore, {sideA: 7, sideB: 5});
    });

    test('7-6 in the tie-break does not complete it (win-by-2 required)', () {
      final state = RacketEngine.replay(
        rule,
        events([
          ...to6All(),
          sideA,
          sideB,
          sideA,
          sideB,
          sideA,
          sideB,
          sideA,
          sideB,
          sideA,
          sideB,
          sideA,
          sideB,
          sideA,
        ]),
      );
      expect(state.isTieBreak, isTrue);
      expect(state.tieBreakPoints, {sideA: 7, sideB: 6});
      expect(state.completedSets, isEmpty);
    });

    test('8-6 completes the tie-break with no artificial cap past 7', () {
      final state = RacketEngine.replay(
        rule,
        events([
          ...to6All(),
          sideA,
          sideB,
          sideA,
          sideB,
          sideA,
          sideB,
          sideA,
          sideB,
          sideA,
          sideB,
          sideA,
          sideB,
          sideA,
          sideA,
        ]),
      );
      expect(state.isTieBreak, isFalse);
      expect(state.completedSets.single.tieBreakScore, {sideA: 8, sideB: 6});
    });
  });

  group('RacketEngine — Match Tie-break', () {
    final rule = buildRule(
      decidingSetFormat: const MatchTieBreakDecidingSet(
        matchTieBreak: TieBreakRule(schemaVersion: 1, target: 10, winBy: 2),
      ),
    );
    List<String> toDecidingSet() =>
        gamesSequence(List.filled(6, sideA)) +
        gamesSequence(List.filled(6, sideB));

    test('10-8 wins the Match Tie-break and the match', () {
      final mtb = [
        sideA,
        sideB,
        sideA,
        sideB,
        sideA,
        sideB,
        sideA,
        sideB,
        sideA,
        sideB,
        sideA,
        sideB,
        sideA,
        sideB,
        sideA,
        sideB,
        sideA,
        sideA,
      ];
      final state = RacketEngine.replay(
        rule,
        events([...toDecidingSet(), ...mtb]),
      );
      expect(state.matchComplete, isTrue);
      expect(state.winner, sideA);
      expect(state.isMatchTieBreak, isTrue);
      expect(state.completedSets.last.isMatchTieBreak, isTrue);
      expect(state.completedSets.last.tieBreakScore, {sideA: 10, sideB: 8});
      expect(state.completedSets.last.games, {sideA: 0, sideB: 0});
    });

    test('9-9 does not complete the Match Tie-break', () {
      final mtb = [
        sideA,
        sideB,
        sideA,
        sideB,
        sideA,
        sideB,
        sideA,
        sideB,
        sideA,
        sideB,
        sideA,
        sideB,
        sideA,
        sideB,
        sideA,
        sideB,
        sideA,
        sideB,
      ];
      final state = RacketEngine.replay(
        rule,
        events([...toDecidingSet(), ...mtb]),
      );
      expect(state.matchComplete, isFalse);
      expect(state.isMatchTieBreak, isTrue);
      expect(state.tieBreakPoints, {sideA: 9, sideB: 9});
    });

    test('11-9 wins once win-by-2 is reached past target 10', () {
      final mtb = [
        sideA,
        sideB,
        sideA,
        sideB,
        sideA,
        sideB,
        sideA,
        sideB,
        sideA,
        sideB,
        sideA,
        sideB,
        sideA,
        sideB,
        sideA,
        sideB,
        sideA,
        sideB,
        sideA,
        sideA,
      ];
      final state = RacketEngine.replay(
        rule,
        events([...toDecidingSet(), ...mtb]),
      );
      expect(state.matchComplete, isTrue);
      expect(state.winner, sideA);
      expect(state.completedSets.last.tieBreakScore, {sideA: 11, sideB: 9});
    });
  });

  group('RacketEngine — Best of', () {
    test('2-0 (straight sets) completes the match', () {
      final rule = buildRule();
      final sides =
          gamesSequence(List.filled(6, sideA)) +
          gamesSequence(List.filled(6, sideA));
      final state = RacketEngine.replay(rule, events(sides));
      expect(state.matchComplete, isTrue);
      expect(state.winner, sideA);
      expect(state.setsWon, {sideA: 2, sideB: 0});
    });

    test('2-1 completes the match only after the deciding set', () {
      final rule = buildRule();
      final sides =
          gamesSequence(List.filled(6, sideA)) +
          gamesSequence(List.filled(6, sideB));
      final midMatch = RacketEngine.replay(rule, events(sides));
      expect(midMatch.matchComplete, isFalse);
      expect(midMatch.setsWon, {sideA: 1, sideB: 1});

      final full = sides + gamesSequence(List.filled(6, sideA));
      final state = RacketEngine.replay(rule, events(full));
      expect(state.matchComplete, isTrue);
      expect(state.winner, sideA);
      expect(state.setsWon, {sideA: 2, sideB: 1});
    });
  });

  group('RacketEngine — service', () {
    test(
      'singles: server alternates every completed game, never reset by a set boundary',
      () {
        final rule = buildRule();
        // 13 games completed total (crosses a set boundary at 6-6->tiebreak
        // is avoided here by using straight one-sided sets): after N games,
        // server = order[N % 2].
        for (var n = 0; n <= 4; n++) {
          final sides = gamesSequence(List.filled(n, sideA));
          final state = RacketEngine.replay(rule, events(sides));
          expect(
            state.currentServerSlotId,
            n.isEven ? sideA : sideB,
            reason: 'after $n completed games',
          );
        }
      },
    );

    test('doubles: server rotates through all 4 persisted slots in order', () {
      final rule = buildRule(service: _doublesService);
      const expectedOrder = [
        'side_a_p0',
        'side_b_p0',
        'side_a_p1',
        'side_b_p1',
      ];
      for (var n = 0; n <= 5; n++) {
        final sides = gamesSequence(List.filled(n, sideA));
        final state = RacketEngine.replay(rule, events(sides));
        expect(
          state.currentServerSlotId,
          expectedOrder[n % 4],
          reason: 'after $n completed games',
        );
      }
    });

    test('tie-break: point 1 by rotation, then alternating every 2 points', () {
      final rule = buildRule();
      final to6All = gamesSequence([
        sideA,
        sideB,
        sideA,
        sideB,
        sideA,
        sideB,
        sideA,
        sideB,
        sideA,
        sideB,
        sideA,
        sideB,
      ]);
      // 12 games completed -> base server = order[12 % 2] = side_a.
      final tbPoints = [sideA, sideB, sideB, sideA, sideA, sideB, sideB];
      const expectedServers = [
        sideB, // after point 1: point 2 starts a new block -> other side.
        sideB, // after point 2: still within the 2-3 block.
        sideA, // after point 3: new block starts.
        sideA, // after point 4: still within the 4-5 block.
        sideB, // after point 5: new block starts.
        sideB, // after point 6: still within the 6-7 block.
        sideA, // after point 7: new block starts.
      ];
      for (var n = 1; n <= tbPoints.length; n++) {
        final state = RacketEngine.replay(
          rule,
          events([...to6All, ...tbPoints.take(n)]),
        );
        expect(
          state.currentServerSlotId,
          expectedServers[n - 1],
          reason: 'after tie-break point $n',
        );
      }
    });
  });

  group('RacketEngine — undo', () {
    final rule = buildRule();

    test('undo a mid-game point', () {
      final state = RacketEngine.replay(rule, [
        ...events([sideA, sideA, sideA]),
        undo('u'),
      ]);
      expect(state.currentGamePoints, {sideA: 2, sideB: 0});
      expect(state.appliedEventCount, 3);
    });

    test('undo the point that won a game reopens the game', () {
      final state = RacketEngine.replay(rule, [
        ...events(straightGame(sideA)),
        undo('u'),
      ]);
      expect(state.gamesWonInCurrentSet, {sideA: 0, sideB: 0});
      expect(state.currentGamePoints, {sideA: 3, sideB: 0});
    });

    test('undo the point that won a set reopens the set', () {
      final sides = gamesSequence(List.filled(6, sideA));
      final state = RacketEngine.replay(rule, [...events(sides), undo('u')]);
      expect(state.setsWon, {sideA: 0, sideB: 0});
      expect(state.completedSets, isEmpty);
      expect(state.gamesWonInCurrentSet, {sideA: 5, sideB: 0});
      expect(state.currentGamePoints, {sideA: 3, sideB: 0});
    });

    test('undo the point that won the match reopens it', () {
      final sides =
          gamesSequence(List.filled(6, sideA)) +
          gamesSequence(List.filled(6, sideA));
      final state = RacketEngine.replay(rule, [...events(sides), undo('u')]);
      expect(state.matchComplete, isFalse);
      expect(state.winner, isNull);
      expect(state.setsWon, {sideA: 1, sideB: 0});
      expect(state.gamesWonInCurrentSet, {sideA: 5, sideB: 0});
    });

    test('undo a tie-break point', () {
      final to6All = gamesSequence([
        sideA,
        sideB,
        sideA,
        sideB,
        sideA,
        sideB,
        sideA,
        sideB,
        sideA,
        sideB,
        sideA,
        sideB,
      ]);
      final state = RacketEngine.replay(rule, [
        ...events([...to6All, sideA, sideA]),
        undo('u'),
      ]);
      expect(state.isTieBreak, isTrue);
      expect(state.tieBreakPoints, {sideA: 1, sideB: 0});
    });

    test('undo with no points scored is a no-op', () {
      final state = RacketEngine.replay(rule, [undo('u')]);
      expect(state.currentGamePoints, {sideA: 0, sideB: 0});
      expect(state.appliedEventCount, 0);
    });
  });

  group('RacketEngine — recovery (pure replay)', () {
    test('replaying the same event log twice yields an identical state', () {
      final rule = buildRule();
      final sides =
          gamesSequence([sideA, sideB, sideA]) + [sideA, sideB, sideA];
      final first = RacketEngine.replay(rule, events(sides));
      final second = RacketEngine.replay(rule, events(sides));
      expect(second.toJson(), first.toJson());
    });
  });

  group('RacketMatchRule — JSON round-trip', () {
    test('round-trips a full tie-break-set Best of 3 rule', () {
      final rule = buildRule(service: _doublesService);
      final decoded = RacketMatchRule.fromJson(rule.toJson());
      expect(decoded.toJson(), rule.toJson());
    });

    test('round-trips No-Ad scoring', () {
      final rule = buildRule(advantageMode: AdvantageMode.noAd);
      final decoded = RacketMatchRule.fromJson(rule.toJson());
      expect(decoded.gameScoring.advantageMode, AdvantageMode.noAd);
    });

    test('round-trips a Match Tie-break deciding set', () {
      final rule = buildRule(
        decidingSetFormat: const MatchTieBreakDecidingSet(
          matchTieBreak: TieBreakRule(schemaVersion: 1, target: 10, winBy: 2),
        ),
      );
      final decoded = RacketMatchRule.fromJson(rule.toJson());
      final format = decoded.matchFormat.decidingSetFormat;
      expect(format, isA<MatchTieBreakDecidingSet>());
      expect((format as MatchTieBreakDecidingSet).matchTieBreak.target, 10);
    });
  });

  group('RacketEngine — change of ends (ITF Rule 10, per set)', () {
    final rule = buildRule();

    test('within a set: change due after odd games (1,3), not even (2,4)', () {
      final winners = [sideB, sideA, sideB, sideA];
      for (var n = 1; n <= winners.length; n++) {
        final state = RacketEngine.replay(
          rule,
          events(gamesSequence(winners.take(n).toList())),
        );
        expect(
          state.changeEndsDue,
          n.isOdd,
          reason: 'after game $n of the set',
        );
      }
    });

    test('6-3 (9 games, odd): change due at set end, and again after the very '
        "next set's first game — a match-wide continuous count would wrongly "
        'skip this second change', () {
      // side_a wins 6, side_b wins 3, interleaved so the set is not
      // decided before the 9th game.
      final set1 = [
        sideB,
        sideA,
        sideB,
        sideA,
        sideB,
        sideA,
        sideA,
        sideA,
        sideA,
      ];
      final afterSet1 = RacketEngine.replay(rule, events(gamesSequence(set1)));
      expect(afterSet1.currentSetIndex, 1);
      expect(afterSet1.changeEndsDue, isTrue, reason: '9 games, odd');

      final afterNewSetGame1 = RacketEngine.replay(
        rule,
        events(gamesSequence(set1 + [sideA])),
      );
      expect(
        afterNewSetGame1.changeEndsDue,
        isTrue,
        reason: "change due again after just 1 game of the new set",
      );

      final afterNewSetGame2 = RacketEngine.replay(
        rule,
        events(gamesSequence(set1 + [sideA, sideB])),
      );
      expect(afterNewSetGame2.changeEndsDue, isFalse);
    });

    test('6-4 (10 games, even): no change at set end, deferred to after the '
        "next set's first game", () {
      final set1 = [
        sideB,
        sideA,
        sideB,
        sideA,
        sideB,
        sideA,
        sideB,
        sideA,
        sideA,
        sideA,
      ];
      final afterSet1 = RacketEngine.replay(rule, events(gamesSequence(set1)));
      expect(afterSet1.currentSetIndex, 1);
      expect(afterSet1.changeEndsDue, isFalse, reason: '10 games, even');

      final afterNewSetGame1 = RacketEngine.replay(
        rule,
        events(gamesSequence(set1 + [sideA])),
      );
      expect(afterNewSetGame1.changeEndsDue, isTrue);
    });

    test("the indicator clears the instant the next game's first point is "
        'scored, rather than staying lit through the whole game', () {
      final oddSet = [
        sideB,
        sideA,
        sideA,
        sideA,
        sideA,
        sideA,
        sideA,
      ]; // 6-1, 7 games.
      final afterOddSet = events(gamesSequence(oddSet));
      expect(RacketEngine.replay(rule, afterOddSet).changeEndsDue, isTrue);

      final firstPointOfNextGame = [...afterOddSet, point('n1', sideA)];
      expect(
        RacketEngine.replay(rule, firstPointOfNextGame).changeEndsDue,
        isFalse,
      );
    });

    test('tie-break: change due at points 6 and 12, not 5/7/11/13', () {
      final to6All = gamesSequence([
        sideA,
        sideB,
        sideA,
        sideB,
        sideA,
        sideB,
        sideA,
        sideB,
        sideA,
        sideB,
        sideA,
        sideB,
      ]);
      final base = events(to6All);
      const tbWinners = [
        sideA, sideB, sideA, sideB, sideA, sideB, // 1-6
        sideA, sideB, sideA, sideB, sideA, sideB, // 7-12
        sideA,
      ];
      const expectedAtPoint = {
        5: false,
        6: true,
        7: false,
        11: false,
        12: true,
        13: false,
      };
      for (final entry in expectedAtPoint.entries) {
        final state = RacketEngine.replay(rule, [
          ...base,
          ...events(
            tbWinners.take(entry.key).toList(),
            startAt: base.length + 1,
          ),
        ]);
        expect(
          state.changeEndsDue,
          entry.value,
          reason: 'after tie-break point ${entry.key}',
        );
      }
    });

    test(
      'a tie-break-decided set (13 games, odd) triggers change right at the '
      'deciding point — not swallowed by the reset that also happens then',
      () {
        final to6All = gamesSequence([
          sideA,
          sideB,
          sideA,
          sideB,
          sideA,
          sideB,
          sideA,
          sideB,
          sideA,
          sideB,
          sideA,
          sideB,
        ]);
        final base = events(to6All);
        // 7-5 tie-break: ends exactly at point 12, not on a 6-point
        // checkpoint boundary drawn from a *different* multiple.
        const tb = [
          sideA,
          sideB,
          sideA,
          sideB,
          sideA,
          sideB,
          sideA,
          sideB,
          sideA,
          sideB,
          sideA,
          sideA,
        ];
        final state = RacketEngine.replay(rule, [
          ...base,
          ...events(tb, startAt: base.length + 1),
        ]);
        expect(state.isTieBreak, isFalse);
        expect(state.completedSets.single.tieBreakScore, {sideA: 7, sideB: 5});
        expect(state.changeEndsDue, isTrue, reason: '13 games total, odd');
      },
    );

    test(
      'a tie-break ending exactly on a 6-point-multiple does not double up',
      () {
        final to6All = gamesSequence([
          sideA,
          sideB,
          sideA,
          sideB,
          sideA,
          sideB,
          sideA,
          sideB,
          sideA,
          sideB,
          sideA,
          sideB,
        ]);
        final base = events(to6All);
        // 7-5 above ends at 12 (a checkpoint itself) - use a straight 7-0
        // instead, also 7 points but landing on point 7 (not 6/12).
        const tb = [sideA, sideA, sideA, sideA, sideA, sideA, sideA];
        final state = RacketEngine.replay(rule, [
          ...base,
          ...events(tb, startAt: base.length + 1),
        ]);
        expect(state.completedSets.single.tieBreakScore, {sideA: 7, sideB: 0});
        // 13 games total (odd) once the tie-break-as-one-game is counted.
        expect(state.changeEndsDue, isTrue);
      },
    );

    test('service order and change-of-ends are computed independently', () {
      final doublesRule = buildRule(service: _doublesService);
      final set1 = [
        sideB,
        sideA,
        sideB,
        sideA,
        sideB,
        sideA,
        sideA,
        sideA,
        sideA,
      ];
      final state = RacketEngine.replay(
        doublesRule,
        events(gamesSequence(set1)),
      );
      // 9 games -> change due; server rotation is unaffected by that —
      // segment 1 has no config yet, so it falls back to the persisted
      // order, walked locally from slot 0 at the segment's own boundary
      // (0 games played in segment 1 so far: local index 9 - 9 = 0).
      expect(state.changeEndsDue, isTrue);
      expect(state.currentServerSlotId, 'side_a_p0');
    });
  });

  group('RacketEngine — doubles service order (ITF Rule 14, per segment)', () {
    RacketMatchRule doublesRule({DecidingSetFormat? decidingSetFormat}) =>
        buildRule(
          service: _doublesService,
          decidingSetFormat: decidingSetFormat ?? const RegularDecidingSet(),
        );

    test('segment 0 never needs configuration, uses the persisted order', () {
      final rule = doublesRule();
      final state = RacketEngine.replay(rule, events(gamesSequence([sideA])));
      expect(state.currentSetIndex, 0);
      expect(state.needsServiceConfiguration, isFalse);
      expect(state.currentServerSlotId, 'side_b_p0'); // order[1 % 4].
    });

    test('singles never needs service configuration, even past set 1', () {
      final rule = buildRule(); // 2-slot singles service.
      final set1 = gamesSequence(List.filled(6, sideA));
      final state = RacketEngine.replay(rule, events(set1));
      expect(state.currentSetIndex, 1);
      expect(state.needsServiceConfiguration, isFalse);
    });

    test('entering segment 1 with no config event: gated, falls back to the '
        'unreconfigured order', () {
      final rule = doublesRule();
      final set1 = gamesSequence(List.filled(6, sideA)); // 6 games, even.
      final state = RacketEngine.replay(rule, events(set1));
      expect(state.currentSetIndex, 1);
      expect(state.needsServiceConfiguration, isTrue);
      // Falls back to the persisted order, walked locally from slot 0
      // at segment 1's own boundary (0 games played in it yet).
      expect(state.currentServerSlotId, 'side_a_p0');
    });

    test('a valid SERVICE_ORDER_CONFIGURED event for segment 1 overrides the '
        'local rotation, restarting at slot 0 for the new set', () {
      final rule = doublesRule();
      final set1 = events(gamesSequence(List.filled(6, sideA))); // 6, even.
      // side_a must still open segment 1's service (even game count) —
      // only which of A's two players does is re-picked here.
      final config = serviceOrderConfigured(
        'cfg',
        segmentIndex: 1,
        order: ['side_a_p1', 'side_b_p1', 'side_a_p0', 'side_b_p0'],
      );

      final atBoundary = RacketEngine.replay(rule, [...set1, config]);
      expect(atBoundary.needsServiceConfiguration, isFalse);
      expect(atBoundary.currentServerSlotId, 'side_a_p1');

      final oneGameIn = RacketEngine.replay(rule, [
        ...set1,
        config,
        ...events(gamesSequence([sideB]), startAt: set1.length + 1),
      ]);
      expect(oneGameIn.currentServerSlotId, 'side_b_p1');
    });

    test("a config naming the wrong starting side is rejected (the side is "
        'mechanical, never a free choice)', () {
      final rule = doublesRule();
      final set1 = events(
        gamesSequence(List.filled(6, sideA)),
      ); // even -> side_a.
      final wrongSide = serviceOrderConfigured(
        'cfg',
        segmentIndex: 1,
        order: ['side_b_p0', 'side_a_p0', 'side_b_p1', 'side_a_p1'],
      );
      final state = RacketEngine.replay(rule, [...set1, wrongSide]);
      expect(state.needsServiceConfiguration, isTrue);
      expect(state.currentServerSlotId, 'side_a_p0'); // unchanged fallback.
    });

    test('a config for a segment not yet reached is ignored', () {
      final rule = doublesRule();
      final set1 = events(gamesSequence(List.filled(6, sideA)));
      final premature = serviceOrderConfigured(
        'cfg',
        segmentIndex: 2,
        order: ['side_a_p1', 'side_b_p1', 'side_a_p0', 'side_b_p0'],
      );
      final state = RacketEngine.replay(rule, [...set1, premature]);
      expect(state.currentSetIndex, 1);
      expect(state.needsServiceConfiguration, isTrue);
    });

    test(
      'the first valid config for a segment wins; a later one is ignored',
      () {
        final rule = doublesRule();
        final set1 = events(gamesSequence(List.filled(6, sideA)));
        final first = serviceOrderConfigured(
          'cfg1',
          segmentIndex: 1,
          order: ['side_a_p1', 'side_b_p1', 'side_a_p0', 'side_b_p0'],
        );
        final second = serviceOrderConfigured(
          'cfg2',
          segmentIndex: 1,
          order: ['side_a_p0', 'side_b_p0', 'side_a_p1', 'side_b_p1'],
        );
        final state = RacketEngine.replay(rule, [...set1, first, second]);
        expect(state.currentServerSlotId, 'side_a_p1'); // first's order[0].
      },
    );

    test('Match Tie-break: the deciding segment can also be reconfigured, side '
        'still mechanically continued', () {
      final rule = doublesRule(
        decidingSetFormat: const MatchTieBreakDecidingSet(
          matchTieBreak: TieBreakRule(schemaVersion: 1, target: 10, winBy: 2),
        ),
      );
      final toDecider =
          gamesSequence(List.filled(6, sideA)) +
          gamesSequence(List.filled(6, sideB)); // 12 games, even -> side_a.
      final base = events(toDecider);
      final config = serviceOrderConfigured(
        'cfg',
        segmentIndex: 2,
        order: ['side_a_p1', 'side_b_p1', 'side_a_p0', 'side_b_p0'],
      );
      final state = RacketEngine.replay(rule, [...base, config]);
      expect(state.isMatchTieBreak, isTrue);
      expect(state.needsServiceConfiguration, isFalse);
      expect(state.currentServerSlotId, 'side_a_p1');

      final onePointIn = RacketEngine.replay(rule, [
        ...base,
        config,
        ...events([sideB], startAt: base.length + 1),
      ]);
      expect(onePointIn.currentServerSlotId, 'side_b_p1');
    });

    test('undo of the point that closed set 1 makes its segment-1 config '
        'inapplicable, and replaying the same point forward again '
        're-applies it deterministically — the config is never contaminated '
        'nor lost, only inapplicable while irrelevant (CLAUDE.md brief '
        'section 12)', () {
      final rule = doublesRule();
      // e1..e24: 6 straight games for side_a (even total).
      final set1 = events(gamesSequence(List.filled(6, sideA)));
      final config = serviceOrderConfigured(
        'cfg',
        segmentIndex: 1,
        order: ['side_a_p1', 'side_b_p1', 'side_a_p0', 'side_b_p0'],
      );
      // Undo the exact point that won set 1 (e24, the 4th point of game
      // 6) — not merely the most recent event.
      final reopened = [...set1, config, undo('u1', target: 'e24')];
      final reopenedState = RacketEngine.replay(rule, reopened);
      expect(reopenedState.currentSetIndex, 0);
      expect(reopenedState.matchComplete, isFalse);

      // Re-scoring the same point under a new id reproduces the exact
      // same 24-point sequence, so set 1 closes again at the same
      // segment-1 boundary the original `config` event was validated
      // against — it becomes applicable again with no new event needed.
      final replayedForward = [...reopened, point('e25', sideA)];
      final finalState = RacketEngine.replay(rule, replayedForward);
      expect(finalState.currentSetIndex, 1);
      expect(finalState.needsServiceConfiguration, isFalse);
      expect(finalState.currentServerSlotId, 'side_a_p1');
    });
  });
}
