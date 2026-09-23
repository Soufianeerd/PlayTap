import 'timer_status.dart';

/// Output of the current period's clock — reuses [TimerStatus] (the same
/// running/paused/completed vocabulary the standalone Timer feature
/// already uses) rather than the full `TimerState`, which also carries a
/// `laps` field with no meaning for a match clock.
class MatchClockState {
  const MatchClockState({
    required this.status,
    required this.elapsedMs,
    this.remainingMs,
  });

  final TimerStatus status;

  final int elapsedMs;

  /// Null for a RUNNING_CLOCK period (Football: no ceiling, can show
  /// 45+3); set and clamped at 0 for a STOPPED_CLOCK period (Basketball,
  /// Futsal), exactly like `TimerState.remainingMs` for a COUNTDOWN.
  final int? remainingMs;

  @override
  bool operator ==(Object other) =>
      other is MatchClockState &&
      status == other.status &&
      elapsedMs == other.elapsedMs &&
      remainingMs == other.remainingMs;

  @override
  int get hashCode => Object.hash(status, elapsedMs, remainingMs);
}
