/// The subset of event types `TeamFoulEngine` itself understands. Reuses
/// `PERIOD_STARTED` (from the same log `MatchEngine` also reads) to know
/// when to reset the count — see `TeamFoulRule`'s reset/carry-into-
/// overtime doc note.
enum TeamFoulEngineEventType {
  periodStarted,
  foulAdded,
  undo;

  static TeamFoulEngineEventType? tryFromJson(String value) => switch (value) {
    'PERIOD_STARTED' => TeamFoulEngineEventType.periodStarted,
    'TEAM_FOUL_ADDED' => TeamFoulEngineEventType.foulAdded,
    'UNDO' => TeamFoulEngineEventType.undo,
    _ => null,
  };
}

/// Pure input to `TeamFoulEngine.replay`. `periodStarted`'s payload is
/// `{kind: 'REGULATION'|'OVERTIME'}` (mirrors `MatchEngineEvent`'s
/// identical payload shape); `foulAdded`'s is `{sideId}`.
class TeamFoulEngineEvent {
  const TeamFoulEngineEvent({
    required this.id,
    required this.type,
    required this.payload,
  });

  final String id;
  final TeamFoulEngineEventType type;
  final Map<String, dynamic> payload;
}
