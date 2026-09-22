import '../events/score_engine_event.dart';
import '../events/session_event.dart';
import '../models/score_rule.dart';
import '../models/score_session_snapshot.dart';
import '../models/scoring_side.dart';
import '../models/session_status.dart';
import 'score_engine.dart';

/// Turns a session's persisted event log into a [ScoreSessionSnapshot] —
/// the one place that knows how to read a `SESSION_STARTED` payload and
/// replay the rest through [ScoreEngine]. Pure: no I/O, same inputs always
/// produce the same snapshot (see `playtap-score-engine` — "Déterminisme").
/// Sport-agnostic: `ScoreRule.fromJson` dispatches on the persisted mode, so
/// this one function already serves Score Libre, Pétanque, and every future
/// Score preset — never duplicated per sport.
ScoreSessionSnapshot deriveScoreSessionSnapshot({
  required SessionStatus status,
  required DateTime startedAt,
  required DateTime? endedAt,
  required List<SessionEvent> events,
}) {
  final startedEvent = events.firstWhere(
    (e) => e.type == SessionEventType.sessionStarted,
    orElse: () => throw StateError('Session has no SESSION_STARTED event'),
  );

  final sides = (startedEvent.payload['sides'] as List)
      .cast<Map<String, dynamic>>()
      .map(ScoringSide.fromJson)
      .toList();
  final rule = ScoreRule.fromJson(
    startedEvent.payload['scoreRule'] as Map<String, dynamic>,
  );

  final engineEvents = events
      .map((e) => e.toScoreEngineEvent())
      .whereType<ScoreEngineEvent>()
      .toList();

  return ScoreSessionSnapshot(
    sides: sides,
    scoreRule: rule,
    scoreState: ScoreEngine.replay(rule, engineEvents),
    status: status,
    startedAt: startedAt,
    endedAt: endedAt,
  );
}
