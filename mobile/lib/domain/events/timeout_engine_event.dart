/// The subset of event types `TimeoutEngine` itself understands.
enum TimeoutEngineEventType {
  taken,
  undo;

  static TimeoutEngineEventType? tryFromJson(String value) => switch (value) {
    'TIMEOUT_TAKEN' => TimeoutEngineEventType.taken,
    'UNDO' => TimeoutEngineEventType.undo,
    _ => null,
  };
}

/// Pure input to `TimeoutEngine.replay`. `taken`'s payload is
/// `{sideId, periodIndex, isOvertimePeriod, overtimeCount,
/// periodRemainingMsAtTime}` — the match context is captured at the
/// moment the timeout was taken (see `TimeoutRecord`'s doc note), not
/// re-derived from a separate `MatchState` replay.
class TimeoutEngineEvent {
  const TimeoutEngineEvent({
    required this.id,
    required this.type,
    required this.payload,
  });

  final String id;
  final TimeoutEngineEventType type;
  final Map<String, dynamic> payload;
}
