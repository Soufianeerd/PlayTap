/// The subset of event types `MatchEngine` itself understands. Naming
/// matches the persisted `SessionEventType` JSON exactly — see
/// `domain/events/session_event.dart` and docs/CONFORMANCE.md.
enum MatchEngineEventType {
  periodStarted,
  periodEnded,
  addedTimeAnnounced,
  timerStarted,
  timerPaused,
  timerResumed,
  timerCompleted,
  shootoutStarted,
  shootoutCompleted,
  undo,
  sessionCompleted;

  static MatchEngineEventType? tryFromJson(String value) => switch (value) {
    'PERIOD_STARTED' => MatchEngineEventType.periodStarted,
    'PERIOD_ENDED' => MatchEngineEventType.periodEnded,
    'ADDED_TIME_ANNOUNCED' => MatchEngineEventType.addedTimeAnnounced,
    'TIMER_STARTED' => MatchEngineEventType.timerStarted,
    'TIMER_PAUSED' => MatchEngineEventType.timerPaused,
    'TIMER_RESUMED' => MatchEngineEventType.timerResumed,
    'TIMER_COMPLETED' => MatchEngineEventType.timerCompleted,
    'SHOOTOUT_STARTED' => MatchEngineEventType.shootoutStarted,
    'SHOOTOUT_COMPLETED' => MatchEngineEventType.shootoutCompleted,
    'UNDO' => MatchEngineEventType.undo,
    'SESSION_COMPLETED' => MatchEngineEventType.sessionCompleted,
    _ => null,
  };
}

/// Pure input to `MatchEngine.replay` — stripped of envelope fields the
/// engine must never depend on (see `playtap-score-engine` —
/// "Déterminisme"). [atMs] is this event's own moment on the same
/// millisecond timeline as the `nowMs` passed to `replay`. [payload]
/// carries the type-specific fields (e.g. `periodStarted`'s
/// `{periodIndex, kind, overtimeNumber?}`).
class MatchEngineEvent {
  const MatchEngineEvent({
    required this.id,
    required this.type,
    required this.atMs,
    required this.payload,
  });

  final String id;
  final MatchEngineEventType type;
  final int atMs;
  final Map<String, dynamic> payload;
}
