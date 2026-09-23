import 'timer_status.dart';

/// Output of `ShotClockEngine.replay` — reuses [TimerStatus], same
/// vocabulary as `MatchClockState`/`TimerState`.
class ShotClockState {
  const ShotClockState({
    required this.status,
    required this.elapsedMs,
    required this.remainingMs,
  });

  final TimerStatus status;
  final int elapsedMs;
  final int remainingMs;

  @override
  bool operator ==(Object other) =>
      other is ShotClockState &&
      status == other.status &&
      elapsedMs == other.elapsedMs &&
      remainingMs == other.remainingMs;

  @override
  int get hashCode => Object.hash(status, elapsedMs, remainingMs);
}
