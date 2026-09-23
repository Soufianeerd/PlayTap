import 'match_engine.dart';
import 'score_engine.dart';
import 'shootout_engine.dart';
import 'shot_clock_engine.dart';
import 'team_foul_engine.dart';
import 'timeout_engine.dart';
import '../events/match_engine_event.dart';
import '../events/score_engine_event.dart';
import '../events/session_event.dart';
import '../events/shootout_engine_event.dart';
import '../events/shot_clock_engine_event.dart';
import '../events/team_foul_engine_event.dart';
import '../events/timeout_engine_event.dart';
import '../models/match_rule.dart';
import '../models/match_session_snapshot.dart';
import '../models/scoring_side.dart';
import '../models/session_status.dart';
import '../models/shootout_state.dart';
import '../models/shot_clock_state.dart';
import '../models/team_foul_state.dart';
import '../models/timeout_state.dart';

/// Turns a team-match session's persisted event log into a
/// [MatchSessionSnapshot] — the first deriver in the codebase composing
/// more than one engine: reads `SESSION_STARTED`'s payload for **both**
/// `scoreRule` and `matchRule`, replays `ScoreEngine` + `MatchEngine` from
/// the same log, and — only once a `SHOOTOUT_STARTED` event exists —
/// additionally replays `ShootoutEngine`. Pure: no I/O, mirrors
/// `deriveScoreSessionSnapshot`/`deriveTimerSnapshot`'s exact shape.
/// Sport-agnostic: Basketball/Football/Futsal all resolve through this one
/// function, keyed only by what's actually persisted in `matchRule`.
MatchSessionSnapshot deriveMatchSessionSnapshot({
  required SessionStatus status,
  required DateTime startedAt,
  required DateTime? endedAt,
  required List<SessionEvent> events,
  required int nowMs,
}) {
  final startedEvent = events.firstWhere(
    (e) => e.type == SessionEventType.sessionStarted,
    orElse: () => throw StateError('Session has no SESSION_STARTED event'),
  );

  final sides = (startedEvent.payload['sides'] as List)
      .cast<Map<String, dynamic>>()
      .map(ScoringSide.fromJson)
      .toList();
  final matchRule = MatchRule.fromJson(
    (startedEvent.payload['matchRule'] as Map).cast<String, dynamic>(),
  );

  final scoreEvents = events
      .map((e) => e.toScoreEngineEvent())
      .whereType<ScoreEngineEvent>()
      .toList();
  final matchEvents = events
      .map((e) => e.toMatchEngineEvent())
      .whereType<MatchEngineEvent>()
      .toList();

  final scoreState = ScoreEngine.replay(matchRule.scoreRule, scoreEvents);
  final matchState = MatchEngine.replay(matchRule, matchEvents, nowMs: nowMs);

  final hasShootoutStarted = events.any(
    (e) => e.type == SessionEventType.shootoutStarted,
  );
  ShootoutState? shootoutState;
  if (hasShootoutStarted && matchRule.shootout != null) {
    final shootoutEvents = events
        .map((e) => e.toShootoutEngineEvent())
        .whereType<ShootoutEngineEvent>()
        .toList();
    shootoutState = ShootoutEngine.replay(
      matchRule.shootout!,
      matchRule.scoreRule.sideIds,
      shootoutEvents,
    );
  }

  ShotClockState? shotClockState;
  if (matchRule.shotClockRule != null) {
    final shotClockEvents = events
        .map((e) => e.toShotClockEngineEvent())
        .whereType<ShotClockEngineEvent>()
        .toList();
    shotClockState = ShotClockEngine.replay(
      matchRule.shotClockRule!,
      shotClockEvents,
      nowMs: nowMs,
    );
  }

  TimeoutState? timeoutState;
  if (matchRule.timeoutRule != null) {
    final timeoutEvents = events
        .map((e) => e.toTimeoutEngineEvent())
        .whereType<TimeoutEngineEvent>()
        .toList();
    timeoutState = TimeoutEngine.replay(timeoutEvents);
  }

  TeamFoulState? teamFoulState;
  if (matchRule.teamFoulRule != null) {
    final teamFoulEvents = events
        .map((e) => e.toTeamFoulEngineEvent())
        .whereType<TeamFoulEngineEvent>()
        .toList();
    teamFoulState = TeamFoulEngine.replay(
      matchRule.teamFoulRule!,
      matchRule.scoreRule.sideIds,
      teamFoulEvents,
    );
  }

  return MatchSessionSnapshot(
    sides: sides,
    matchRule: matchRule,
    scoreState: scoreState,
    matchState: matchState,
    shootoutState: shootoutState,
    shotClockState: shotClockState,
    timeoutState: timeoutState,
    teamFoulState: teamFoulState,
    status: status,
    startedAt: startedAt,
    endedAt: endedAt,
  );
}

/// Resolves what a bare `undoLast()` action should target — see
/// `team_match_session_controller.dart` and the Phase Sports 2 brief's
/// undo-scope decision: undo only ever targets the single most recent
/// *meaningful* event (a point, a period ending, a shootout attempt, a
/// shot-clock reset, a timeout, a team foul, or the event that completed
/// the match), never a lifecycle/clock-control event like `SESSION_
/// STARTED`/`PERIOD_STARTED`/`TIMER_PAUSED` — those aren't user-reversible
/// actions in the UI, they're consequences of one. Returns null when
/// nothing is left to undo. Pure: a plain function of the raw log, reused
/// for both "is undo available" (result != null) and "what to append
/// UNDO against" (the result itself).
String? resolveMatchUndoTarget(List<SessionEvent> events) {
  const undoableTypes = {
    SessionEventType.pointScored,
    SessionEventType.periodEnded,
    SessionEventType.shootoutAttempt,
    SessionEventType.sessionCompleted,
    SessionEventType.shotClockReset,
    SessionEventType.timeoutTaken,
    SessionEventType.teamFoulAdded,
  };
  final alreadyUndone = <String>{};
  for (final event in events) {
    if (event.type != SessionEventType.undo) continue;
    final target = event.payload['targetEventId'] as String?;
    if (target != null) alreadyUndone.add(target);
  }

  for (final event in events.reversed) {
    if (!undoableTypes.contains(event.type)) continue;
    if (alreadyUndone.contains(event.id)) continue;
    return event.id;
  }
  return null;
}
