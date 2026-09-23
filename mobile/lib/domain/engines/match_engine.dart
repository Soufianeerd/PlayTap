import 'clock_engine.dart';
import '../events/match_engine_event.dart';
import '../models/match_clock_kind.dart';
import '../models/match_clock_state.dart';
import '../models/match_rule.dart';
import '../models/match_state.dart';
import '../models/score_state.dart';
import '../models/timer_status.dart';

/// Pure, deterministic period/clock/phase derivation for Basketball,
/// Football, and Futsal — see `playtap-score-engine`'s `MatchRule`
/// composition note and docs/DATA_MODEL.md. Score itself is never touched
/// here (that stays `ScoreEngine`'s job, replayed separately from the same
/// log and composed by `match_session_deriver.dart`) — `MatchEngine` only
/// ever answers "which period/phase are we in, and what does the clock
/// say," exactly the way `TimerEngine.replay` never re-decides anything
/// either.
///
/// No Flutter, no Riverpod, no Drift, no clock of its own: `replay` is a
/// plain function of `(rule, events, nowMs)`.
abstract final class MatchEngine {
  static MatchState replay(
    MatchRule rule,
    List<MatchEngineEvent> events, {
    required int nowMs,
  }) {
    // UNDO in a team-match session always carries an explicit
    // targetEventId (see `team_match_session_controller.dart` — cross-
    // engine undo ambiguity is resolved by the controller, never here).
    // Filtering the targeted event out and forward-replaying the
    // remainder is simpler and safer than inventing bespoke per-
    // transition reversal logic for every phase transition, and composes
    // for free with `ScoreEngine`/`ShootoutEngine` doing the exact same
    // filter independently over their own event subset.
    final undoneIds = <String>{};
    for (final event in events) {
      if (event.type != MatchEngineEventType.undo) continue;
      final target = event.payload['targetEventId'] as String?;
      if (target != null) undoneIds.add(target);
    }

    var phase = MatchPhase.regulation;
    var periodIndex = 0;
    var isOvertimePeriod = false;
    var overtimeCount = 0;
    var clock = const ClockAccumulator();
    var matchEnded = false;
    MatchEndReason? endReason;
    int? announcedAddedTimeMs;
    final seenEventIds = <String>{};

    for (final event in events) {
      if (event.type == MatchEngineEventType.undo) {
        continue; // instruction, not state.
      }
      if (undoneIds.contains(event.id)) continue; // this event was undone.
      if (!seenEventIds.add(event.id)) continue; // duplicate id: no-op.

      switch (event.type) {
        case MatchEngineEventType.periodStarted:
          clock = const ClockAccumulator();
          announcedAddedTimeMs = null;
          matchEnded = false;
          endReason = null;
          if (event.payload['kind'] == 'OVERTIME') {
            isOvertimePeriod = true;
            overtimeCount = event.payload['overtimeNumber'] as int;
            periodIndex = overtimeCount - 1;
            phase = MatchPhase.overtime;
          } else {
            isOvertimePeriod = false;
            periodIndex = event.payload['periodIndex'] as int;
            phase = MatchPhase.regulation;
          }

        case MatchEngineEventType.periodEnded:
          clock = clock.apply(ClockCommandType.completed, event.atMs);

        case MatchEngineEventType.addedTimeAnnounced:
          announcedAddedTimeMs = event.payload['addedTimeMs'] as int;

        case MatchEngineEventType.timerStarted:
          // Paired with PERIOD_STARTED in the same transaction (see
          // `team_match_actions.dart`) — PERIOD_STARTED resets to a fresh,
          // not-yet-running accumulator; this is what actually starts it.
          clock = clock.apply(ClockCommandType.started, event.atMs);

        case MatchEngineEventType.timerPaused:
          clock = clock.apply(ClockCommandType.paused, event.atMs);

        case MatchEngineEventType.timerResumed:
          clock = clock.apply(ClockCommandType.resumed, event.atMs);

        case MatchEngineEventType.timerCompleted:
          clock = clock.apply(ClockCommandType.completed, event.atMs);

        case MatchEngineEventType.shootoutStarted:
          phase = MatchPhase.shootoutInProgress;

        case MatchEngineEventType.shootoutCompleted:
          break; // informational only — SESSION_COMPLETED carries the result.

        case MatchEngineEventType.sessionCompleted:
          matchEnded = true;
          phase = MatchPhase.ended;
          endReason = _endReasonFromJson(event.payload['endReason'] as String?);

        case MatchEngineEventType.undo:
          break; // unreachable — filtered above.
      }
    }

    final periodDurationMs = isOvertimePeriod
        ? rule.overtime?.durationMs
        : (periodIndex < rule.periods.length
              ? rule.periods[periodIndex].durationMs
              : null);

    return MatchState(
      phase: phase,
      periodIndex: periodIndex,
      isOvertimePeriod: isOvertimePeriod,
      overtimeCount: overtimeCount,
      clock: _finalizeClock(rule.clock, clock, periodDurationMs, nowMs),
      matchEnded: matchEnded,
      endReason: endReason,
      announcedAddedTimeMs: announcedAddedTimeMs,
    );
  }

