/// The subset of event types `ShootoutEngine` itself understands.
enum ShootoutEngineEventType {
  shootoutStarted,
  shootoutAttempt,
  undo,
  shootoutCompleted;

  static ShootoutEngineEventType? tryFromJson(String value) => switch (value) {
    'SHOOTOUT_STARTED' => ShootoutEngineEventType.shootoutStarted,
    'SHOOTOUT_ATTEMPT' => ShootoutEngineEventType.shootoutAttempt,
    'UNDO' => ShootoutEngineEventType.undo,
    'SHOOTOUT_COMPLETED' => ShootoutEngineEventType.shootoutCompleted,
    _ => null,
  };
}

/// Pure input to `ShootoutEngine.replay` — see `MatchEngineEvent`'s
/// equivalent doc note. `shootoutAttempt`'s payload is `{side, scored}`.
class ShootoutEngineEvent {
  const ShootoutEngineEvent({
    required this.id,
    required this.type,
    required this.payload,
  });

  final String id;
  final ShootoutEngineEventType type;
  final Map<String, dynamic> payload;
}
