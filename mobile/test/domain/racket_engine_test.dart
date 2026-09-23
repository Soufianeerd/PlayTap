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
/// side ids, auto-incrementing ids.
List<RacketEngineEvent> events(List<String> sides) => [
  for (var i = 0; i < sides.length; i++) point('e${i + 1}', sides[i]),
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
}
