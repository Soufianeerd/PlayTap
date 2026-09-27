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
  sessionCompleted,

  /// Generic, sport-agnostic per-segment service-order override — see
  /// `RacketEngine`'s "Doubles service order" section. A "segment" is a
  /// set index (0-based `RacketMatchState.currentSetIndex`), including the
  /// Match Tie-break (which shares its deciding set's index, since it
  /// replaces that set entirely rather than following it). Deliberately
  /// not `TENNIS_...`-prefixed: Padel/Table Tennis/Badminton will reuse
  /// this same event unchanged (CLAUDE.md brief section 5/24).
  serviceOrderConfigured;

  String toJson() => switch (this) {
    RacketEngineEventType.pointScored => 'POINT_SCORED',
    RacketEngineEventType.undo => 'UNDO',
    RacketEngineEventType.sessionCompleted => 'SESSION_COMPLETED',
    RacketEngineEventType.serviceOrderConfigured => 'SERVICE_ORDER_CONFIGURED',
  };

  static RacketEngineEventType? tryFromJson(String value) => switch (value) {
    'POINT_SCORED' => RacketEngineEventType.pointScored,
    'UNDO' => RacketEngineEventType.undo,
    'SESSION_COMPLETED' => RacketEngineEventType.sessionCompleted,
    'SERVICE_ORDER_CONFIGURED' => RacketEngineEventType.serviceOrderConfigured,
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
