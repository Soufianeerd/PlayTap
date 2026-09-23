import 'package:flutter_test/flutter_test.dart';
import 'package:playtap/domain/engines/match_engine.dart';
import 'package:playtap/domain/events/match_engine_event.dart';
import 'package:playtap/domain/models/match_clock_kind.dart';
import 'package:playtap/domain/models/match_clock_state.dart';
import 'package:playtap/domain/models/match_end_rule.dart';
import 'package:playtap/domain/models/match_rule.dart';
import 'package:playtap/domain/models/match_state.dart';
import 'package:playtap/domain/models/overtime_rule.dart';
import 'package:playtap/domain/models/period_rule.dart';
import 'package:playtap/domain/models/score_rule.dart';
import 'package:playtap/domain/models/score_state.dart';
import 'package:playtap/domain/models/shootout_rule.dart';
import 'package:playtap/domain/models/timer_status.dart';

MatchRule stoppedClockRule({
  int periodCount = 4,
  int periodDurationMs = 600000,
  int? overtimeMaxCount = -1, // -1 sentinel: no overtime at all.
  int overtimeDurationMs = 300000,
  bool shootout = false,
  bool drawAllowed = false,
}) => MatchRule(
  schemaVersion: 1,
  rulesetId: 'test.stopped_clock',
  scoreRule: const TeamScoreRule(
    schemaVersion: 1,
    sideIds: ['a', 'b'],
    allowedIncrements: [1, 2, 3],
  ),
  clock: MatchClockKind.stoppedClock,
  periods: List.generate(
    periodCount,
    (i) => PeriodRule(index: i, durationMs: periodDurationMs),
  ),
  overtime: overtimeMaxCount == -1
      ? null
      : OvertimeRule(
          durationMs: overtimeDurationMs,
          maxCount: overtimeMaxCount,
        ),
  shootout: shootout
      ? const ShootoutRule(kicksPerRound: 5, suddenDeath: true)
      : null,
  matchEnd: MatchEndRule(drawAllowed: drawAllowed),
);

MatchRule runningClockRule({
  int periodCount = 2,
  int periodDurationMs = 2700000,
  bool drawAllowed = true,
}) => MatchRule(
  schemaVersion: 1,
  rulesetId: 'test.running_clock',
  scoreRule: const TeamScoreRule(
    schemaVersion: 1,
    sideIds: ['a', 'b'],
    allowedIncrements: [1],
  ),
  clock: MatchClockKind.runningClock,
  periods: List.generate(
    periodCount,
    (i) => PeriodRule(index: i, durationMs: periodDurationMs),
  ),
  matchEnd: MatchEndRule(drawAllowed: drawAllowed),
);

MatchEngineEvent regulationStarted(
  String id,
  int atMs, {
  required int periodIndex,
}) => MatchEngineEvent(
  id: id,
  type: MatchEngineEventType.periodStarted,
  atMs: atMs,
  payload: {'periodIndex': periodIndex, 'kind': 'REGULATION'},
);

MatchEngineEvent overtimeStarted(
  String id,
  int atMs, {
  required int overtimeNumber,
}) => MatchEngineEvent(
  id: id,
  type: MatchEngineEventType.periodStarted,
  atMs: atMs,
  payload: {'kind': 'OVERTIME', 'overtimeNumber': overtimeNumber},
);

MatchEngineEvent timerStarted(String id, int atMs) => MatchEngineEvent(
  id: id,
  type: MatchEngineEventType.timerStarted,
  atMs: atMs,
  payload: const {},
);

MatchEngineEvent periodEnded(String id, int atMs) => MatchEngineEvent(
  id: id,
  type: MatchEngineEventType.periodEnded,
  atMs: atMs,
  payload: const {},
);

MatchEngineEvent timerPaused(String id, int atMs) => MatchEngineEvent(
  id: id,
  type: MatchEngineEventType.timerPaused,
  atMs: atMs,
  payload: const {},
);

MatchEngineEvent timerResumed(String id, int atMs) => MatchEngineEvent(
  id: id,
  type: MatchEngineEventType.timerResumed,
  atMs: atMs,
  payload: const {},
);

MatchEngineEvent timerCompleted(String id, int atMs) => MatchEngineEvent(
  id: id,
  type: MatchEngineEventType.timerCompleted,
  atMs: atMs,
  payload: const {},
);