  /// Projects what the display should show [liveElapsedMs] after a
  /// baseline replay, using the monotonic clock instead of another
  /// wall-clock replay — mirrors `TimerEngine.projectLiveElapsed`. Only
  /// valid while [baseline]'s clock is running.
  static MatchState projectLiveElapsed(
    MatchRule rule,
    MatchState baseline,
    int liveElapsedMs,
  ) {
    final periodDurationMs = baseline.isOvertimePeriod
        ? rule.overtime?.durationMs
        : (baseline.periodIndex < rule.periods.length
              ? rule.periods[baseline.periodIndex].durationMs
              : null);
    // `runningSinceMs: 0` (not null) is what makes `_finalizeClock` read
    // this as *running*, not paused — mirrors `TimerEngine.
    // projectLiveElapsed` passing `TimerStatus.running` explicitly rather
    // than trying to infer it. `elapsedAt(liveElapsedMs)` then yields
    // exactly `liveElapsedMs` (`0 + (liveElapsedMs - 0)`).
    final projected = const ClockAccumulator(started: true, runningSinceMs: 0);
    return MatchState(
      phase: baseline.phase,
      periodIndex: baseline.periodIndex,
      isOvertimePeriod: baseline.isOvertimePeriod,
      overtimeCount: baseline.overtimeCount,
      clock: _finalizeClock(
        rule.clock,
        projected,
        periodDurationMs,
        liveElapsedMs,
      ),
      matchEnded: baseline.matchEnded,
      endReason: baseline.endReason,
      announcedAddedTimeMs: baseline.announcedAddedTimeMs,
    );
  }

  /// Whether the current period is a STOPPED_CLOCK period that has run out
  /// on its own (`remainingMs == 0`) without a `TIMER_COMPLETED`/
  /// `PERIOD_ENDED` pair yet in the log — the one case the controller must
  /// persist that pair for. [terminalEventAlreadyPersisted] must be
  /// determined by the caller from the raw log (not from [state] itself:
  /// `_finalizeClock` already reports `completed` purely from elapsed-vs-
  /// duration comparison, before any event is persisted for it — exactly
  /// mirroring `TimerEngine.isUnfinalizedCountdownCompletion`'s identical
  /// split between "what replay reports" and "what's actually on disk").
  static bool isUnfinalizedStoppedPeriodCompletion(
    MatchRule rule,
    MatchState state,
    bool terminalEventAlreadyPersisted,
  ) {
    return rule.clock == MatchClockKind.stoppedClock &&
        !state.matchEnded &&
        state.clock.remainingMs == 0 &&
        !terminalEventAlreadyPersisted;
  }

  /// Clamps elapsed/remaining for a STOPPED_CLOCK period (never negative
  /// remaining, never over the period duration — mirrors
  /// `TimerEngine._finalize`'s COUNTDOWN clamping) and leaves a
  /// RUNNING_CLOCK period unclamped (Football: can show 45+3). Both
  /// `replay` and `projectLiveElapsed` derive the final [MatchClockState]
  /// from here, so they can never disagree.
  static MatchClockState _finalizeClock(
    MatchClockKind kind,
    ClockAccumulator clock,
    int? periodDurationMs,
    int nowMs,
  ) {
    if (!clock.started) {
      return MatchClockState(
        status: TimerStatus.paused,
        elapsedMs: 0,
        remainingMs: kind == MatchClockKind.stoppedClock
            ? periodDurationMs
            : null,
      );
    }

    var elapsedMs = clock.elapsedAt(nowMs);
    var completed = clock.completed;

    if (kind == MatchClockKind.stoppedClock && periodDurationMs != null) {
      if (elapsedMs >= periodDurationMs) {
        elapsedMs = periodDurationMs;
        completed = true;
        return MatchClockState(
          status: TimerStatus.completed,
          elapsedMs: elapsedMs,
          remainingMs: 0,
        );
      }
      return MatchClockState(
        status: clock.runningSinceMs == null
            ? TimerStatus.paused
            : TimerStatus.running,
        elapsedMs: elapsedMs,
        remainingMs: periodDurationMs - elapsedMs,
      );
    }

    return MatchClockState(
      status: completed
          ? TimerStatus.completed
          : (clock.runningSinceMs == null
                ? TimerStatus.paused
                : TimerStatus.running),
      elapsedMs: elapsedMs,
      remainingMs: null,
    );
  }

  static MatchEndReason? _endReasonFromJson(String? value) => switch (value) {
    'DECIDED_IN_REGULATION' => MatchEndReason.decidedInRegulation,
    'DECIDED_IN_OVERTIME' => MatchEndReason.decidedInOvertime,
    'DECIDED_BY_SHOOTOUT' => MatchEndReason.decidedByShootout,
    'REGULATION_DRAW' => MatchEndReason.regulationDraw,
    _ => null,
  };

