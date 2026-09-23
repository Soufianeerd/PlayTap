import 'package:flutter_test/flutter_test.dart';
import 'package:playtap/domain/engines/shootout_engine.dart';
import 'package:playtap/domain/events/shootout_engine_event.dart';
import 'package:playtap/domain/models/shootout_rule.dart';

const _rule = ShootoutRule(kicksPerRound: 5, suddenDeath: true);
const _sides = ['a', 'b'];

ShootoutEngineEvent attempt(String id, String side, {required bool scored}) =>
    ShootoutEngineEvent(
      id: id,
      type: ShootoutEngineEventType.shootoutAttempt,
      payload: {'side': side, 'scored': scored},
    );

ShootoutEngineEvent undo(String id, {required String targetEventId}) =>
    ShootoutEngineEvent(
      id: id,
      type: ShootoutEngineEventType.undo,
      payload: {'targetEventId': targetEventId},
    );

void main() {
  group('ShootoutEngine — basic alternating procedure', () {
    test('no attempts: nextKicker is side A, not decided', () {
      final state = ShootoutEngine.replay(_rule, _sides, []);
      expect(state.nextKicker, 'a');
      expect(state.decided, isFalse);
    });

    test('alternates kickers strictly A, B, A, B...', () {
      final state = ShootoutEngine.replay(_rule, _sides, [
        attempt('e1', 'a', scored: true),
      ]);
      expect(state.nextKicker, 'b');
    });

    test(
      'an out-of-order kick (same side twice in a row) is ignored, not fatal',
      () {
        final state = ShootoutEngine.replay(_rule, _sides, [
          attempt('e1', 'a', scored: true),
          attempt('e2', 'a', scored: true), // A again — invalid, B's turn.
        ]);
        expect(state.scores['a'], 1); // only the first attempt counted.
        expect(state.nextKicker, 'b');
      },
    );

    test(
      'a full 5-5 tie after the initial round is not decided, sudden death continues',
      () {
        final events = <ShootoutEngineEvent>[];
        for (var i = 0; i < 5; i++) {
          events.add(attempt('a$i', 'a', scored: true));
          events.add(attempt('b$i', 'b', scored: true));
        }
        final state = ShootoutEngine.replay(_rule, _sides, events);
        expect(state.decided, isFalse);
        expect(state.scores, {'a': 5, 'b': 5});
        expect(
          state.nextKicker,
          'a',
        ); // sudden death round starts with A again.
      },
    );

    test(
      'early termination: decided before all 5 kicks when mathematically unreachable',
      () {
        // A scores its first 3; B misses its first 3. After B's 3rd miss, A
        // leads 3-0 with B only having 2 kicks left (max possible for B is
        // 0+2=2 < 3) — decided immediately, without waiting for kicks 4-5.
        final events = [
          attempt('a0', 'a', scored: true),
          attempt('b0', 'b', scored: false),
          attempt('a1', 'a', scored: true),
          attempt('b1', 'b', scored: false),
          attempt('a2', 'a', scored: true),
          attempt('b2', 'b', scored: false),
        ];
        final state = ShootoutEngine.replay(_rule, _sides, events);
        expect(state.decided, isTrue);
        expect(state.winner, 'a');
        expect(state.attempts.length, 6); // no further kicks accepted.
      },
    );

    test('a kick after the shootout is already decided is ignored', () {
      final events = [
        attempt('a0', 'a', scored: true),
        attempt('b0', 'b', scored: false),
        attempt('a1', 'a', scored: true),
        attempt('b1', 'b', scored: false),
        attempt('a2', 'a', scored: true),
        attempt('b2', 'b', scored: false), // decided here, A wins.
        attempt('a3', 'a', scored: true), // ignored: already decided.
      ];
      final state = ShootoutEngine.replay(_rule, _sides, events);
      expect(state.attempts.length, 6);
      expect(state.scores['a'], 3);
    });

    test(
      'sudden death: decided as soon as both have kicked in a round and scores differ',
      () {
        final events = <ShootoutEngineEvent>[];
        for (var i = 0; i < 5; i++) {
          events.add(attempt('a$i', 'a', scored: true));
          events.add(attempt('b$i', 'b', scored: true));
        }
        // Sudden death round 1: A scores, B misses.
        events.add(attempt('sd_a', 'a', scored: true));
        events.add(attempt('sd_b', 'b', scored: false));
        final state = ShootoutEngine.replay(_rule, _sides, events);
        expect(state.decided, isTrue);
        expect(state.winner, 'a');
      },
    );

    test(
      'sudden death round where only the first kicker has gone is not yet decided',
      () {
        final events = <ShootoutEngineEvent>[];
        for (var i = 0; i < 5; i++) {
          events.add(attempt('a$i', 'a', scored: true));
          events.add(attempt('b$i', 'b', scored: true));
        }
        events.add(attempt('sd_a', 'a', scored: true)); // B hasn't kicked yet.
        final state = ShootoutEngine.replay(_rule, _sides, events);
        expect(state.decided, isFalse);
        expect(state.nextKicker, 'b');
      },
    );

    test(
      'no sudden death configured and level after initial round: no forced winner',
      () {
        const rule = ShootoutRule(kicksPerRound: 5, suddenDeath: false);
        final events = <ShootoutEngineEvent>[];
        for (var i = 0; i < 5; i++) {
          events.add(attempt('a$i', 'a', scored: true));
          events.add(attempt('b$i', 'b', scored: true));
        }
        final state = ShootoutEngine.replay(rule, _sides, events);
        expect(state.decided, isFalse);
        expect(state.winner, isNull);
        expect(state.nextKicker, isNull); // no further kicks expected either.
      },
    );
  });

  group('ShootoutEngine — undo', () {
    test('undoing the decisive attempt reopens the shootout', () {
      final events = [
        attempt('a0', 'a', scored: true),
        attempt('b0', 'b', scored: false),
        attempt('a1', 'a', scored: true),
        attempt('b1', 'b', scored: false),
        attempt('a2', 'a', scored: true),
        attempt('b2', 'b', scored: false), // decided here.
        undo('u1', targetEventId: 'b2'),
      ];
      final state = ShootoutEngine.replay(_rule, _sides, events);
      expect(state.decided, isFalse);
      expect(state.attempts.length, 5);
      expect(state.nextKicker, 'b');
    });

    test(
      'undoing a non-decisive attempt just removes it, replay continues correctly',
      () {
        final events = [
          attempt('a0', 'a', scored: true),
          attempt('b0', 'b', scored: false),
          undo('u1', targetEventId: 'a0'), // undo A's first kick.
        ];
        final state = ShootoutEngine.replay(_rule, _sides, events);
        // b0 targeted A as next kicker's turn originally, but with a0
        // removed, b0 becomes an out-of-order kick (B kicking when A hasn't
        // kicked this round) and is ignored — this is the expected, safe
        // behavior of "filter then forward-replay": undo only ever removes
        // exactly the targeted event, never renumbers surrounding kicks.
        expect(state.attempts, isEmpty);
        expect(state.nextKicker, 'a');
      },
    );
  });

  group('ShootoutEngine — general event sourcing guarantees', () {
    test('replay is deterministic', () {
      final events = [
        attempt('a0', 'a', scored: true),
        attempt('b0', 'b', scored: false),
      ];
      final s1 = ShootoutEngine.replay(_rule, _sides, events);
      final s2 = ShootoutEngine.replay(_rule, _sides, events);
      expect(s1.scores, s2.scores);
      expect(s1.decided, s2.decided);
    });

    test('a duplicate event id is applied only once', () {
      final events = [
        attempt('a0', 'a', scored: true),
        attempt(
          'a0',
          'b',
          scored: true,
        ), // same id, different payload, ignored.
      ];
      final state = ShootoutEngine.replay(_rule, _sides, events);
      expect(state.attempts.length, 1);
      expect(state.scores['b'], 0);
    });

    test('an unknown side in the payload is ignored, not fatal', () {
      final events = [attempt('a0', 'c', scored: true)];
      final state = ShootoutEngine.replay(_rule, _sides, events);
      expect(state.attempts, isEmpty);
    });
  });
}