MatchEngineEvent sessionCompleted(
  String id,
  int atMs, {
  MatchEndReason? reason,
}) => MatchEngineEvent(
  id: id,
  type: MatchEngineEventType.sessionCompleted,
  atMs: atMs,
  payload: reason != null ? {'endReason': reason.toJson()} : const {},
);

MatchEngineEvent undo(String id, int atMs, {required String targetEventId}) =>
    MatchEngineEvent(
      id: id,
      type: MatchEngineEventType.undo,
      atMs: atMs,
      payload: {'targetEventId': targetEventId},
    );

ScoreState scoreState(Map<String, int> scores) => ScoreState(
  scores: scores,
  matchComplete: false,
  winner: null,
  appliedEventCount: scores.values.fold(0, (a, b) => a + b),
);

void main() {
  group('MatchEngine — STOPPED_CLOCK period replay', () {
    test(
      'initial period before any event: paused, remaining = full duration',
      () {
        final state = MatchEngine.replay(stoppedClockRule(), [], nowMs: 0);
        expect(state.clock.status, TimerStatus.paused);
        expect(state.clock.remainingMs, 600000);
        expect(state.periodIndex, 0);
        expect(state.isOvertimePeriod, isFalse);
      },
    );

    test(
      'PERIOD_STARTED + TIMER_STARTED together start the clock counting down',
      () {
        final rule = stoppedClockRule();
        final events = [
          regulationStarted('e1', 0, periodIndex: 0),
          timerStarted('e2', 0),
        ];
        final state = MatchEngine.replay(rule, events, nowMs: 5000);
        expect(state.clock.status, TimerStatus.running);
        expect(state.clock.elapsedMs, 5000);
        expect(state.clock.remainingMs, 595000);
      },
    );

    test(
      'PERIOD_STARTED alone (no TIMER_STARTED yet) leaves the clock paused at 0',
      () {
        final rule = stoppedClockRule();
        final events = [regulationStarted('e1', 0, periodIndex: 2)];
        final state = MatchEngine.replay(rule, events, nowMs: 5000);
        expect(state.clock.status, TimerStatus.paused);
        expect(state.clock.elapsedMs, 0);
        expect(state.periodIndex, 2);
      },
    );

    test(
      'clock resets to fresh at each PERIOD_STARTED — Q1 elapsed never leaks into Q2',
      () {
        final rule = stoppedClockRule();
        final events = [
          regulationStarted('e1', 0, periodIndex: 0),
          timerStarted('e2', 0),
          timerCompleted('e3', 600000),
          periodEnded('e4', 600000),
          regulationStarted('e5', 600000, periodIndex: 1),
          timerStarted('e6', 600000),
        ];
        final state = MatchEngine.replay(rule, events, nowMs: 610000);
        expect(state.periodIndex, 1);
        expect(state.clock.elapsedMs, 10000); // 10s into Q2, not 610s.
      },
    );
  });

  group('MatchEngine — projectLiveElapsed', () {
    test('reports RUNNING (not paused) while projecting live elapsed time', () {
      final rule = stoppedClockRule();
      final baseline = MatchEngine.replay(rule, [
        regulationStarted('e1', 0, periodIndex: 0),
        timerStarted('e2', 0),
      ], nowMs: 0);

      final projected = MatchEngine.projectLiveElapsed(rule, baseline, 5000);
      expect(projected.clock.status, TimerStatus.running);
      expect(projected.clock.elapsedMs, 5000);
      expect(projected.clock.remainingMs, 595000);
    });

    test('still clamps at the period duration when projected past it', () {
      final rule = stoppedClockRule(periodDurationMs: 600000);
      final baseline = MatchEngine.replay(rule, [
        regulationStarted('e1', 0, periodIndex: 0),
        timerStarted('e2', 0),
      ], nowMs: 0);

      final projected = MatchEngine.projectLiveElapsed(rule, baseline, 700000);
      expect(projected.clock.status, TimerStatus.completed);
      expect(projected.clock.elapsedMs, 600000);
      expect(projected.clock.remainingMs, 0);
    });
  });

  group('MatchEngine — decideNextPhase truth table', () {
    final rule = stoppedClockRule(overtimeMaxCount: null); // unlimited OT.

    MatchState stateAt({
      required int periodIndex,
      bool isOvertimePeriod = false,
      int overtimeCount = 0,
    }) => MatchState(
      phase: isOvertimePeriod ? MatchPhase.overtime : MatchPhase.regulation,
      periodIndex: periodIndex,
      isOvertimePeriod: isOvertimePeriod,
      overtimeCount: overtimeCount,
      clock: const MatchClockState(status: TimerStatus.paused, elapsedMs: 0),
      matchEnded: false,
    );

    test('not last regulation period -> continue regardless of score', () {
      final decision = MatchEngine.decideNextPhase(
        rule,
        stateAt(periodIndex: 0),
        scoreState({'a': 20, 'b': 5}),
      );
      expect(decision.action, NextPhaseAction.continueRegulation);
      expect(decision.nextPeriodIndex, 1);
    });

    test('last regulation period, not level -> match ends decided', () {
      final decision = MatchEngine.decideNextPhase(
        rule,
        stateAt(periodIndex: 3),
        scoreState({'a': 80, 'b': 78}),
      );
      expect(decision.action, NextPhaseAction.matchEnds);
      expect(decision.endReason, MatchEndReason.decidedInRegulation);
    });

    test(
      'last regulation period, level, overtime unlimited -> start overtime',
      () {
        final decision = MatchEngine.decideNextPhase(
          rule,
          stateAt(periodIndex: 3),
          scoreState({'a': 80, 'b': 80}),
        );
        expect(decision.action, NextPhaseAction.startOvertime);
        expect(decision.overtimeNumber, 1);
      },
    );

    test('overtime period, not level -> match ends decided in overtime', () {
      final decision = MatchEngine.decideNextPhase(
        rule,
        stateAt(periodIndex: 0, isOvertimePeriod: true, overtimeCount: 1),
        scoreState({'a': 85, 'b': 80}),
      );
      expect(decision.action, NextPhaseAction.matchEnds);
      expect(decision.endReason, MatchEndReason.decidedInOvertime);
    });

    test(
      'overtime exhausted (maxCount reached), level, no shootout, drawAllowed false '
      '-> defensive fallback to draw rather than crashing',
      () {
        final cappedRule = stoppedClockRule(overtimeMaxCount: 1);
        final decision = MatchEngine.decideNextPhase(
          cappedRule,
          stateAt(periodIndex: 0, isOvertimePeriod: true, overtimeCount: 1),
          scoreState({'a': 80, 'b': 80}),
        );
        expect(decision.action, NextPhaseAction.matchEnds);
        expect(decision.endReason, MatchEndReason.regulationDraw);
      },
    );

    test(
      'overtime exhausted, level, shootout configured -> start shootout',
      () {
        final shootoutRule = stoppedClockRule(
          overtimeMaxCount: 1,
          shootout: true,
        );
        final decision = MatchEngine.decideNextPhase(
          shootoutRule,
          stateAt(periodIndex: 0, isOvertimePeriod: true, overtimeCount: 1),
          scoreState({'a': 1, 'b': 1}),
        );
        expect(decision.action, NextPhaseAction.startShootout);
      },
    );

    test(
      "football-style fixed-length extra time (2x15) always plays both periods, "
      'even if not level partway through',
      () {
        final knockoutFootball = MatchRule(
          schemaVersion: 1,
          rulesetId: 'test.football_knockout',
          scoreRule: const TeamScoreRule(
            schemaVersion: 1,
            sideIds: ['a', 'b'],
            allowedIncrements: [1],
          ),
          clock: MatchClockKind.runningClock,
          periods: List.generate(
            2,
            (i) => PeriodRule(index: i, durationMs: 2700000),
          ),
          overtime: const OvertimeRule(durationMs: 900000, maxCount: 2),
          shootout: const ShootoutRule(kicksPerRound: 5, suddenDeath: true),
          matchEnd: const MatchEndRule(drawAllowed: false),
        );

        // End of regulation, level -> enters extra time period 1.
        final afterRegulation = MatchEngine.decideNextPhase(
          knockoutFootball,
          stateAt(periodIndex: 1),
          scoreState({'a': 1, 'b': 1}),
        );
        expect(afterRegulation.action, NextPhaseAction.startOvertime);
        expect(afterRegulation.overtimeNumber, 1);

        // End of ET period 1, NOT level -> still continues to ET period 2
        // regardless (the block is fixed-length, not decisive per period).
        final afterEt1NotLevel = MatchEngine.decideNextPhase(
          knockoutFootball,
          stateAt(periodIndex: 0, isOvertimePeriod: true, overtimeCount: 1),
          scoreState({'a': 2, 'b': 1}),
        );
        expect(afterEt1NotLevel.action, NextPhaseAction.startOvertime);
        expect(afterEt1NotLevel.overtimeNumber, 2);

        // End of ET period 2, NOT level -> now decided (block exhausted).
        final afterEt2NotLevel = MatchEngine.decideNextPhase(
          knockoutFootball,
          stateAt(periodIndex: 1, isOvertimePeriod: true, overtimeCount: 2),
          scoreState({'a': 2, 'b': 1}),
        );
        expect(afterEt2NotLevel.action, NextPhaseAction.matchEnds);
        expect(afterEt2NotLevel.endReason, MatchEndReason.decidedInOvertime);

        // End of ET period 2, level -> shootout (block exhausted, still tied).
        final afterEt2Level = MatchEngine.decideNextPhase(
          knockoutFootball,
          stateAt(periodIndex: 1, isOvertimePeriod: true, overtimeCount: 2),
          scoreState({'a': 1, 'b': 1}),
        );
        expect(afterEt2Level.action, NextPhaseAction.startShootout);
      },
    );

    test(
      'no overtime configured at all, level, drawAllowed true -> match ends in draw',
      () {
        final leagueRule = runningClockRule();
        final decision = MatchEngine.decideNextPhase(
          leagueRule,
          MatchState(
            phase: MatchPhase.regulation,
            periodIndex: 1,
            isOvertimePeriod: false,
            overtimeCount: 0,
            clock: const MatchClockState(
              status: TimerStatus.paused,
              elapsedMs: 0,
            ),
            matchEnded: false,
          ),
          scoreState({'a': 1, 'b': 1}),
        );
        expect(decision.action, NextPhaseAction.matchEnds);
        expect(decision.endReason, MatchEndReason.regulationDraw);
      },
    );
  });

  group('MatchEngine — overtime periods', () {
    test(
      'an OVERTIME PERIOD_STARTED sets phase/overtimeCount and resets the clock',
      () {
        final rule = stoppedClockRule(overtimeMaxCount: null);
        final events = [
          regulationStarted('e1', 0, periodIndex: 3),
          timerStarted('e1b', 0),
          timerCompleted('e2', 600000),
          periodEnded('e3', 600000),
          overtimeStarted('e4', 600000, overtimeNumber: 1),
          timerStarted('e4b', 600000),
        ];
        final state = MatchEngine.replay(rule, events, nowMs: 610000);
        expect(state.phase, MatchPhase.overtime);
        expect(state.isOvertimePeriod, isTrue);
        expect(state.overtimeCount, 1);
        expect(
          state.clock.elapsedMs,
          10000,
        ); // fresh clock since OT started, not 610s.
      },
    );
  });

  group('MatchEngine — SESSION_COMPLETED and undo-reopens-match', () {
    test('SESSION_COMPLETED ends the match with the recorded reason', () {
      final rule = stoppedClockRule();
      final events = [
        regulationStarted('e1', 0, periodIndex: 3),
        sessionCompleted(
          'e2',
          600000,
          reason: MatchEndReason.decidedInRegulation,
        ),
      ];
      final state = MatchEngine.replay(rule, events, nowMs: 700000);
      expect(state.matchEnded, isTrue);
      expect(state.phase, MatchPhase.ended);
      expect(state.endReason, MatchEndReason.decidedInRegulation);
    });

    test('undoing the SESSION_COMPLETED event reopens the match', () {
      final rule = stoppedClockRule();
      final events = [
        regulationStarted('e1', 0, periodIndex: 3),
        sessionCompleted(
          'e2',
          600000,
          reason: MatchEndReason.decidedInRegulation,
        ),
        undo('e3', 601000, targetEventId: 'e2'),
      ];
      final state = MatchEngine.replay(rule, events, nowMs: 700000);
      expect(state.matchEnded, isFalse);
      expect(state.phase, MatchPhase.regulation);
      expect(state.periodIndex, 3);
    });

    test(
      'undoing a PERIOD_ENDED reopens the period clock (not just match end)',
      () {
        final rule = runningClockRule();
        final events = [
          regulationStarted('e1', 0, periodIndex: 1),
          timerStarted('e1b', 0),
          periodEnded('e2', 2700000),
          undo('e3', 2701000, targetEventId: 'e2'),
        ];
        final state = MatchEngine.replay(rule, events, nowMs: 2800000);
        // Period never actually ended once its PERIOD_ENDED is undone — the
        // running clock keeps counting from the original PERIOD_STARTED.
        expect(state.clock.status, TimerStatus.running);
        expect(state.clock.elapsedMs, 2800000);
      },
    );
  });

  group('MatchEngine — STOPPED_CLOCK vs RUNNING_CLOCK finalization', () {
    test('STOPPED_CLOCK clamps at the period duration and auto-completes', () {
      final rule = stoppedClockRule(periodDurationMs: 600000);
      final events = [
        regulationStarted('e1', 0, periodIndex: 0),
        timerStarted('e2', 0),
      ];
      final state = MatchEngine.replay(rule, events, nowMs: 999999999);
      expect(state.clock.elapsedMs, 600000);
      expect(state.clock.remainingMs, 0);
      expect(state.clock.status, TimerStatus.completed);
      expect(
        MatchEngine.isUnfinalizedStoppedPeriodCompletion(rule, state, false),
        isTrue,
      );
      expect(
        MatchEngine.isUnfinalizedStoppedPeriodCompletion(rule, state, true),
        isFalse,
      );
    });

    test(
      'RUNNING_CLOCK never clamps — can exceed the period duration (45+3)',
      () {
        final rule = runningClockRule(periodDurationMs: 2700000);
        final events = [
          regulationStarted('e1', 0, periodIndex: 0),
          timerStarted('e2', 0),
        ];
        final state = MatchEngine.replay(
          rule,
          events,
          nowMs: 2880000,
        ); // 48:00.
        expect(state.clock.elapsedMs, 2880000);
        expect(state.clock.remainingMs, isNull);
        expect(state.clock.status, TimerStatus.running);
      },
    );

    test(
      'pause/resume mid-period accumulates correctly for a STOPPED_CLOCK',
      () {
        final rule = stoppedClockRule();
        final events = [
          regulationStarted('e1', 0, periodIndex: 0),
          timerStarted('e1b', 0),
          timerPaused('e2', 60000),
          timerResumed('e3', 120000),
        ];
        final state = MatchEngine.replay(rule, events, nowMs: 180000);
        // 60s ran, 60s paused, then 60s more running = 120s elapsed.
        expect(state.clock.elapsedMs, 120000);
        expect(state.clock.status, TimerStatus.running);
      },
    );

    test(
      'TIMER_COMPLETED then PERIOD_ENDED freezes the clock (stopped-clock auto-expiry pairing)',
      () {
        final rule = stoppedClockRule(periodDurationMs: 600000);
        final events = [
          regulationStarted('e1', 0, periodIndex: 0),
          timerStarted('e1b', 0),
          timerCompleted('e2', 600000),
          periodEnded('e3', 600000),
        ];
        final state = MatchEngine.replay(rule, events, nowMs: 999999);
        expect(state.clock.elapsedMs, 600000);
        expect(state.clock.status, TimerStatus.completed);
      },
    );
  });

  group('MatchEngine — general event sourcing guarantees', () {
    test(
      'replay is deterministic: same events always produce the same state',
      () {
        final rule = stoppedClockRule();
        final events = [
          regulationStarted('e1', 0, periodIndex: 2),
          timerPaused('e2', 30000),
        ];
        final s1 = MatchEngine.replay(rule, events, nowMs: 40000);
        final s2 = MatchEngine.replay(rule, events, nowMs: 40000);
        expect(s1, s2);
      },
    );

    test('a duplicate event id anywhere in the log is applied only once', () {
      final rule = stoppedClockRule();
      final events = [
        regulationStarted('e1', 0, periodIndex: 0),
        timerStarted('e2', 0),
        timerStarted(
          'e2',
          5000,
        ), // same id as above, ignored — not a second start.
      ];
      final state = MatchEngine.replay(rule, events, nowMs: 10000);
      expect(
        state.clock.elapsedMs,
        10000,
      ); // measured from the original atMs=0, not 5000.
    });
  });
}
