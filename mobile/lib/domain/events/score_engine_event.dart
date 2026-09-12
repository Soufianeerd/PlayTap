/// The subset of event types the Score Engine itself understands. Naming
/// matches the existing `/contracts/score` fixtures exactly (e.g. `UNDO`,
/// not `ACTION_UNDONE`) — see docs/CONFORMANCE.md.
enum ScoreEngineEventType {
  pointScored,
  undo,
  sessionCompleted;

  String toJson() => switch (this) {
    ScoreEngineEventType.pointScored => 'POINT_SCORED',
    ScoreEngineEventType.undo => 'UNDO',
    ScoreEngineEventType.sessionCompleted => 'SESSION_COMPLETED',
  };

  static ScoreEngineEventType? tryFromJson(String value) => switch (value) {
    'POINT_SCORED' => ScoreEngineEventType.pointScored,
    'UNDO' => ScoreEngineEventType.undo,
    'SESSION_COMPLETED' => ScoreEngineEventType.sessionCompleted,
    _ => null,
  };
}

/// Pure input to `ScoreEngine.replay` — deliberately stripped of envelope
/// fields (sessionId, originDevice, timestamp) that the engine itself must
/// never depend on (see `playtap-score-engine` — "Déterminisme"). Ordering
/// is the caller's responsibility (see docs/WATCH_SYNC.md).
class ScoreEngineEvent {
  const ScoreEngineEvent({
    required this.id,
    required this.type,
    required this.payload,
  });

  final String id;
  final ScoreEngineEventType type;
  final Map<String, dynamic> payload;
}
