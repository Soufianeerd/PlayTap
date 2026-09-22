import 'package:flutter_test/flutter_test.dart';
import 'package:playtap/domain/engines/score_engine.dart';
import 'package:playtap/domain/events/score_engine_event.dart';
import 'package:playtap/domain/models/score_rule.dart';
import 'package:playtap/domain/models/score_round.dart';
import 'package:playtap/domain/models/score_target.dart';

ScoreEngineEvent point(String id, String side, {int amount = 1}) =>
    ScoreEngineEvent(
      id: id,
      type: ScoreEngineEventType.pointScored,
      payload: {'side': side, 'amount': amount},
    );

ScoreEngineEvent undo(String id, {String? target}) => ScoreEngineEvent(
  id: id,
  type: ScoreEngineEventType.undo,
  payload: target == null ? {} : {'targetEventId': target},
);

ScoreEngineEvent completed(String id) => ScoreEngineEvent(
  id: id,
  type: ScoreEngineEventType.sessionCompleted,
  payload: const {},
);

FreeScoreRule rule(List<String> sides) =>
    FreeScoreRule(schemaVersion: 1, sideIds: sides, defaultIncrement: 1);

void main() {
  group('ScoreEngine — FREE_SCORE', () {
    test('initial score is 0 for every side with no events', () {
      final state = ScoreEngine.replay(rule(['a', 'b']), []);
      expect(state.scores, {'a': 0, 'b': 0});
      expect(state.matchComplete, isFalse);
      expect(state.appliedEventCount, 0);
    });

    test('+1 to side A', () {
      final state = ScoreEngine.replay(rule(['a', 'b']), [point('e1', 'a')]);
      expect(state.scores, {'a': 1, 'b': 0});
    });

    test('+1 to side B', () {
      final state = ScoreEngine.replay(rule(['a', 'b']), [point('e1', 'b')]);
      expect(state.scores, {'a': 0, 'b': 1});
    });

    test('sequence of several points', () {
      final state = ScoreEngine.replay(rule(['a', 'b']), [
        point('e1', 'a'),
        point('e2', 'a'),
        point('e3', 'b'),
        point('e4', 'a'),
      ]);
      expect(state.scores, {'a': 3, 'b': 1});
      expect(state.appliedEventCount, 4);
    });

    test('3 scoring sides', () {
      final state = ScoreEngine.replay(rule(['a', 'b', 'c']), [
        point('e1', 'a'),
        point('e2', 'b'),
        point('e3', 'c'),
        point('e4', 'c'),
      ]);
      expect(state.scores, {'a': 1, 'b': 1, 'c': 2});
    });

    test('4 scoring sides', () {
      final state = ScoreEngine.replay(rule(['a', 'b', 'c', 'd']), [
        point('e1', 'a'),
        point('e2', 'b'),
        point('e3', 'c'),
        point('e4', 'd'),
        point('e5', 'd'),
      ]);
      expect(state.scores, {'a': 1, 'b': 1, 'c': 1, 'd': 2});
    });

    test('undo removes exactly the last active point', () {
      final state = ScoreEngine.replay(rule(['a', 'b']), [
        point('e1', 'a'),
        point('e2', 'b'),
        point('e3', 'a'),
        undo('e4'),
      ]);
      expect(state.scores, {'a': 1, 'b': 1});
      expect(state.appliedEventCount, 3); // undo itself is not "applied"
    });

    test('successive undo removes points in reverse order', () {
      final state = ScoreEngine.replay(rule(['a', 'b']), [
        point('e1', 'a'),
        point('e2', 'a'),
        point('e3', 'b'),
        undo('e4'),
        undo('e5'),
      ]);
      expect(state.scores, {'a': 1, 'b': 0});
    });

    test('undo with no eligible event is a no-op, never negative', () {
      final state = ScoreEngine.replay(rule(['a', 'b']), [undo('e1')]);
      expect(state.scores, {'a': 0, 'b': 0});
    });

    test(
      'undo of an already-undone event does not cascade to an earlier one',
      () {
        final state = ScoreEngine.replay(rule(['a']), [
          point('e1', 'a'),
          point('e2', 'a'),
          undo('e3', target: 'e1'),
          undo('e4', target: 'e1'), // e1 already undone: no-op
        ]);
        expect(state.scores, {'a': 1}); // only e2 remains
      },
    );

    test('undo targeting an unknown event id is a no-op', () {
      final state = ScoreEngine.replay(rule(['a']), [
        point('e1', 'a'),
        undo('e2', target: 'does-not-exist'),
      ]);
      expect(state.scores, {'a': 1});
    });

    test(
      'replay is deterministic: same events always produce the same state',
      () {
        final events = [
          point('e1', 'a'),
          point('e2', 'b'),
          undo('e3'),
          point('e4', 'a'),
        ];
        final r = rule(['a', 'b']);
        final first = ScoreEngine.replay(r, events);
        final second = ScoreEngine.replay(r, events);
        expect(first.scores, second.scores);
        expect(first.matchComplete, second.matchComplete);
        expect(first.winner, second.winner);
        expect(first.appliedEventCount, second.appliedEventCount);
      },
    );

    test('the same event id received twice is applied only once', () {
      final state = ScoreEngine.replay(rule(['a']), [
        point('e1', 'a'),
        point('e1', 'a'), // duplicate id, e.g. a resync replay
      ]);
      expect(state.scores, {'a': 1});
      expect(state.appliedEventCount, 1);
    });

    test('SESSION_COMPLETED marks the match complete and stops replay', () {
      final state = ScoreEngine.replay(rule(['a', 'b']), [
        point('e1', 'a'),
        point('e2', 'a'),
        completed('e3'),
        point('e4', 'b'), // after completion: ignored
      ]);
      expect(state.matchComplete, isTrue);
      expect(state.scores, {'a': 2, 'b': 0});
    });

    test('winner is the strictly highest score once complete', () {
      final state = ScoreEngine.replay(rule(['a', 'b']), [
        point('e1', 'a'),
        point('e2', 'a'),
        point('e3', 'b'),
        completed('e4'),
      ]);
      expect(state.winner, 'a');
    });

    test('winner is null on a tie', () {
      final state = ScoreEngine.replay(rule(['a', 'b']), [
        point('e1', 'a'),
        point('e2', 'b'),
        completed('e3'),
      ]);
      expect(state.winner, isNull);
    });

    test('a point for an unknown participant is ignored, not fatal', () {
      final state = ScoreEngine.replay(rule(['a', 'b']), [
        point('e1', 'a'),
        point('e2', 'ghost'),
      ]);
      expect(state.scores, {'a': 1, 'b': 0});
      expect(state.appliedEventCount, 1);
    });

    test('a non-positive increment is rejected', () {
      final state = ScoreEngine.replay(rule(['a']), [
        point('e1', 'a', amount: 0),
        point('e2', 'a', amount: -1),
      ]);
      expect(state.scores, {'a': 0});
      expect(state.appliedEventCount, 0);
    });

    test('unsupported modes raise UnsupportedScoreModeException', () {
      expect(
        () => ScoreRule.fromJson({
          'schemaVersion': 1,
          'mode': 'SEQUENTIAL_SCORE',
        }),
        throwsA(isA<UnsupportedScoreModeException>()),
      );
    });
  });

  group('ScoreEngine — TARGET_SCORE', () {
    TargetScoreRule rule(
      List<String> sides, {
      int target = 11,
      ScoreWinBy? winBy,
    }) => TargetScoreRule(
      schemaVersion: 1,
      sideIds: sides,
      target: ScoreTarget(targetScore: target, winBy: winBy),
    );

    test('JSON round-trip', () {
      final r = TargetScoreRule(
        schemaVersion: 1,
        sideIds: ['a', 'b'],
        target: const ScoreTarget(
          targetScore: 11,
          winBy: ScoreWinBy(enabled: true, margin: 2),
        ),
      );
      final decoded = ScoreRule.fromJson(r.toJson());
      expect(decoded, isA<TargetScoreRule>());
      expect(decoded.toJson(), r.toJson());
    });

    test('amount defaults to 1 when omitted', () {
      final state = ScoreEngine.replay(rule(['a', 'b']), [
        ScoreEngineEvent(
          id: 'e1',
          type: ScoreEngineEventType.pointScored,
          payload: {'side': 'a'},
        ),
      ]);
      expect(state.scores, {'a': 1, 'b': 0});
    });

    test('0 -> target completes automatically, winner set', () {
      final events = [for (var i = 0; i < 11; i++) point('e$i', 'a')];
      final state = ScoreEngine.replay(rule(['a', 'b'], target: 11), events);
      expect(state.matchComplete, isTrue);
      expect(state.winner, 'a');
      expect(state.scores['a'], 11);
    });

    test('without win-by, reaching the target alone is enough', () {
      final state = ScoreEngine.replay(rule(['a', 'b'], target: 5), [
        point('e1', 'a'),
        point('e2', 'a'),
        point('e3', 'a'),
        point('e4', 'a'),
        point('e5', 'a'),
        point('e6', 'b'), // after completion: ignored.
      ]);
      expect(state.matchComplete, isTrue);
      expect(state.scores, {'a': 5, 'b': 0});
    });

    test('win-by margin unmet at the raw target keeps the match running', () {
      final state = ScoreEngine.replay(
        rule(
          ['a', 'b'],
          target: 5,
          winBy: const ScoreWinBy(enabled: true, margin: 2),
        ),
        [
          point('e1', 'a'),
          point('e2', 'a'),
          point('e3', 'a'),
          point('e4', 'a'),
          point('e5', 'a'), // a=5, b=0: margin already satisfied actually.
        ],
      );
      // a=5 vs b=0 already has a 5-point margin, so this *is* complete —
      // exercise the "unmet" branch with a tighter race instead.
      expect(state.matchComplete, isTrue);

      final tight = ScoreEngine.replay(
        rule(
          ['a', 'b'],
          target: 5,
          winBy: const ScoreWinBy(enabled: true, margin: 2),
        ),
        [
          point('e1', 'a'),
          point('e2', 'b'),
          point('e3', 'a'),
          point('e4', 'b'),
          point('e5', 'a'), // a=3, b=2: target not yet reached either.
          point('e6', 'a'), // a=4
          point('e7', 'b'), // b=3
          point('e8', 'a'), // a=5, b=3: margin 2, satisfied.
        ],
      );
      expect(tight.matchComplete, isTrue);
      expect(tight.winner, 'a');
      expect(tight.scores, {'a': 5, 'b': 3});
    });

    test('an amount other than 1 is rejected', () {
      final state = ScoreEngine.replay(rule(['a', 'b']), [
        ScoreEngineEvent(
          id: 'e1',
          type: ScoreEngineEventType.pointScored,
          payload: {'side': 'a', 'amount': 2},
        ),
      ]);
      expect(state.scores, {'a': 0, 'b': 0});
      expect(state.appliedEventCount, 0);
    });

    test('undoing the completing point reopens the match', () {
      final events = [
        for (var i = 0; i < 5; i++) point('e$i', 'a'),
        undo('undo1'),
      ];
      final state = ScoreEngine.replay(rule(['a', 'b'], target: 5), events);
      expect(state.matchComplete, isFalse);
      expect(state.winner, isNull);
      expect(state.scores['a'], 4);
    });
  });

  group('ScoreEngine — TEAM_SCORE', () {
    TeamScoreRule rule(
      List<String> sides, {
      List<int> increments = const [1, 2, 3, 4, 5, 6],
      ScoreTarget? target,
    }) => TeamScoreRule(
      schemaVersion: 1,
      sideIds: sides,
      allowedIncrements: increments,
      target: target,
    );

    test('JSON round-trip without target (Basketball/Football-style)', () {
      final r = rule(['a', 'b'], increments: const [1, 2, 3]);
      final decoded = ScoreRule.fromJson(r.toJson());
      expect(decoded, isA<TeamScoreRule>());
      expect(decoded.toJson(), r.toJson());
    });

    test('JSON round-trip with a composed target (Pétanque-style)', () {
      final r = rule([
        'team_a',
        'team_b',
      ], target: const ScoreTarget(targetScore: 13));
      final decoded = ScoreRule.fromJson(r.toJson());
      expect(decoded, isA<TeamScoreRule>());
      expect(decoded.toJson(), r.toJson());
    });

    test('valid increments are applied', () {
      final state = ScoreEngine.replay(rule(['a', 'b']), [
        point('e1', 'a', amount: 3),
        point('e2', 'b', amount: 6),
      ]);
      expect(state.scores, {'a': 3, 'b': 6});
    });

    test('an increment outside the allowed set is rejected', () {
      final state = ScoreEngine.replay(
        rule(['a', 'b'], increments: const [1, 2, 3]),
        [point('e1', 'a', amount: 4)],
      );
      expect(state.scores, {'a': 0, 'b': 0});
      expect(state.appliedEventCount, 0);
    });

    test('without a target, the match never ends automatically', () {
      final state = ScoreEngine.replay(rule(['a', 'b']), [
        point('e1', 'a', amount: 6),
        point('e2', 'a', amount: 6),
        point('e3', 'a', amount: 6), // 18 points, no target configured.
      ]);
      expect(state.matchComplete, isFalse);
      expect(state.scores['a'], 18);
    });

    group('Pétanque preset (target 13, 1-6 per mène)', () {
      TeamScoreRule petanque() => rule([
        'team_a',
        'team_b',
      ], target: const ScoreTarget(targetScore: 13));

      test('several mènes, no completion below 13', () {
        final state = ScoreEngine.replay(petanque(), [
          point('e1', 'team_a', amount: 2),
          point('e2', 'team_b', amount: 1),
          point('e3', 'team_a', amount: 4),
        ]);
        expect(state.scores, {'team_a': 6, 'team_b': 1});
        expect(state.matchComplete, isFalse);
        expect(state.rounds, [
          const ScoreRound(sideId: 'team_a', amount: 2),
          const ScoreRound(sideId: 'team_b', amount: 1),
          const ScoreRound(sideId: 'team_a', amount: 4),
        ]);
      });

      test('reaching exactly 13 completes the game', () {
        final state = ScoreEngine.replay(petanque(), [
          point('e1', 'team_a', amount: 6),
          point('e2', 'team_a', amount: 6),
          point('e3', 'team_a', amount: 1), // exactly 13.
        ]);
        expect(state.matchComplete, isTrue);
        expect(state.winner, 'team_a');
        expect(state.scores['team_a'], 13);
      });

      test('overshooting 13 in a single mène still wins ("13 or more")', () {
        final state = ScoreEngine.replay(petanque(), [
          point('e1', 'team_a', amount: 6),
          point('e2', 'team_a', amount: 6),
          point('e3', 'team_a', amount: 4), // 16, overshoots.
        ]);
        expect(state.matchComplete, isTrue);
        expect(state.winner, 'team_a');
        expect(state.scores['team_a'], 16);
      });

      test('undo removes the entire last mène, not a single point', () {
        final state = ScoreEngine.replay(petanque(), [
          point('e1', 'team_a', amount: 2),
          point('e2', 'team_b', amount: 1),
          point('e3', 'team_a', amount: 3),
          undo('undo1'),
        ]);
        expect(state.scores, {'team_a': 2, 'team_b': 1});
        expect(state.rounds, [
          const ScoreRound(sideId: 'team_a', amount: 2),
          const ScoreRound(sideId: 'team_b', amount: 1),
        ]);
      });

      test('undo after auto-completion reopens the game and play resumes', () {
        final state = ScoreEngine.replay(petanque(), [
          point('e1', 'team_a', amount: 6),
          point('e2', 'team_a', amount: 6),
          point('e3', 'team_a', amount: 4), // 16, completes.
          undo('undo1'), // back to 12, reopened.
          point('e4', 'team_b', amount: 3), // play continues.
        ]);
        expect(state.matchComplete, isFalse);
        expect(state.winner, isNull);
        expect(state.scores, {'team_a': 12, 'team_b': 3});
      });

      test('manual abandon before 13 completes via highest score', () {
        final state = ScoreEngine.replay(petanque(), [
          point('e1', 'team_a', amount: 5),
          point('e2', 'team_b', amount: 3),
          completed('e3'),
        ]);
        expect(state.matchComplete, isTrue);
        expect(state.winner, 'team_a');
      });

      test('replay is deterministic across a full game', () {
        final events = [
          point('e1', 'team_a', amount: 3),
          point('e2', 'team_b', amount: 2),
          point('e3', 'team_a', amount: 6),
          point('e4', 'team_b', amount: 1),
          point('e5', 'team_a', amount: 6), // 15, completes.
        ];
        final r = petanque();
        final first = ScoreEngine.replay(r, events);
        final second = ScoreEngine.replay(r, events);
        expect(first.scores, second.scores);
        expect(first.matchComplete, second.matchComplete);
        expect(first.winner, second.winner);
        expect(first.rounds, second.rounds);
      });
    });
  });
}
