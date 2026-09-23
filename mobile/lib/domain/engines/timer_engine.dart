import 'clock_engine.dart';
import '../events/timer_engine_event.dart';
import '../models/lap_split.dart';
import '../models/timer_mode.dart';
import '../models/timer_spec.dart';
import '../models/timer_state.dart';
import '../models/timer_status.dart';

/// Pure, deterministic timer derivation — see `playtap-timer-engine`.
///
/// No Flutter, no Riverpod, no Drift, no clock of its own: `replay` is a
/// plain function of its three arguments (`spec`, `events`, `nowMs`).
/// `state = replay(events, now)` must hold for any prefix or full replay,
/// every time — never `remaining--` or `elapsed++` per tick.
///
/// The running-since/accumulated-ms bookkeeping itself lives in
/// [ClockAccumulator] (`clock_engine.dart`), shared with `MatchEngine`'s
/// per-period clock — this class only adds what's specific to a standalone
/// Timer session: lap splits and COUNTDOWN clamping (`_finalize`).
abstract final class TimerEngine {
  static TimerState replay(
    TimerSpec spec,
    List<TimerEngineEvent> events, {
    required int nowMs,
  }) {
    var clock = const ClockAccumulator();
    final laps = <LapSplit>[];
    final seenEventIds = <String>{};

    for (final event in events) {
      if (clock.completed) break; // a completed timer ignores anything after.
      if (!seenEventIds.add(event.id)) continue; // duplicate id: no-op.

      switch (event.type) {
        case TimerEngineEventType.started:
          clock = clock.apply(ClockCommandType.started, event.atMs);

        case TimerEngineEventType.paused:
          clock = clock.apply(ClockCommandType.paused, event.atMs);

        case TimerEngineEventType.resumed:
          clock = clock.apply(ClockCommandType.resumed, event.atMs);

        case TimerEngineEventType.lapRecorded:
          if (!clock.started) continue;
          final cumulative = clock.elapsedAt(event.atMs);
          final previous = laps.isEmpty ? 0 : laps.last.cumulativeElapsedMs;
          laps.add(
            LapSplit(
              eventId: event.id,
              lapNumber: laps.length + 1,
              cumulativeElapsedMs: cumulative,
              splitMs: cumulative - previous,
            ),
          );

        case TimerEngineEventType.completed:
          clock = clock.apply(ClockCommandType.completed, event.atMs);
      }
    }

    if (!clock.started) {
      return TimerState(
        status: TimerStatus.paused,
        elapsedMs: 0,
        remainingMs: spec.durationTargetMs,
        laps: const [],
      );
    }

    final elapsedMs = clock.elapsedAt(nowMs);
    final rawStatus = clock.completed
        ? TimerStatus.completed
        : (clock.runningSinceMs == null
              ? TimerStatus.paused
              : TimerStatus.running);

    return _finalize(spec, rawStatus, elapsedMs, laps);
  }

  /// Projects what the display should show [liveElapsedMs] after a
  /// baseline replay, using the *monotonic* clock instead of another
  /// wall-clock replay — see `TimerSessionController.currentDisplaySnapshot`
  /// and `playtap-timer-engine` "Quelle horloge pour `now` ?". Only valid
  /// while the baseline status is `running`; [laps] are carried over
  /// unchanged (a lap is only ever added by a real persisted event).
  static TimerState projectLiveElapsed(
    TimerSpec spec,
    int liveElapsedMs,
    List<LapSplit> laps,
  ) {
    return _finalize(spec, TimerStatus.running, liveElapsedMs, laps);
  }

  /// Clamps elapsed/remaining for COUNTDOWN (never negative remaining,
  /// never over target — see "Fin de countdown" in `playtap-timer-engine`)
  /// and is the single place both `replay` and `projectLiveElapsed` derive
  /// the final [TimerState] from, so they can never disagree.
  static TimerState _finalize(
    TimerSpec spec,
    TimerStatus rawStatus,
    int rawElapsedMs,
    List<LapSplit> laps,
  ) {
    var elapsedMs = rawElapsedMs;
    var status = rawStatus;
    int? remainingMs;

    if (spec.mode == TimerMode.countdown) {
      final target = spec.durationTargetMs!;
      if (elapsedMs >= target) {
        elapsedMs = target; // never negative remaining, never over target.
        remainingMs = 0;
        // A countdown that has run its full duration is complete even if
        // no TIMER_COMPLETED event has been persisted yet — see
        // `playtap-timer-engine` "Fin de countdown": detected by
        // comparison, not by waiting for an exact tick. The caller
        // (TimerSessionController) is responsible for persisting the
        // event exactly once; this pure function only ever reports state.
        status = TimerStatus.completed;
      } else {
        remainingMs = target - elapsedMs;
      }
    }

    return TimerState(
      status: status,
      elapsedMs: elapsedMs,
      remainingMs: remainingMs,
      laps: laps,
    );
  }

  /// Whether [state] represents a COUNTDOWN that ran out on its own
  /// (`remainingMs == 0`) without a terminal event yet in the log — the
  /// one case a caller must persist a finalizing event for (see
  /// `TimerSessionController._finalizeIfExpired`).
  static bool isUnfinalizedCountdownCompletion(
    TimerSpec spec,
    TimerState state,
    bool terminalEventAlreadyPersisted,
  ) {
    return spec.mode == TimerMode.countdown &&
        state.status == TimerStatus.completed &&
        !terminalEventAlreadyPersisted;
  }
}
