import '../events/session_event.dart';
import '../events/timer_engine_event.dart';
import '../models/session_status.dart';
import '../models/timer_snapshot.dart';
import '../models/timer_spec.dart';
import 'timer_engine.dart';

/// Turns a Timer session's persisted event log into a [TimerSnapshot] —
/// the one place that knows how to read the `SESSION_STARTED` payload and
/// replay the rest through [TimerEngine]. Pure aside from the caller-
/// supplied [nowMs] (wall-clock milliseconds — see `playtap-timer-engine`):
/// same inputs always produce the same snapshot.
TimerSnapshot deriveTimerSnapshot({
  required SessionStatus sessionStatus,
  required DateTime startedAt,
  required DateTime? endedAt,
  required List<SessionEvent> events,
  required int nowMs,
}) {
  final startedEvent = events.firstWhere(
    (e) => e.type == SessionEventType.sessionStarted,
    orElse: () => throw StateError('Session has no SESSION_STARTED event'),
  );

  final spec = TimerSpec.fromJson(
    startedEvent.payload['timerSpec'] as Map<String, dynamic>,
  );

  final engineEvents = events
      .map((e) => e.toTimerEngineEvent())
      .whereType<TimerEngineEvent>()
      .toList();

  return TimerSnapshot(
    spec: spec,
    state: TimerEngine.replay(spec, engineEvents, nowMs: nowMs),
    sessionStatus: sessionStatus,
    startedAt: startedAt,
    endedAt: endedAt,
  );
}
