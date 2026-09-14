/// Two clocks, two jobs — see the "Quelle horloge pour `now` ?" section of
/// the `playtap-timer-engine` skill:
///
/// - [now] (wall clock) is what gets persisted on every `SessionEvent`, so
///   an app restart can rebuild `TimerState` from timestamps alone.
/// - [monotonicNowMillis] is what a *live*, still-running process uses to
///   tick the on-screen display between two persisted events. It never
///   jumps when the system clock does (DST, NTP correction, a manual
///   clock change) because it isn't derived from the system clock at all.
///
/// Neither survives a process restart being read directly — [now] does,
/// [monotonicNowMillis] deliberately doesn't (a monotonic clock is only
/// meaningful within one process's lifetime), which is exactly why
/// recovery always replays from persisted wall-clock timestamps, never
/// from a monotonic value.
abstract class AppClock {
  DateTime now();

  int monotonicNowMillis();
}

/// Production clock. `Stopwatch` is backed by the platform's monotonic
/// timer (not the system wall clock), so [monotonicNowMillis] keeps
/// advancing steadily even if [now] jumps.
class SystemAppClock implements AppClock {
  SystemAppClock() : _stopwatch = Stopwatch()..start();

  final Stopwatch _stopwatch;

  @override
  DateTime now() => DateTime.now();

  @override
  int monotonicNowMillis() => _stopwatch.elapsedMilliseconds;
}

/// Fully controllable clock for deterministic tests — see
/// `playtap-timer-engine` and the Phase 1B.2 brief: Timer tests must never
/// depend on real elapsed wall-clock time.
class FakeClock implements AppClock {
  FakeClock({DateTime? initialNow, int initialMonotonicMs = 0})
    : _now = initialNow ?? DateTime.utc(2026, 1, 1),
      _monotonicMs = initialMonotonicMs;

  DateTime _now;
  int _monotonicMs;

  @override
  DateTime now() => _now;

  @override
  int monotonicNowMillis() => _monotonicMs;

  /// Advances both clocks together (the common case: real time passing
  /// while the process stays alive).
  void advance(Duration duration) {
    _now = _now.add(duration);
    _monotonicMs += duration.inMilliseconds;
  }

  /// Moves the wall clock only — simulates a system clock jump (DST, NTP,
  /// manual change) without any real time having passed, to verify a live
  /// monotonic-driven timer is unaffected by it.
  void jumpWallClockOnly(Duration duration) {
    _now = _now.add(duration);
  }

  /// Simulates "the process died and was relaunched later": the monotonic
  /// clock resets (a fresh process starts a fresh `Stopwatch` at 0) while
  /// the wall clock keeps advancing.
  void simulateProcessRestart({required Duration wallClockAdvance}) {
    _now = _now.add(wallClockAdvance);
    _monotonicMs = 0;
  }
}
