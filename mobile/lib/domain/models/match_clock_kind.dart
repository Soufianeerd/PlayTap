/// How a sport's period clock behaves — the one fact that distinguishes a
/// Basketball/Futsal period clock from a Football one, expressed as data
/// so `MatchEngine` never branches on sport identity (see `MatchRule`).
enum MatchClockKind {
  /// The clock counts up continuously while play is on and can exceed the
  /// period's nominal duration (Football: 45+3) — added time is announced,
  /// never auto-computed, and the period only ends via an explicit
  /// `PERIOD_ENDED` (referee's whistle), never automatically.
  runningClock,

  /// The clock counts down from the period duration to zero and is
  /// explicitly paused/resumed by the app (Basketball, Futsal) — reaching
  /// zero auto-completes the period, exactly like a COUNTDOWN Timer.
  stoppedClock;

  String toJson() => switch (this) {
    MatchClockKind.runningClock => 'RUNNING_CLOCK',
    MatchClockKind.stoppedClock => 'STOPPED_CLOCK',
  };

  static MatchClockKind fromJson(String value) => switch (value) {
    'RUNNING_CLOCK' => MatchClockKind.runningClock,
    'STOPPED_CLOCK' => MatchClockKind.stoppedClock,
    _ => throw ArgumentError.value(value, 'value', 'Unknown MatchClockKind'),
  };
}
