import 'package:flutter_test/flutter_test.dart';
import 'package:playtap/domain/engines/score_engine.dart';
import 'package:playtap/domain/events/score_engine_event.dart';
import 'package:playtap/domain/models/score_rule.dart';

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
          'mode': 'TARGET_SCORE',
          'targetScore': 11,
        }),
        throwsA(isA<UnsupportedScoreModeException>()),
      );
    });
  });
}
