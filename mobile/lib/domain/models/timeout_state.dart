/// One recorded timeout — carries the match context *at the moment it was
/// taken* (period/overtime/remaining clock), captured by the controller
/// from the live `MatchState` rather than re-derived during replay. This
/// is what lets `TimeoutEngine.replay` stay a plain fold over its own
/// events without needing to replay `MatchState` in lockstep to know
/// "what period was it when this past timeout happened" — see
/// `playtap-score-engine` "Déterminisme".
class TimeoutRecord {
  const TimeoutRecord({
    required this.eventId,
    required this.sideId,
    required this.periodIndex,
    required this.isOvertimePeriod,
    required this.overtimeCount,
    required this.periodRemainingMsAtTime,
  });

  final String eventId;
  final String sideId;
  final int periodIndex;
  final bool isOvertimePeriod;
  final int overtimeCount;
  final int periodRemainingMsAtTime;

  @override
  bool operator ==(Object other) =>
      other is TimeoutRecord &&
      eventId == other.eventId &&
      sideId == other.sideId &&
      periodIndex == other.periodIndex &&
      isOvertimePeriod == other.isOvertimePeriod &&
      overtimeCount == other.overtimeCount &&
      periodRemainingMsAtTime == other.periodRemainingMsAtTime;

  @override
  int get hashCode => Object.hash(
    eventId,
    sideId,
    periodIndex,
    isOvertimePeriod,
    overtimeCount,
    periodRemainingMsAtTime,
  );
}

/// Output of `TimeoutEngine.replay` — every not-yet-undone timeout taken
/// so far. "How many does side X have left *right now*" is a separate
/// query (`TimeoutEngine.remainingForSide`) against the *current* match
/// context, not baked into this state — mirrors `MatchEngine.
/// decideNextPhase` taking current state as a separate input rather than
/// folding "now" into `replay`.
class TimeoutState {
  const TimeoutState({required this.records});

  final List<TimeoutRecord> records;
}
