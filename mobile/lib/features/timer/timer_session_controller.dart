import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../app/providers/database_providers.dart';
import '../../domain/engines/timer_deriver.dart';
import '../../domain/engines/timer_engine.dart';
import '../../domain/events/session_event.dart';
import '../../domain/models/session_status.dart';
import '../../domain/models/timer_mode.dart';
import '../../domain/models/timer_snapshot.dart';
import '../../domain/models/timer_status.dart';

const _uuid = Uuid();

final timerSessionControllerProvider =
    AsyncNotifierProvider.family<TimerSessionController, TimerSnapshot, String>(
      TimerSessionController.new,
    );

/// UI -> this controller -> event creation -> repositories -> TimerEngine
/// replay -> TimerState -> UI — same shape as
/// `FreeScoreSessionController`, plus a *live display* path: between real
/// persisted events, [currentDisplaySnapshot] ticks using the monotonic
/// clock so a system clock change never affects what's on screen (see
/// `playtap-timer-engine` "Quelle horloge pour `now` ?"). The Riverpod
/// `state` itself only ever changes on a real persisted transition.
class TimerSessionController extends AsyncNotifier<TimerSnapshot> {
  TimerSessionController(this.sessionId);

  final String sessionId;

  int? _monotonicAnchorMs;
  int _baselineElapsedMs = 0;

  /// Guards [checkLiveCompletion] and [complete] against re-entrancy: the
  /// UI ticker calls [checkLiveCompletion] without awaiting it every
  /// ~200ms, and `_load()`'s multiple DB round-trips can take longer than
  /// that under load — without this, two overlapping calls both read
  /// `hasTerminalEvent == false` before either write is visible and each
  /// persists its own `TIMER_COMPLETED`/`SESSION_COMPLETED` (seen for real
  /// on-device: two `TIMER_COMPLETED` rows for one countdown reaching
  /// zero). Only one finalize-triggering call runs at a time; the rest
  /// no-op, which is safe since the very next tick after the in-flight one
  /// resolves observes `sessionStatus != active` and stops re-triggering.
  bool _finalizeInFlight = false;

  @override
  Future<TimerSnapshot> build() async {
    final snapshot = await _load();
    _resetAnchor(snapshot);
    return snapshot;
  }

  Future<TimerSnapshot> _load() async {
    final session = await ref
        .read(sessionRepositoryProvider)
        .getSessionById(sessionId);
    if (session == null) {
      throw StateError('Session $sessionId does not exist');
    }
    final events = await ref
        .read(eventRepositoryProvider)
        .getEventsForSession(sessionId);
    final nowMs = ref.read(clockProvider).now().millisecondsSinceEpoch;

    final snapshot = deriveTimerSnapshot(
      sessionStatus: session.status,
      startedAt: session.startedAt,
      endedAt: session.endedAt,
      events: events,
      nowMs: nowMs,
    );

    final hasTerminalEvent = events.any(
      (e) =>
          e.type == SessionEventType.timerCompleted ||
          e.type == SessionEventType.sessionCompleted,
    );
    if (session.status == SessionStatus.active &&
        TimerEngine.isUnfinalizedCountdownCompletion(
          snapshot.spec,
          snapshot.state,
          hasTerminalEvent,
        )) {
      await _finalize(SessionEventType.timerCompleted, nowMs);
      return _load(); // one recursive reload; hasTerminalEvent is true next time.
    }

    return snapshot;
  }

  void _resetAnchor(TimerSnapshot snapshot) {
    _baselineElapsedMs = snapshot.state.elapsedMs;
    _monotonicAnchorMs = snapshot.state.status == TimerStatus.running
        ? ref.read(clockProvider).monotonicNowMillis()
        : null;
  }

  /// Pure, synchronous, never persists anything — call this from the UI's
  /// own repaint ticker (see the Phase 1B.2 brief section 21) to get a
  /// smoothly-updating value between real events. Falls back to the last
  /// loaded state while paused/completed/loading (nothing to tick).
  TimerSnapshot? currentDisplaySnapshot() {
    final baseline = state.value;
    if (baseline == null) return null;
    if (baseline.state.status != TimerStatus.running ||
        _monotonicAnchorMs == null) {
      return baseline;
    }
    final liveElapsedMs =
        _baselineElapsedMs +
        (ref.read(clockProvider).monotonicNowMillis() - _monotonicAnchorMs!);
    final projected = TimerEngine.projectLiveElapsed(
      baseline.spec,
      liveElapsedMs,
      baseline.state.laps,
    );
    return TimerSnapshot(
      spec: baseline.spec,
      state: projected,
      sessionStatus: baseline.sessionStatus,
      startedAt: baseline.startedAt,
      endedAt: baseline.endedAt,
    );
  }

