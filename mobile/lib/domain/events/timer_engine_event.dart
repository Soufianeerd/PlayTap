/// The subset of event types the Timer Engine itself understands. Naming
/// matches the existing `/contracts/timer` fixtures exactly (`TIMER_*`) —
/// see docs/CONFORMANCE.md. `SESSION_COMPLETED` also maps to [completed]:
/// it's how a STOPWATCH/LAP_TIMER session ends (no natural target), while
/// `TIMER_COMPLETED` is how a COUNTDOWN ends on its own — see
/// `domain/engines/timer_engine.dart`.
enum TimerEngineEventType {
  started,
  paused,
  resumed,
  lapRecorded,
  completed;

  static TimerEngineEventType? tryFromJson(String value) => switch (value) {
    'TIMER_STARTED' => TimerEngineEventType.started,
    'TIMER_PAUSED' => TimerEngineEventType.paused,
    'TIMER_RESUMED' => TimerEngineEventType.resumed,
    'LAP_RECORDED' => TimerEngineEventType.lapRecorded,
    'TIMER_COMPLETED' => TimerEngineEventType.completed,
    'SESSION_COMPLETED' => TimerEngineEventType.completed,
    _ => null,
  };
}

/// Pure input to `TimerEngine.replay` — stripped of envelope fields
/// (sessionId, originDevice) the engine must never depend on. [atMs] is
/// this event's own moment, in the same millisecond timeline as the `now`
/// passed to `replay` (see `playtap-timer-engine` — both are wall-clock
/// milliseconds when replaying persisted events for recovery/history).
class TimerEngineEvent {
  const TimerEngineEvent({
    required this.id,
    required this.type,
    required this.atMs,
  });

  final String id;
  final TimerEngineEventType type;
  final int atMs;
}
