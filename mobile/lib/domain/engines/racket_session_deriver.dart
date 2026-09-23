import '../events/racket_engine_event.dart';
import '../events/session_event.dart';
import '../models/racket_rule.dart';
import '../models/racket_session_snapshot.dart';
import '../models/scoring_side.dart';
import '../models/session_status.dart';
import 'racket_engine.dart';

/// Turns a Tennis (and later Padel/Table Tennis/Badminton) session's
/// persisted event log into a [RacketSessionSnapshot] — mirrors
/// `deriveScoreSessionSnapshot`'s exact shape. Pure: no I/O, same inputs
/// always produce the same snapshot.
RacketSessionSnapshot deriveRacketSessionSnapshot({
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
  final rule = RacketMatchRule.fromJson(
    (startedEvent.payload['racketRule'] as Map).cast<String, dynamic>(),
  );

  final engineEvents = events
      .map(_toRacketEngineEvent)
      .whereType<RacketEngineEvent>()
      .toList();

  return RacketSessionSnapshot(
    sides: sides,
    racketRule: rule,
    matchState: RacketEngine.replay(rule, engineEvents),
    status: status,
    startedAt: startedAt,
    endedAt: endedAt,
  );
}

/// Converts a persisted [SessionEvent] to the pure shape `RacketEngine.
/// replay` accepts, or null for events Racket Core doesn't need to see —
/// mirrors `SessionEvent.toScoreEngineEvent`.
RacketEngineEvent? _toRacketEngineEvent(SessionEvent event) {
  final engineType = RacketEngineEventType.tryFromJson(event.type.toJson());
  if (engineType == null) return null;
  return RacketEngineEvent(
    id: event.id,
    type: engineType,
    payload: event.payload,
  );
}
