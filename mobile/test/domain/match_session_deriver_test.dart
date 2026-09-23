import 'package:flutter_test/flutter_test.dart';
import 'package:playtap/domain/engines/match_session_deriver.dart';
import 'package:playtap/domain/events/session_event.dart';
import 'package:playtap/domain/models/match_clock_kind.dart';
import 'package:playtap/domain/models/match_end_rule.dart';
import 'package:playtap/domain/models/match_rule.dart';
import 'package:playtap/domain/models/match_state.dart';
import 'package:playtap/domain/models/origin_device.dart';
import 'package:playtap/domain/models/overtime_rule.dart';
import 'package:playtap/domain/models/period_rule.dart';
import 'package:playtap/domain/models/score_rule.dart';
import 'package:playtap/domain/models/scoring_side.dart';
import 'package:playtap/domain/models/session_status.dart';
import 'package:playtap/domain/models/shootout_rule.dart';

final _basketballRule = MatchRule(
  schemaVersion: 1,
  rulesetId: 'test.basketball',
  scoreRule: const TeamScoreRule(
    schemaVersion: 1,
    sideIds: ['home', 'away'],
    allowedIncrements: [1, 2, 3],
  ),
  clock: MatchClockKind.stoppedClock,
  periods: List.generate(4, (i) => PeriodRule(index: i, durationMs: 600000)),
  overtime: const OvertimeRule(durationMs: 300000, maxCount: null),
  matchEnd: const MatchEndRule(drawAllowed: false),
);

final _sides = [
  const ScoringSide(id: 'home', name: 'Home'),
  const ScoringSide(id: 'away', name: 'Away'),
];

SessionEvent event({
  required String id,
  required SessionEventType type,
  required Map<String, dynamic> payload,
  required DateTime timestamp,
  int originSequence = 0,
}) => SessionEvent(
  id: id,
  sessionId: 's1',
  type: type,
  payload: payload,
  timestamp: timestamp,
  originDevice: OriginDevice.phone,
  originSequence: originSequence,
);

