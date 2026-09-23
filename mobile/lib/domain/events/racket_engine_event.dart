/// The subset of event types `RacketEngine` itself understands — reuses
/// exactly the same three real-world meanings as `ScoreEngineEventType`
/// (`POINT_SCORED`/`UNDO`/`SESSION_COMPLETED`, see CLAUDE.md brief section
/// 15: "réutiliser autant que possible"), kept as Racket Core's own type
/// for the same reason every other engine has one (`MatchEngineEvent`,
/// `ShootoutEngineEvent`, ...) — each pure engine only ever depends on its
/// own event shape, never another engine's.
enum RacketEngineEventType {
  pointScored,
  undo,
  sessionCompleted;

  String toJson() => switch (this) {
    RacketEngineEventType.pointScored => 'POINT_SCORED',
    RacketEngineEventType.undo => 'UNDO',
    RacketEngineEventType.sessionCompleted => 'SESSION_COMPLETED',
  };

  static RacketEngineEventType? tryFromJson(String value) => switch (value) {
    'POINT_SCORED' => RacketEngineEventType.pointScored,
    'UNDO' => RacketEngineEventType.undo,
    'SESSION_COMPLETED' => RacketEngineEventType.sessionCompleted,
    _ => null,
  };
}

/// Pure input to `RacketEngine.replay` — see `ScoreEngineEvent`'s doc for
/// why envelope fields (sessionId, originDevice, timestamp) are
/// deliberately excluded.
class RacketEngineEvent {
  const RacketEngineEvent({
    required this.id,
    required this.type,
    required this.payload,
  });

  final String id;
  final RacketEngineEventType type;
  final Map<String, dynamic> payload;
}
