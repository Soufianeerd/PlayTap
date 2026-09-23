import 'clock_engine.dart';
import '../events/shot_clock_engine_event.dart';
import '../models/shot_clock_rule.dart';
import '../models/shot_clock_state.dart';
import '../models/timer_status.dart';

/// Pure, deterministic shot-clock derivation (FIBA Article 29 — see
/// docs/SPORT_RULES.md). Reuses [ClockAccumulator], the same primitive
/// `TimerEngine`/`MatchEngine` share, so no clock math is duplicated a
/// third time.
///
/// `SHOT_CLOCK_RESET` starts a fresh "leg": a brand-new [ClockAccumulator]
/// counting toward the reset's own `durationMs` (24000 or 14000) — if the
/// clock was already running at the moment of reset, the new leg starts
/// running immediately (a reset happens at a live-ball moment in real
/// play); if it was paused/never started, the new leg stays paused at the
/// new duration until an explicit `SHOT_CLOCK_STARTED`. This mirrors
/// `MatchEngine`'s clock-resets-at-`PERIOD_STARTED` pattern, just
/// triggered by a different event.
abstract final class ShotClockEngine {
  static ShotClockState replay(
    ShotClockRule rule,
    List<ShotClockEngineEvent> events, {
    required int nowMs,
  }) {
    final undoneIds = <String>{};
    for (final event in events) {
      if (event.type != ShotClockEngineEventType.undo) continue;
      final target = event.payload['targetEventId'] as String?;
      if (target != null) undoneIds.add(target);
    }

    var targetMs = rule.defaultDurationMs;
    var clock = const ClockAccumulator();
    final seenEventIds = <String>{};

    for (final event in events) {
      if (event.type == ShotClockEngineEventType.undo) continue; // instruction.
      if (undoneIds.contains(event.id)) continue; // this event was undone.
      if (!seenEventIds.add(event.id)) continue; // duplicate id: no-op.

      switch (event.type) {
        case ShotClockEngineEventType.started:
          // No separate "resumed" event in this engine's vocabulary (see
          // the brief's event list) — `started` does double duty: a real
          // start on a fresh leg (`clock.started == false`, e.g. right
          // after a reset), or a resume when the leg was merely paused
          // (`clock.started == true`) — `ClockAccumulator.apply(started)`
          // alone would silently no-op in the second case, since it only
          // guards against a *duplicate* start.
          clock = clock.started
              ? clock.apply(ClockCommandType.resumed, event.atMs)
              : clock.apply(ClockCommandType.started, event.atMs);

        case ShotClockEngineEventType.paused:
          clock = clock.apply(ClockCommandType.paused, event.atMs);

        case ShotClockEngineEventType.reset:
          final wasRunning =
              clock.started && !clock.completed && clock.runningSinceMs != null;
          targetMs = event.payload['durationMs'] as int;
          clock = const ClockAccumulator();
          if (wasRunning) {
            clock = clock.apply(ClockCommandType.started, event.atMs);
          }

        case ShotClockEngineEventType.completed:
          clock = clock.apply(ClockCommandType.completed, event.atMs);

        case ShotClockEngineEventType.undo:
          break; // unreachable — filtered above.
      }
    }

    if (!clock.started) {
      return ShotClockState(
        status: TimerStatus.paused,
        elapsedMs: 0,
        remainingMs: targetMs,
      );
    }

    var elapsedMs = clock.elapsedAt(nowMs);
    if (elapsedMs >= targetMs) {
      return ShotClockState(
        status: TimerStatus.completed,
        elapsedMs: targetMs,
        remainingMs: 0,
      );
    }

    return ShotClockState(
      status: clock.runningSinceMs == null
          ? TimerStatus.paused
          : TimerStatus.running,
      elapsedMs: elapsedMs,
      remainingMs: targetMs - elapsedMs,
    );
  }

  /// Projects what the display should show [liveElapsedMs] after a
  /// baseline replay — mirrors `MatchEngine.projectLiveElapsed`/
  /// `TimerEngine.projectLiveElapsed`. Only valid while [baseline] is
  /// running. `runningSinceMs: 0` (not null) is what makes the projected
  /// leg read as *running* rather than paused — see
  /// `MatchEngine.projectLiveElapsed`'s identical doc note for why this
  /// matters (a past real bug: a naively-reconstructed accumulator with
  /// `runningSinceMs: null` reads as paused no matter what).
  static ShotClockState projectLiveElapsed(
    ShotClockState baseline,
    int liveElapsedMs,
  ) {
    final target =
        baseline.elapsedMs + baseline.remainingMs; // this leg's duration.
    if (liveElapsedMs >= target) {
      return ShotClockState(
        status: TimerStatus.completed,
        elapsedMs: target,
        remainingMs: 0,
      );
    }
    return ShotClockState(
      status: TimerStatus.running,
      elapsedMs: liveElapsedMs,
      remainingMs: target - liveElapsedMs,
    );
  }

  /// Whether the shot clock has run out on its own without a
  /// `SHOT_CLOCK_COMPLETED` persisted yet for it — mirrors
  /// `MatchEngine.isUnfinalizedStoppedPeriodCompletion`'s identical shape.
  static bool isUnfinalizedCompletion(
    ShotClockState state,
    bool terminalEventAlreadyPersisted,
  ) {
    return state.remainingMs == 0 && !terminalEventAlreadyPersisted;
  }
}