void main() {
  group('deriveMatchSessionSnapshot — composing ScoreEngine + MatchEngine', () {
    test(
      'reads both scoreRule and matchRule from SESSION_STARTED and composes both engines',
      () {
        final events = [
          event(
            id: 'e0',
            type: SessionEventType.sessionStarted,
            payload: {
              'matchRule': _basketballRule.toJson(),
              'sides': _sides.map((s) => s.toJson()).toList(),
            },
            timestamp: DateTime.utc(2026, 1, 1),
          ),
          event(
            id: 'e1',
            type: SessionEventType.periodStarted,
            payload: const {'periodIndex': 0, 'kind': 'REGULATION'},
            timestamp: DateTime.utc(2026, 1, 1),
          ),
          event(
            id: 'e2',
            type: SessionEventType.timerStarted,
            payload: const {},
            timestamp: DateTime.utc(2026, 1, 1),
          ),
          event(
            id: 'e3',
            type: SessionEventType.pointScored,
            payload: const {'side': 'home', 'amount': 3},
            timestamp: DateTime.utc(2026, 1, 1, 0, 0, 5),
          ),
        ];

        final snapshot = deriveMatchSessionSnapshot(
          status: SessionStatus.active,
          startedAt: DateTime.utc(2026, 1, 1),
          endedAt: null,
          events: events,
          nowMs: DateTime.utc(2026, 1, 1, 0, 0, 10).millisecondsSinceEpoch,
        );

        expect(snapshot.scoreState.scores, {'home': 3, 'away': 0});
        expect(snapshot.matchState.periodIndex, 0);
        expect(snapshot.matchState.clock.elapsedMs, 10000);
        expect(snapshot.shootoutState, isNull); // no shootout started.
      },
    );

    test(
      'a SHOOTOUT_STARTED event triggers ShootoutEngine composition, kept separate from score',
      () {
        final shootoutRule = MatchRule(
          schemaVersion: 1,
          rulesetId: 'test.football',
          scoreRule: const TeamScoreRule(
            schemaVersion: 1,
            sideIds: ['home', 'away'],
            allowedIncrements: [1],
          ),
          clock: MatchClockKind.runningClock,
          periods: List.generate(
            2,
            (i) => PeriodRule(index: i, durationMs: 2700000),
          ),
          shootout: const ShootoutRule(kicksPerRound: 5, suddenDeath: true),
          matchEnd: const MatchEndRule(drawAllowed: false),
        );

        final events = [
          event(
            id: 'e0',
            type: SessionEventType.sessionStarted,
            payload: {
              'matchRule': shootoutRule.toJson(),
              'sides': _sides.map((s) => s.toJson()).toList(),
            },
            timestamp: DateTime.utc(2026, 1, 1),
          ),
          event(
            id: 'e1',
            type: SessionEventType.pointScored,
            payload: const {'side': 'home', 'amount': 1},
            timestamp: DateTime.utc(2026, 1, 1),
          ),
          event(
            id: 'e2',
            type: SessionEventType.shootoutStarted,
            payload: const {},
            timestamp: DateTime.utc(2026, 1, 1),
          ),
          event(
            id: 'e3',
            type: SessionEventType.shootoutAttempt,
            payload: const {'side': 'home', 'scored': true},
            timestamp: DateTime.utc(2026, 1, 1),
          ),
        ];

        final snapshot = deriveMatchSessionSnapshot(
          status: SessionStatus.active,
          startedAt: DateTime.utc(2026, 1, 1),
          endedAt: null,
          events: events,
          nowMs: DateTime.utc(2026, 1, 1).millisecondsSinceEpoch,
        );

        expect(snapshot.scoreState.scores, {
          'home': 1,
          'away': 0,
        }); // match score unaffected.
        expect(snapshot.shootoutState, isNotNull);
        expect(snapshot.shootoutState!.scores, {
          'home': 1,
          'away': 0,
        }); // separate tally.
        expect(snapshot.matchState.phase, MatchPhase.shootoutInProgress);
      },
    );

    test(
      'throws a clear error when SESSION_STARTED is missing — never silently empty',
      () {
        expect(
          () => deriveMatchSessionSnapshot(
            status: SessionStatus.active,
            startedAt: DateTime.utc(2026, 1, 1),
            endedAt: null,
            events: const [],
            nowMs: 0,
          ),
          throwsStateError,
        );
      },
    );
  });

  group('resolveMatchUndoTarget', () {
    test('returns null when nothing undoable has happened yet', () {
      final events = [
        event(
          id: 'e0',
          type: SessionEventType.sessionStarted,
          payload: const {},
          timestamp: DateTime.utc(2026, 1, 1),
        ),
        event(
          id: 'e1',
          type: SessionEventType.periodStarted,
          payload: const {},
          timestamp: DateTime.utc(2026, 1, 1),
        ),
        event(
          id: 'e2',
          type: SessionEventType.timerStarted,
          payload: const {},
          timestamp: DateTime.utc(2026, 1, 1),
        ),
      ];
      expect(resolveMatchUndoTarget(events), isNull);
    });

    test(
      'targets the most recent point, skipping trailing lifecycle events',
      () {
        final events = [
          event(
            id: 'e0',
            type: SessionEventType.sessionStarted,
            payload: const {},
            timestamp: DateTime.utc(2026, 1, 1),
          ),
          event(
            id: 'e1',
            type: SessionEventType.pointScored,
            payload: const {},
            timestamp: DateTime.utc(2026, 1, 1),
          ),
          event(
            id: 'e2',
            type: SessionEventType.timerPaused,
            payload: const {},
            timestamp: DateTime.utc(2026, 1, 1),
          ),
        ];
        expect(resolveMatchUndoTarget(events), 'e1');
      },
    );

    test(
      'a period transition (PERIOD_ENDED) is itself a valid undo target',
      () {
        final events = [
          event(
            id: 'e0',
            type: SessionEventType.sessionStarted,
            payload: const {},
            timestamp: DateTime.utc(2026, 1, 1),
          ),
          event(
            id: 'e1',
            type: SessionEventType.periodEnded,
            payload: const {},
            timestamp: DateTime.utc(2026, 1, 1),
          ),
        ];
        expect(resolveMatchUndoTarget(events), 'e1');
      },
    );

    test(
      'an already-undone event is skipped, falling back to the one before it',
      () {
        final events = [
          event(
            id: 'e0',
            type: SessionEventType.sessionStarted,
            payload: const {},
            timestamp: DateTime.utc(2026, 1, 1),
          ),
          event(
            id: 'e1',
            type: SessionEventType.pointScored,
            payload: const {},
            timestamp: DateTime.utc(2026, 1, 1),
          ),
          event(
            id: 'e2',
            type: SessionEventType.pointScored,
            payload: const {},
            timestamp: DateTime.utc(2026, 1, 1),
          ),
          event(
            id: 'e3',
            type: SessionEventType.undo,
            payload: const {'targetEventId': 'e2'},
            timestamp: DateTime.utc(2026, 1, 1),
          ),
        ];
        expect(resolveMatchUndoTarget(events), 'e1');
      },
    );
  });
}
