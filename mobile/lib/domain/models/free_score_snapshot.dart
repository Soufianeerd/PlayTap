import 'score_state.dart';
import 'scoring_side.dart';
import 'session_status.dart';

/// A fully-resolved Score Libre session — sides + derived score, ready for
/// the UI. Shared between the active-session controller and History (see
/// `domain/engines/free_score_deriver.dart`), so there is exactly one place
/// that turns (Session, Events) into this shape.
class FreeScoreSnapshot {
  const FreeScoreSnapshot({
    required this.sides,
    required this.scoreState,
    required this.status,
    required this.startedAt,
    required this.endedAt,
  });

  final List<ScoringSide> sides;
  final ScoreState scoreState;
  final SessionStatus status;
  final DateTime startedAt;
  final DateTime? endedAt;

  bool get isUndoAvailable => scoreState.scores.values.any((v) => v > 0);
}
