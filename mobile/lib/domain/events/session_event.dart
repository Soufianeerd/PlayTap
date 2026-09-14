import '../models/origin_device.dart';
import 'score_engine_event.dart';
import 'timer_engine_event.dart';

/// Full set of event types persisted for a session — a superset of
/// [ScoreEngineEventType]/[TimerEngineEventType] that also covers
/// lifecycle markers shared across categories. Lifecycle events are still
/// part of the append-only log (so the log alone fully describes what
/// happened to a session), but each pure engine only ever consumes its own
/// subset — see `toScoreEngineEvent`/`toTimerEngineEvent`.
enum SessionEventType {
  sessionStarted,
  pointScored,
  undo,
  sessionCompleted,
  sessionAbandoned,
  timerStarted,
  timerPaused,
  timerResumed,
  lapRecorded,
  timerCompleted;

  String toJson() => switch (this) {
    SessionEventType.sessionStarted => 'SESSION_STARTED',
    SessionEventType.pointScored => 'POINT_SCORED',
    SessionEventType.undo => 'UNDO',
    SessionEventType.sessionCompleted => 'SESSION_COMPLETED',
    SessionEventType.sessionAbandoned => 'SESSION_ABANDONED',
    SessionEventType.timerStarted => 'TIMER_STARTED',
    SessionEventType.timerPaused => 'TIMER_PAUSED',
    SessionEventType.timerResumed => 'TIMER_RESUMED',
    SessionEventType.lapRecorded => 'LAP_RECORDED',
    SessionEventType.timerCompleted => 'TIMER_COMPLETED',
  };

  static SessionEventType fromJson(String value) => switch (value) {
    'SESSION_STARTED' => SessionEventType.sessionStarted,
    'POINT_SCORED' => SessionEventType.pointScored,
    'UNDO' => SessionEventType.undo,
    'SESSION_COMPLETED' => SessionEventType.sessionCompleted,
    'SESSION_ABANDONED' => SessionEventType.sessionAbandoned,
    'TIMER_STARTED' => SessionEventType.timerStarted,
    'TIMER_PAUSED' => SessionEventType.timerPaused,
    'TIMER_RESUMED' => SessionEventType.timerResumed,
    'LAP_RECORDED' => SessionEventType.lapRecorded,
    'TIMER_COMPLETED' => SessionEventType.timerCompleted,
    _ => throw ArgumentError.value(value, 'value', 'Unknown SessionEventType'),
  };
}

/// A persisted, immutable event — the source of truth for session state
/// (see `playtap-score-engine`, `playtap-timer-engine`, docs/DATA_MODEL.md).
/// Never mutated once written.
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
  /// events the Score Engine doesn't need to see (lifecycle markers, any
  /// Timer-specific type).
  ScoreEngineEvent? toScoreEngineEvent() {
    final engineType = ScoreEngineEventType.tryFromJson(type.toJson());
    if (engineType == null) return null;
    return ScoreEngineEvent(id: id, type: engineType, payload: payload);
  }

  /// Converts to the pure shape `TimerEngine.replay` accepts, or null for
  /// events the Timer Engine doesn't need to see (`SESSION_STARTED`,
  /// `SESSION_ABANDONED`, any Score-specific type). [atMs] is this event's
  /// wall-clock timestamp in milliseconds — see `playtap-timer-engine`.
  TimerEngineEvent? toTimerEngineEvent() {
    final engineType = TimerEngineEventType.tryFromJson(type.toJson());
    if (engineType == null) return null;
    return TimerEngineEvent(
      id: id,
      type: engineType,
      atMs: timestamp.millisecondsSinceEpoch,
    );
  }
}
