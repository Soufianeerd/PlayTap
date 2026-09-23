import '../models/origin_device.dart';
import 'match_engine_event.dart';
import 'score_engine_event.dart';
import 'shootout_engine_event.dart';
import 'shot_clock_engine_event.dart';
import 'team_foul_engine_event.dart';
import 'timeout_engine_event.dart';
import 'timer_engine_event.dart';

/// Full set of event types persisted for a session — a superset of
/// [ScoreEngineEventType]/[TimerEngineEventType]/[MatchEngineEventType]/
/// [ShootoutEngineEventType] that also covers lifecycle markers shared
/// across categories. Lifecycle events are still part of the append-only
/// log (so the log alone fully describes what happened to a session), but
/// each pure engine only ever consumes its own subset — see
/// `toScoreEngineEvent`/`toTimerEngineEvent`/`toMatchEngineEvent`/
/// `toShootoutEngineEvent`.
///
/// Team-match additions (Basketball/Football/Futsal — see
/// `playtap-score-engine`'s `MatchRule` composition note) stay generic on
/// purpose: no `BASKETBALL_POINT`/`FOOTBALL_GOAL`/`FUTSAL_GOAL`, and
/// overtime reuses [periodStarted]'s payload (`kind: OVERTIME`) rather
/// than a separate `OVERTIME_STARTED` type. Reused unchanged for the same
/// real-world meaning: [sessionStarted] (match start), [pointScored]/
/// [undo] (scoring), [sessionCompleted] (match end — decided, drawn, or
/// resolved by shootout), [timerStarted]/[timerPaused]/[timerResumed]/
/// [timerCompleted] (the match clock's start/pause/resume/period-expiry —
/// paired with [periodStarted]/[periodEnded], see
/// `features/score_team_match/team_match_actions.dart`).
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
  timerCompleted,
  periodStarted,
  periodEnded,
  addedTimeAnnounced,
  shootoutStarted,
  shootoutAttempt,
  shootoutCompleted,
  shotClockStarted,
  shotClockPaused,
  shotClockReset,
  shotClockCompleted,
  timeoutTaken,
  teamFoulAdded;

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
    SessionEventType.periodStarted => 'PERIOD_STARTED',
    SessionEventType.periodEnded => 'PERIOD_ENDED',
    SessionEventType.addedTimeAnnounced => 'ADDED_TIME_ANNOUNCED',
    SessionEventType.shootoutStarted => 'SHOOTOUT_STARTED',
    SessionEventType.shootoutAttempt => 'SHOOTOUT_ATTEMPT',
    SessionEventType.shootoutCompleted => 'SHOOTOUT_COMPLETED',
    SessionEventType.shotClockStarted => 'SHOT_CLOCK_STARTED',
    SessionEventType.shotClockPaused => 'SHOT_CLOCK_PAUSED',
    SessionEventType.shotClockReset => 'SHOT_CLOCK_RESET',
    SessionEventType.shotClockCompleted => 'SHOT_CLOCK_COMPLETED',
    SessionEventType.timeoutTaken => 'TIMEOUT_TAKEN',
    SessionEventType.teamFoulAdded => 'TEAM_FOUL_ADDED',
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
    'PERIOD_STARTED' => SessionEventType.periodStarted,
    'PERIOD_ENDED' => SessionEventType.periodEnded,
    'ADDED_TIME_ANNOUNCED' => SessionEventType.addedTimeAnnounced,
    'SHOOTOUT_STARTED' => SessionEventType.shootoutStarted,
    'SHOOTOUT_ATTEMPT' => SessionEventType.shootoutAttempt,
    'SHOOTOUT_COMPLETED' => SessionEventType.shootoutCompleted,
    'SHOT_CLOCK_STARTED' => SessionEventType.shotClockStarted,
    'SHOT_CLOCK_PAUSED' => SessionEventType.shotClockPaused,
    'SHOT_CLOCK_RESET' => SessionEventType.shotClockReset,
    'SHOT_CLOCK_COMPLETED' => SessionEventType.shotClockCompleted,
    'TIMEOUT_TAKEN' => SessionEventType.timeoutTaken,
    'TEAM_FOUL_ADDED' => SessionEventType.teamFoulAdded,
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

  /// Converts to the pure shape `MatchEngine.replay` accepts, or null for
  /// events the Match Engine doesn't need to see (`SESSION_STARTED`,
  /// `POINT_SCORED`, `SESSION_ABANDONED`, `LAP_RECORDED`,
  /// `SHOOTOUT_ATTEMPT`) — see `domain/engines/match_engine.dart`.
  MatchEngineEvent? toMatchEngineEvent() {
    final engineType = MatchEngineEventType.tryFromJson(type.toJson());
    if (engineType == null) return null;
    return MatchEngineEvent(
      id: id,
      type: engineType,
      atMs: timestamp.millisecondsSinceEpoch,
      payload: payload,
    );
  }

  /// Converts to the pure shape `ShootoutEngine.replay` accepts, or null
  /// for events the Shootout Engine doesn't need to see — see
  /// `domain/engines/shootout_engine.dart`.
  ShootoutEngineEvent? toShootoutEngineEvent() {
    final engineType = ShootoutEngineEventType.tryFromJson(type.toJson());
    if (engineType == null) return null;
    return ShootoutEngineEvent(id: id, type: engineType, payload: payload);
  }

  /// Converts to the pure shape `ShotClockEngine.replay` accepts, or null
  /// for events the Shot Clock Engine doesn't need to see — see
  /// `domain/engines/shot_clock_engine.dart`.
  ShotClockEngineEvent? toShotClockEngineEvent() {
    final engineType = ShotClockEngineEventType.tryFromJson(type.toJson());
    if (engineType == null) return null;
    return ShotClockEngineEvent(
      id: id,
      type: engineType,
      atMs: timestamp.millisecondsSinceEpoch,
      payload: payload,
    );
  }

  /// Converts to the pure shape `TimeoutEngine.replay` accepts, or null
  /// for events the Timeout Engine doesn't need to see — see
  /// `domain/engines/timeout_engine.dart`.
  TimeoutEngineEvent? toTimeoutEngineEvent() {
    final engineType = TimeoutEngineEventType.tryFromJson(type.toJson());
    if (engineType == null) return null;
    return TimeoutEngineEvent(id: id, type: engineType, payload: payload);
  }

  /// Converts to the pure shape `TeamFoulEngine.replay` accepts, or null
  /// for events the Team Foul Engine doesn't need to see — see
  /// `domain/engines/team_foul_engine.dart`.
  TeamFoulEngineEvent? toTeamFoulEngineEvent() {
    final engineType = TeamFoulEngineEventType.tryFromJson(type.toJson());
    if (engineType == null) return null;
    return TeamFoulEngineEvent(id: id, type: engineType, payload: payload);
  }
}
