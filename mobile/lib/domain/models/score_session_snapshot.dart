import 'score_rule.dart';
import 'score_state.dart';
import 'scoring_side.dart';
import 'session_status.dart';

/// A fully-resolved Score session — sides + derived score, ready for the
/// UI. Generic across every `ScoreRule` mode (Score Libre, Pétanque, and
/// future presets): shared between each mode's active-session controller
/// and History (see `domain/engines/score_session_deriver.dart`), so there
/// is exactly one place that turns (Session, Events) into this shape —
/// never a per-sport duplicate.
class ScoreSessionSnapshot {
  const ScoreSessionSnapshot({
    required this.sides,
    required this.scoreRule,
    required this.scoreState,
    required this.status,
    required this.startedAt,
    required this.endedAt,
  });

  final List<ScoringSide> sides;

  /// The rule actually persisted in `SESSION_STARTED` — the single source
  /// of truth for what this session allows (e.g. which increments a
  /// `TeamScoreRule` accepts). UI must read config like allowed increments
  /// from here, never recompute a parallel rule from config-screen state:
  /// that state doesn't survive recovery and can drift from what was
  /// actually persisted (see the Pétanque tête-à-tête review, 2026-09-22).
  final ScoreRule scoreRule;
  final ScoreState scoreState;
  final SessionStatus status;
  final DateTime startedAt;
  final DateTime? endedAt;

  bool get isUndoAvailable => scoreState.scores.values.any((v) => v > 0);
}
