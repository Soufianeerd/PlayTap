import 'package:meta/meta.dart';

import 'lap_split.dart';
import 'timer_status.dart';

/// Output of `TimerEngine.replay` — always derived, never stored as a
/// second source of truth (see `playtap-timer-engine`, DATA_MODEL.md).
@immutable
class TimerState {
  const TimerState({
    required this.status,
    required this.elapsedMs,
    required this.remainingMs,
    required this.laps,
  });

  final TimerStatus status;

  /// Time actually run, excluding paused intervals. For COUNTDOWN, clamped
  /// so it never exceeds `durationTargetMs`.
  final int elapsedMs;

  /// Only non-null for COUNTDOWN. Never negative — clamps at 0.
  final int? remainingMs;

  /// Empty unless the mode is LAP_TIMER.
  final List<LapSplit> laps;

  @override
  bool operator ==(Object other) =>
      other is TimerState &&
      status == other.status &&
      elapsedMs == other.elapsedMs &&
      remainingMs == other.remainingMs &&
      _lapsEqual(laps, other.laps);

  @override
  int get hashCode =>
      Object.hash(status, elapsedMs, remainingMs, Object.hashAll(laps));

  static bool _lapsEqual(List<LapSplit> a, List<LapSplit> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
