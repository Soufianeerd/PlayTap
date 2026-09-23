import 'match_rule.dart';
import 'match_state.dart';
import 'score_state.dart';
import 'scoring_side.dart';
import 'session_status.dart';
import 'shootout_state.dart';

/// A fully-resolved team-match session — sides + derived score + derived
/// match/clock/period state (+ shootout state once one has started) —
/// ready for the UI. Shared by Basketball/Football/Futsal (see
/// `domain/engines/match_session_deriver.dart`), never duplicated per
/// sport, mirroring how `ScoreSessionSnapshot` already serves every
/// `ScoreRule` mode.
class MatchSessionSnapshot {
  const MatchSessionSnapshot({
    required this.sides,
    required this.matchRule,
    required this.scoreState,
    required this.matchState,
    required this.status,
    required this.startedAt,
    required this.endedAt,
    this.shootoutState,
  });

  final List<ScoringSide> sides;

  /// The rule actually persisted in `SESSION_STARTED` — the single source
  /// of truth for this match's periods/clock/overtime/shootout/increments.
  /// UI must read config from here, never recompute a parallel rule from
  /// config-screen state (see `ScoreSessionSnapshot`'s identical warning —
  /// the same past bug class applies here).
  final MatchRule matchRule;

  final ScoreState scoreState;
  final MatchState matchState;

  /// Null until a `SHOOTOUT_STARTED` event exists in the log.
  final ShootoutState? shootoutState;

  final SessionStatus status;
  final DateTime startedAt;
  final DateTime? endedAt;
}
