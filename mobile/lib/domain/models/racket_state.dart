import 'package:meta/meta.dart';

/// One completed set's result — see `RacketMatchState.completedSets`. When
/// [isMatchTieBreak] is true, this entry represents a Match Tie-Break that
/// replaced the entire deciding set ([MatchTieBreakDecidingSet]): [games]
/// is then always `{side: 0, ...}` (no games were played) and
/// [tieBreakScore] carries the 10-point score instead — kept as its own
/// flag rather than inferred from score shape so the UI/summary never has
/// to guess ("10-8" must read as a Match Tie-Break, not a 10-8 set).
@immutable
class RacketSetResult {
  const RacketSetResult({
    required this.games,
    this.tieBreakScore,
    this.isMatchTieBreak = false,
  });

  final Map<String, int> games;

  /// Present when this set was decided by a tie-break (set tie-break at
  /// e.g. 7-6, or the Match Tie-Break itself when [isMatchTieBreak]).
  final Map<String, int>? tieBreakScore;

  final bool isMatchTieBreak;

  Map<String, dynamic> toJson() => {
    'games': games,
    if (tieBreakScore != null) 'tieBreakScore': tieBreakScore,
    'isMatchTieBreak': isMatchTieBreak,
  };

  @override
  bool operator ==(Object other) =>
      other is RacketSetResult &&
      isMatchTieBreak == other.isMatchTieBreak &&
      _mapEquals(games, other.games) &&
      _mapEquals(tieBreakScore, other.tieBreakScore);

  @override
  int get hashCode => Object.hash(
    isMatchTieBreak,
    Object.hashAllUnordered(
      games.entries.map((e) => Object.hash(e.key, e.value)),
    ),
    tieBreakScore == null
        ? 0
        : Object.hashAllUnordered(
            tieBreakScore!.entries.map((e) => Object.hash(e.key, e.value)),
          ),
  );

  static bool _mapEquals(Map<String, int>? a, Map<String, int>? b) {
    if (a == null || b == null) return a == b;
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }
}

/// Output of `RacketEngine.replay` — see `playtap-score-engine` and
/// docs/DATA_MODEL.md. Always derived, never a second source of truth:
/// games/sets/match are projections over the `POINT_SCORED` log, never
/// separately persisted (CLAUDE.md brief section 15).
@immutable
class RacketMatchState {
  const RacketMatchState({
    required this.currentGamePoints,
    required this.gamesWonInCurrentSet,
    required this.setsWon,
    required this.completedSets,
    required this.currentSetIndex,
    required this.isTieBreak,
    required this.isMatchTieBreak,
    required this.tieBreakPoints,
    required this.currentServerSlotId,
    required this.matchComplete,
    required this.winner,
    required this.appliedEventCount,
    required this.changeEndsDue,
  });

  /// Raw per-side point counters for the game in progress — 0,1,2,3,4...
  /// Never the display label ("15"/"30"/"40"/"Deuce"/"Advantage"); see
  /// `RacketLabels.pointLabel`. Meaningless (left at 0) while
  /// [isTieBreak]/[isMatchTieBreak] is true — see [tieBreakPoints] instead.
  final Map<String, int> currentGamePoints;

  final Map<String, int> gamesWonInCurrentSet;

  final Map<String, int> setsWon;

  /// Every set decided so far, in order — see [RacketSetResult].
  final List<RacketSetResult> completedSets;

  final int currentSetIndex;

  /// True during a standard set tie-break (6-6 in games).
  final bool isTieBreak;

  /// True during a Match Tie-Break replacing the entire deciding set (see
  /// [MatchTieBreakDecidingSet]) — mutually exclusive with [isTieBreak].
  final bool isMatchTieBreak;

  /// Raw per-side point counters for the tie-break in progress — only
  /// meaningful while [isTieBreak] or [isMatchTieBreak] is true.
  final Map<String, int> tieBreakPoints;

  /// The [ServiceSlot.id] (see `racket_rule.dart`) whose turn it is to
  /// serve the point about to be played — resolved from the persisted
  /// [ServiceRule.order] plus the number of games/tie-break points played
  /// so far, never guessed from UI state.
  final String currentServerSlotId;

  final bool matchComplete;

  /// Side id with strictly more sets won once [matchComplete] is true;
  /// null while running. A retirement (`SESSION_COMPLETED` with no side
  /// having won enough sets) can leave this null even once complete — see
  /// `RacketEngine`.
  final String? winner;

  /// Count of valid `POINT_SCORED` events applied while the match was not
  /// yet complete (mirrors `ScoreState.appliedEventCount` exactly — see
  /// its doc for the undo/duplicate/invalid-payload semantics).
  final int appliedEventCount;

  /// Non-blocking "changer de côté" indicator (CLAUDE.md brief section
  /// 14) — purely a UI hint, never a gate on scoring. Odd total games
  /// played in the match so far outside a tie-break, or a positive
  /// multiple of 6 tie-break points while [isTieBreak]/[isMatchTieBreak] —
  /// ITF Rule 6 (Change of Ends).
  final bool changeEndsDue;

  Map<String, dynamic> toJson() => {
    'currentGamePoints': currentGamePoints,
    'gamesWonInCurrentSet': gamesWonInCurrentSet,
    'setsWon': setsWon,
    'completedSets': completedSets.map((s) => s.toJson()).toList(),
    'currentSetIndex': currentSetIndex,
    'isTieBreak': isTieBreak,
    'isMatchTieBreak': isMatchTieBreak,
    'tieBreakPoints': tieBreakPoints,
    'currentServerSlotId': currentServerSlotId,
    'matchComplete': matchComplete,
    'winner': winner,
    'appliedEventCount': appliedEventCount,
    'changeEndsDue': changeEndsDue,
  };
}