  /// The pure, config-driven "what happens once this period is over"
  /// decision — see the `MatchRule` composition note: this is the *only*
  /// place a match's ending is decided, and it never branches on sport
  /// identity, only on [rule]'s data. Called by the controller exactly
  /// once, at the moment a period naturally ends (auto-detected for
  /// STOPPED_CLOCK via [isUnfinalizedStoppedPeriodCompletion], or on a
  /// manual `endPeriodManually()` for RUNNING_CLOCK).
  static NextPhaseDecision decideNextPhase(
    MatchRule rule,
    MatchState state,
    ScoreState score,
  ) {
    if (!state.isOvertimePeriod) {
      final isLastRegulationPeriod =
          state.periodIndex >= rule.periods.length - 1;
      if (!isLastRegulationPeriod) {
        return NextPhaseDecision.continueRegulation(
          nextPeriodIndex: state.periodIndex + 1,
        );
      }
    } else {
      final maxCount = rule.overtime?.maxCount;
      if (maxCount != null && state.overtimeCount < maxCount) {
        // A fixed-length overtime block (e.g. football's 2x15 extra time,
        // `maxCount: 2`) is always played out in full before any decision
        // is made, regardless of the score partway through it — see the
        // dual semantics documented on `OvertimeRule.maxCount`.
        return NextPhaseDecision.startOvertime(
          overtimeNumber: state.overtimeCount + 1,
        );
      }
    }

    // Decision point: either the last regulation period just ended, or
    // the current overtime is done (a single uncapped period, or a
    // fixed-length block just exhausted).
    final scores = score.scores.values.toList();
    final isLevel = scores.isEmpty || scores.every((s) => s == scores.first);
    if (!isLevel) {
      return NextPhaseDecision.matchEnds(
        state.isOvertimePeriod
            ? MatchEndReason.decidedInOvertime
            : MatchEndReason.decidedInRegulation,
      );
    }

    if (!state.isOvertimePeriod) {
      // Still level at the end of regulation: enter overtime if configured
      // (whether basketball's uncapped single period or football's
      // fixed-length block — both start the same way, at overtimeNumber 1).
      if (rule.overtime != null) {
        return NextPhaseDecision.startOvertime(overtimeNumber: 1);
      }
    } else if (rule.overtime!.maxCount == null) {
      // Still level after an uncapped overtime period (Basketball, FIBA
      // Article 8: as many 5-minute overtimes as necessary) — play another.
      return NextPhaseDecision.startOvertime(
        overtimeNumber: state.overtimeCount + 1,
      );
    }

    if (rule.shootout != null) {
      return NextPhaseDecision.startShootout();
    }

    // Defensive fallback for a misconfigured ruleset (drawAllowed should
    // be true whenever overtime/shootout are both absent or exhausted) —
    // never crash mid-match.
    return NextPhaseDecision.matchEnds(MatchEndReason.regulationDraw);
  }
}

enum NextPhaseAction {
  continueRegulation,
  startOvertime,
  startShootout,
  matchEnds,
}

/// Output of `MatchEngine.decideNextPhase` — a plain data description of
/// what to do next; the controller is responsible for turning this into
/// the actual `PERIOD_STARTED`/`SHOOTOUT_STARTED`/`SESSION_COMPLETED`
/// event(s) to persist.
class NextPhaseDecision {
  const NextPhaseDecision._(
    this.action, {
    this.nextPeriodIndex,
    this.overtimeNumber,
    this.endReason,
  });

  final NextPhaseAction action;
  final int? nextPeriodIndex;
  final int? overtimeNumber;
  final MatchEndReason? endReason;

  factory NextPhaseDecision.continueRegulation({
    required int nextPeriodIndex,
  }) => NextPhaseDecision._(
    NextPhaseAction.continueRegulation,
    nextPeriodIndex: nextPeriodIndex,
  );

  factory NextPhaseDecision.startOvertime({required int overtimeNumber}) =>
      NextPhaseDecision._(
        NextPhaseAction.startOvertime,
        overtimeNumber: overtimeNumber,
      );

  factory NextPhaseDecision.startShootout() =>
      const NextPhaseDecision._(NextPhaseAction.startShootout);

  factory NextPhaseDecision.matchEnds(MatchEndReason reason) =>
      NextPhaseDecision._(NextPhaseAction.matchEnds, endReason: reason);
}

/// JSON mapping for `MatchEndReason`, shared by the controller (writing
/// `SESSION_COMPLETED.payload['endReason']`) and `MatchEngine.replay`
/// (reading it back) — see `_endReasonFromJson` above.
extension MatchEndReasonJson on MatchEndReason {
  String toJson() => switch (this) {
    MatchEndReason.decidedInRegulation => 'DECIDED_IN_REGULATION',
    MatchEndReason.decidedInOvertime => 'DECIDED_IN_OVERTIME',
    MatchEndReason.decidedByShootout => 'DECIDED_BY_SHOOTOUT',
    MatchEndReason.regulationDraw => 'REGULATION_DRAW',
  };
}
