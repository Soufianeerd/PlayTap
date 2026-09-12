import '../models/origin_device.dart';
import 'score_engine_event.dart';

/// Full set of event types persisted for a session — a superset of
/// [ScoreEngineEventType] that also covers lifecycle markers. Lifecycle
/// events are still part of the append-only log (so the log alone fully
/// describes what happened to a session), but the Score Engine itself only
/// ever consumes the `ScoreEngineEventType` subset — see
/// `toScoreEngineEvent`.
enum SessionEventType {
  sessionStarted,
  pointScored,
  undo,
  sessionCompleted,
  sessionAbandoned;

  String toJson() => switch (this) {
    SessionEventType.sessionStarted => 'SESSION_STARTED',
    SessionEventType.pointScored => 'POINT_SCORED',
    SessionEventType.undo => 'UNDO',
    SessionEventType.sessionCompleted => 'SESSION_COMPLETED',
    SessionEventType.sessionAbandoned => 'SESSION_ABANDONED',
  };

  static SessionEventType fromJson(String value) => switch (value) {
    'SESSION_STARTED' => SessionEventType.sessionStarted,
    'POINT_SCORED' => SessionEventType.pointScored,
    'UNDO' => SessionEventType.undo,
    'SESSION_COMPLETED' => SessionEventType.sessionCompleted,
    'SESSION_ABANDONED' => SessionEventType.sessionAbandoned,
    _ => throw ArgumentError.value(value, 'value', 'Unknown SessionEventType'),
  };
}

/// A persisted, immutable event — the source of truth for session state
/// (see `playtap-score-engine`, docs/DATA_MODEL.md). Never mutated once
/// written.
class SessionEvent {
  const SessionEvent({
    required this.id,
    required this.sessionId,
    required this.type,
    required this.payload,
    required this.timestamp,
    required this.originDevice,
    required this.originSequence,
  });

  final String id;
  final String sessionId;
  final SessionEventType type;
  final Map<String, dynamic> payload;
  final DateTime timestamp;
  final OriginDevice originDevice;
  final int originSequence;

  /// Converts to the pure shape `ScoreEngine.replay` accepts, or null for
  /// lifecycle events the engine doesn't need to see (SESSION_STARTED,
  /// SESSION_ABANDONED).
  ScoreEngineEvent? toScoreEngineEvent() {
    final engineType = ScoreEngineEventType.tryFromJson(type.toJson());
    if (engineType == null) return null;
    return ScoreEngineEvent(id: id, type: engineType, payload: payload);
  }
}
