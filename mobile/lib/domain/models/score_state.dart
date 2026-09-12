import 'package:meta/meta.dart';

/// Output of `ScoreEngine.replay` — always derived, never stored as a
/// second source of truth (see `playtap-score-engine`, DATA_MODEL.md).
@immutable
class ScoreState {
  const ScoreState({
    required this.scores,
    required this.matchComplete,
    required this.winner,
    required this.appliedEventCount,
  });

  /// Score per side id. Every configured side is present, even at 0.
  final Map<String, int> scores;

  final bool matchComplete;

  /// Side id with the strictly highest score once `matchComplete` is true;
  /// null while running, and null on a tie (no forced winner for FREE_SCORE).
  final String? winner;

  /// Count of valid `POINT_SCORED` events applied (regardless of whether
  /// a later undo removed their contribution) — excludes duplicates and
  /// unknown-side/invalid-amount points. `UNDO`/`SESSION_COMPLETED` never
  /// change this count. Mirrors `appliedEventCount` in the conformance
  /// fixtures (see contracts/score/free_score_basic.json).
  final int appliedEventCount;

  Map<String, dynamic> toJson() => {
    'scores': scores,
    'matchComplete': matchComplete,
    'winner': winner,
    'appliedEventCount': appliedEventCount,
  };

  @override
  bool operator ==(Object other) =>
      other is ScoreState &&
      matchComplete == other.matchComplete &&
      winner == other.winner &&
      appliedEventCount == other.appliedEventCount &&
      _mapEquals(scores, other.scores);

  @override
  int get hashCode => Object.hash(
    matchComplete,
    winner,
    appliedEventCount,
    Object.hashAllUnordered(
      scores.entries.map((e) => Object.hash(e.key, e.value)),
    ),
  );

  static bool _mapEquals(Map<String, int> a, Map<String, int> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }
}
