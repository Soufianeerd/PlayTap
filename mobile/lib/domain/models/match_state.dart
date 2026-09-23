import 'match_clock_state.dart';

/// Which stage of the match is currently in progress — see `MatchEngine`.
enum MatchPhase {
  regulation,
  overtime,
  shootoutPending,
  shootoutInProgress,
  ended;

  String toJson() => switch (this) {
    MatchPhase.regulation => 'REGULATION',
    MatchPhase.overtime => 'OVERTIME',
    MatchPhase.shootoutPending => 'SHOOTOUT_PENDING',
    MatchPhase.shootoutInProgress => 'SHOOTOUT_IN_PROGRESS',
    MatchPhase.ended => 'ENDED',
  };
}

/// Why a match ended — purely informational (summary display), never
/// re-derived by branching on sport identity; it's a direct record of
/// which branch of `MatchEngine.decideNextPhase` fired.
enum MatchEndReason {
  decidedInRegulation,
  decidedInOvertime,
  decidedByShootout,
  regulationDraw,
}

/// Output of `MatchEngine.replay` — periods/clock/phase state only, never
/// score (that's `ScoreState`, replayed separately and composed alongside
/// this by `deriveMatchSessionSnapshot`) — see `playtap-score-engine` and
/// docs/DATA_MODEL.md.
class MatchState {
  const MatchState({
    required this.phase,
    required this.periodIndex,
    required this.isOvertimePeriod,
    required this.overtimeCount,
    required this.clock,
    required this.matchEnded,
    this.endReason,
    this.announcedAddedTimeMs,
  });

  final MatchPhase phase;

  /// Zero-based ordinal within the current phase — a regulation period
  /// index into `MatchRule.periods`, or an overtime ordinal when
  /// [isOvertimePeriod] is true (see [overtimeCount]).
  final int periodIndex;

  final bool isOvertimePeriod;

  /// How many overtime periods have been played so far (0 while still in
  /// regulation).
  final int overtimeCount;

  final MatchClockState clock;

  final bool matchEnded;

  final MatchEndReason? endReason;

  /// Latest `ADDED_TIME_ANNOUNCED` value for the current period (RUNNING_
  /// CLOCK sports only — the referee's "board up" moment), reset to null
  /// on every `PERIOD_STARTED`. Purely informational: it never changes how
  /// the clock itself is computed (a running clock already free-runs past
  /// the period's nominal duration) — it only lets the UI show "45+3"
  /// instead of a raw minute count, and is kept in the historical record
  /// via the summary. Always null for STOPPED_CLOCK sports.
  final int? announcedAddedTimeMs;

  @override
  bool operator ==(Object other) =>
      other is MatchState &&
      phase == other.phase &&
      periodIndex == other.periodIndex &&
      isOvertimePeriod == other.isOvertimePeriod &&
      overtimeCount == other.overtimeCount &&
      clock == other.clock &&
      matchEnded == other.matchEnded &&
      endReason == other.endReason &&
      announcedAddedTimeMs == other.announcedAddedTimeMs;

  @override
  int get hashCode => Object.hash(
    phase,
    periodIndex,
    isOvertimePeriod,
    overtimeCount,
    clock,
    matchEnded,
    endReason,
    announcedAddedTimeMs,
  );
}