  /// Called by the UI ticker after each repaint: if the live display just
  /// crossed into a natural COUNTDOWN completion, persist it exactly once
  /// (idempotent — see `_load`, which no-ops once the terminal event
  /// exists) and publish the real, persisted terminal state.
  Future<void> checkLiveCompletion() async {
    if (_finalizeInFlight) return;
    final current = state.value;
    final display = currentDisplaySnapshot();
    if (current == null || display == null) return;
    if (current.sessionStatus == SessionStatus.active &&
        display.spec.mode == TimerMode.countdown &&
        display.state.status == TimerStatus.completed) {
      _finalizeInFlight = true;
      try {
        final snapshot = await _load();
        _resetAnchor(snapshot);
        state = AsyncData(snapshot);
      } finally {
        _finalizeInFlight = false;
      }
    }
  }

  Future<void> pause() async {
    final current = state.value;
    if (current == null || current.state.status != TimerStatus.running) return;
    await _appendAndReload(SessionEventType.timerPaused);
  }

  Future<void> resume() async {
    final current = state.value;
    if (current == null || current.state.status != TimerStatus.paused) return;
    await _appendAndReload(SessionEventType.timerResumed);
  }

  Future<void> recordLap() async {
    final current = state.value;
    if (current == null ||
        current.state.status != TimerStatus.running ||
        current.spec.mode != TimerMode.lapTimer) {
      return;
    }
    await _appendAndReload(SessionEventType.lapRecorded);
  }

  /// User-initiated end of session (see `playtap-product` — "Terminer la
  /// session"). For a COUNTDOWN that already ran out on its own, prefer
  /// `checkLiveCompletion`/the automatic path — this is for STOPWATCH,
  /// LAP_TIMER, or stopping a COUNTDOWN early.
  Future<void> complete() async {
    if (_finalizeInFlight) return;
    final current = state.value;
    if (current == null || current.sessionStatus != SessionStatus.active) {
      return;
    }
    _finalizeInFlight = true;
    try {
      await _finalize(
        SessionEventType.sessionCompleted,
        ref.read(clockProvider).now().millisecondsSinceEpoch,
      );
      final snapshot = await _load();
      _resetAnchor(snapshot);
      state = AsyncData(snapshot);
    } finally {
      _finalizeInFlight = false;
    }
  }

  /// Guarded like [complete] and [checkLiveCompletion]: this calls [_load],
  /// which can itself finalize a countdown that just hit zero — without the
  /// same [_finalizeInFlight] guard here, a pause/resume/lap tap landing at
  /// that exact instant could race the ticker's in-flight finalize and
  /// double-write the terminal event (see the guard's doc comment above).
  Future<void> _appendAndReload(SessionEventType type) async {
    if (_finalizeInFlight) return;
    _finalizeInFlight = true;
    try {
      await ref
          .read(eventRepositoryProvider)
          .appendPhoneEvent(
            id: _uuid.v4(),
            sessionId: sessionId,
            type: type,
            payload: const {},
            timestamp: ref.read(clockProvider).now(),
          );
      final snapshot = await _load();
      _resetAnchor(snapshot);
      state = AsyncData(snapshot);
    } finally {
      _finalizeInFlight = false;
    }
  }

  Future<void> _finalize(SessionEventType terminalType, int nowMs) async {
    final now = DateTime.fromMillisecondsSinceEpoch(nowMs, isUtc: true);
    final db = ref.read(databaseProvider);
    await db.transaction(() async {
      await ref
          .read(eventRepositoryProvider)
          .appendPhoneEvent(
            id: _uuid.v4(),
            sessionId: sessionId,
            type: terminalType,
            payload: const {},
            timestamp: now,
          );
      await ref
          .read(sessionRepositoryProvider)
          .completeSession(sessionId, endedAt: now);
    });
  }
}
