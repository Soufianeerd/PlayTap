/// Base timer shapes from `playtap-timer-engine`. [interval] is reserved
/// for the Interval Engine (Phase 1B.3+) — declared here so `TimerSpec`
/// doesn't need a breaking rename later, but never constructed yet.
enum TimerMode {
  stopwatch,
  countdown,
  lapTimer,
  interval;

  String toJson() => switch (this) {
    TimerMode.stopwatch => 'STOPWATCH',
    TimerMode.countdown => 'COUNTDOWN',
    TimerMode.lapTimer => 'LAP_TIMER',
    TimerMode.interval => 'INTERVAL',
  };

  static TimerMode fromJson(String value) => switch (value) {
    'STOPWATCH' => TimerMode.stopwatch,
    'COUNTDOWN' => TimerMode.countdown,
    'LAP_TIMER' => TimerMode.lapTimer,
    'INTERVAL' => TimerMode.interval,
    _ => throw ArgumentError.value(value, 'value', 'Unknown TimerMode'),
  };
}
