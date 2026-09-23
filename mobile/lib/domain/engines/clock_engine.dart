/// Shared pure clock primitive — the running-since/accumulated-ms
/// bookkeeping used by both `TimerEngine` (stopwatch/countdown/lap timer)
/// and `MatchEngine` (per-period match clock), extracted so neither
/// duplicates it — see `playtap-timer-engine` and the Phase Sports 2 brief
/// section 5 ("extraire une primitive de clock réutilisable").
///
/// No Flutter, no I/O, no clock of its own: [ClockAccumulator] is an
/// immutable value: `apply` is a pure transition, `elapsedAt` a pure
/// projection. Never `elapsed++` per tick — always derived from the
/// commands actually applied plus the caller's own `nowMs`.
enum ClockCommandType { started, paused, resumed, completed }

/// One clock command in a command sequence. Callers translate their own
/// event types into these (see `TimerEngine.replay`, future `MatchEngine`
/// per-period clock) — [ClockAccumulator] itself knows nothing about
/// timers, matches, or sessions.
class ClockCommand {
  const ClockCommand({required this.type, required this.atMs});

  final ClockCommandType type;
  final int atMs;
}

/// Immutable clock state — apply commands one at a time with [apply],
/// project elapsed time at any instant with [elapsedAt]. Every invalid
/// transition (double start, pause-while-paused, resume-while-running,
/// anything after completion) is a no-op that returns `this` unchanged —
/// mirrors `TimerEngine.replay`'s original inline no-op guards exactly.
class ClockAccumulator {
  const ClockAccumulator({
    this.started = false,
    this.completed = false,
    this.runningSinceMs,
    this.accumulatedMs = 0,
  });

  final bool started;
  final bool completed;

  /// Set while running; null while not started, paused, or completed.
  final int? runningSinceMs;

  /// Elapsed time banked from completed running spans — excludes the
  /// current in-progress span while [runningSinceMs] is set (see
  /// [elapsedAt]).
  final int accumulatedMs;

  /// Elapsed time at [atMs] — the *only* place a running span's partial
  /// duration is computed. While completed or paused (`runningSinceMs ==
  /// null`), this ignores [atMs] entirely and returns [accumulatedMs],
  /// which is exactly why the same call works for both live projection
  /// (`nowMs`) and terminal state (any `atMs`).
  int elapsedAt(int atMs) {
    final since = runningSinceMs;
    return since == null ? accumulatedMs : accumulatedMs + (atMs - since);
  }

  ClockAccumulator apply(ClockCommandType type, int atMs) {
    if (completed) return this; // a completed clock ignores anything after.
    switch (type) {
      case ClockCommandType.started:
        if (started) return this; // ignore a duplicate start.
        return ClockAccumulator(
          started: true,
          runningSinceMs: atMs,
          accumulatedMs: accumulatedMs,
        );

      case ClockCommandType.paused:
        final since = runningSinceMs;
        if (!started || since == null) return this; // not running.
        return ClockAccumulator(
          started: true,
          accumulatedMs: accumulatedMs + (atMs - since),
        );

      case ClockCommandType.resumed:
        if (!started || runningSinceMs != null) return this; // not paused.
        return ClockAccumulator(
          started: true,
          runningSinceMs: atMs,
          accumulatedMs: accumulatedMs,
        );

      case ClockCommandType.completed:
        if (!started) return this;
        return ClockAccumulator(
          started: true,
          completed: true,
          accumulatedMs: elapsedAt(atMs),
        );
    }
  }
}
