import 'racket_rule.dart';
import 'racket_state.dart';
import 'scoring_side.dart';
import 'session_status.dart';

/// A fully-resolved Racket (Tennis, and later Padel/Table Tennis/
/// Badminton) session — sides + derived match state, ready for the UI.
/// Mirrors `ScoreSessionSnapshot`/`MatchSessionSnapshot`'s exact shape
/// (see `domain/engines/racket_session_deriver.dart`).
class RacketSessionSnapshot {
  const RacketSessionSnapshot({
    required this.sides,
    required this.racketRule,
    required this.matchState,
    required this.status,
    required this.startedAt,
    required this.endedAt,
  });

  final List<ScoringSide> sides;

  /// The rule actually persisted in `SESSION_STARTED` — never recomputed
  /// from transient config-screen state, which doesn't survive recovery
  /// (see the note on `ScoreSessionSnapshot.scoreRule`).
  final RacketMatchRule racketRule;

  final RacketMatchState matchState;
  final SessionStatus status;
  final DateTime startedAt;
  final DateTime? endedAt;

  /// True once any point has visibly moved the match away from its
  /// opening state (0-0, first set, no completed sets) — `appliedEventCount`
  /// alone can't tell "nothing left to undo" apart from "some points
  /// undone, more remain" (it counts every point ever accepted, including
  /// undone ones — see `RacketMatchState.appliedEventCount`), so this
  /// checks the current derived state directly instead, mirroring
  /// `ScoreSessionSnapshot.isUndoAvailable`.
  bool get isUndoAvailable => !_atOpeningState;

  bool get _atOpeningState =>
      matchState.currentSetIndex == 0 &&
      matchState.completedSets.isEmpty &&
      !matchState.isTieBreak &&
      !matchState.isMatchTieBreak &&
      matchState.currentGamePoints.values.every((v) => v == 0) &&
      matchState.gamesWonInCurrentSet.values.every((v) => v == 0);
}
