/// Pure engine status — see `playtap-timer-engine`. Distinct from
/// [SessionStatus] (the session's own lifecycle column): a session can be
/// `ACTIVE` while its timer is `paused`, for example.
enum TimerStatus {
  running,
  paused,
  completed;

  String toJson() => switch (this) {
    TimerStatus.running => 'RUNNING',
    TimerStatus.paused => 'PAUSED',
    TimerStatus.completed => 'COMPLETED',
  };
}
