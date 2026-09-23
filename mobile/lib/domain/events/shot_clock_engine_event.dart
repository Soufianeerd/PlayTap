/// The subset of event types `ShotClockEngine` itself understands.
enum ShotClockEngineEventType {
  started,
  paused,
  reset,
  completed,
  undo;

  static ShotClockEngineEventType? tryFromJson(String value) => switch (value) {
    'SHOT_CLOCK_STARTED' => ShotClockEngineEventType.started,
    'SHOT_CLOCK_PAUSED' => ShotClockEngineEventType.paused,
    'SHOT_CLOCK_RESET' => ShotClockEngineEventType.reset,
    'SHOT_CLOCK_COMPLETED' => ShotClockEngineEventType.completed,
    'UNDO' => ShotClockEngineEventType.undo,
    _ => null,
  };
}

/// Pure input to `ShotClockEngine.replay` — see `MatchEngineEvent`'s
/// equivalent doc note. `reset`'s payload is `{durationMs}`.
class ShotClockEngineEvent {
  const ShotClockEngineEvent({
    required this.id,
    required this.type,
    required this.atMs,
    required this.payload,
  });

  final String id;
  final ShotClockEngineEventType type;
  final int atMs;
  final Map<String, dynamic> payload;
}
