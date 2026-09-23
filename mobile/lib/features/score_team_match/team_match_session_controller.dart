import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../app/providers/database_providers.dart';
import '../../domain/engines/match_engine.dart';
import '../../domain/engines/match_session_deriver.dart';
import '../../domain/engines/shot_clock_engine.dart';
import '../../domain/engines/timeout_engine.dart';
import '../../domain/events/match_engine_event.dart';
import '../../domain/events/session_event.dart';
import '../../domain/models/match_clock_kind.dart';
import '../../domain/models/match_session_snapshot.dart';
import '../../domain/models/match_state.dart';
import '../../domain/models/session_status.dart';
import '../../domain/models/timer_status.dart';

const _uuid = Uuid();

final teamMatchSessionControllerProvider =
    AsyncNotifierProvider.family<
      TeamMatchSessionController,
      MatchSessionSnapshot,
      String
    >(TeamMatchSessionController.new);

/// UI -> this controller -> events -> repositories -> `ScoreEngine` +
/// `MatchEngine` (+ `ShootoutEngine`) replay -> UI — the shared controller
/// behind Basketball, Football, and Futsal (see
/// `domain/engines/match_session_deriver.dart`): nothing here branches on
/// sport identity, only on what [MatchSessionSnapshot.matchRule] says.
/// Combines `PetanqueSessionController`'s event-append/reload/reopen-on-
/// undo shape with `TimerSessionController`'s live-clock-projection shape
/// (monotonic-clock ticking between persisted events, wall-clock replay
/// for recovery — see `playtap-timer-engine` "Quelle horloge pour `now` ?").
class TeamMatchSessionController extends AsyncNotifier<MatchSessionSnapshot> {
  TeamMatchSessionController(this.sessionId);

  final String sessionId;

  int? _monotonicAnchorMs;
  int _baselineElapsedMs = 0;

  /// Separate anchor for the shot clock (Basketball) — it doesn't always
  /// move in lockstep with the match clock (e.g. paused for a reset while
  /// the game clock keeps running between free throws), so it needs its
  /// own live-projection baseline.
  int? _shotClockMonotonicAnchorMs;
  int _shotClockBaselineElapsedMs = 0;

  /// Guards every mutating method against re-entrancy — a rapid double-tap
  /// fires two calls before either `await` settles, which would otherwise
  /// double-append events for what the user experiences as one tap (the
  /// exact bug fixed for Pétanque in commit `9e7085e`; mirrors
  /// `TimerSessionController._finalizeInFlight`'s identical shape, applied
  /// uniformly here to every mutation rather than split by method).
  bool _mutationInFlight = false;

  @override
  Future<MatchSessionSnapshot> build() async {
    final snapshot = await _load();
    _resetAnchor(snapshot);
    return snapshot;
  }

  Future<MatchSessionSnapshot> _load() async {
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

    final snapshot = deriveMatchSessionSnapshot(
      status: session.status,
      startedAt: session.startedAt,
      endedAt: session.endedAt,
      events: events,
      nowMs: nowMs,
    );

    // Scoped to the *current* period only: a `PERIOD_ENDED` from an earlier
    // period must never suppress detecting the current period's own
    // expiry (each `PERIOD_STARTED` starts a fresh window — see
    // `MatchEngine.replay`'s identical clock-reset behavior).
    final lastPeriodStartedIndex = events.lastIndexWhere(
      (e) => e.type == SessionEventType.periodStarted,
    );
    final hasTerminalEvent = events
        .skip(lastPeriodStartedIndex + 1)
        .any(
          (e) =>
              e.type == SessionEventType.timerCompleted ||
              e.type == SessionEventType.periodEnded,
        );
    if (session.status == SessionStatus.active &&
        MatchEngine.isUnfinalizedStoppedPeriodCompletion(
          snapshot.matchRule,
          snapshot.matchState,
          hasTerminalEvent,
        )) {
      await _finalizePeriodEnd(rawEvents: events, current: snapshot);
      return _load(); // one recursive reload; hasTerminalEvent is true next time.
    }

    return snapshot;
  }

  void _resetAnchor(MatchSessionSnapshot snapshot) {
    _baselineElapsedMs = snapshot.matchState.clock.elapsedMs;
    _monotonicAnchorMs = snapshot.matchState.clock.status == TimerStatus.running
        ? ref.read(clockProvider).monotonicNowMillis()
        : null;

    _shotClockBaselineElapsedMs = snapshot.shotClockState?.elapsedMs ?? 0;
    _shotClockMonotonicAnchorMs =
        snapshot.shotClockState?.status == TimerStatus.running
        ? ref.read(clockProvider).monotonicNowMillis()
        : null;
  }

  /// Pure, synchronous, never persists anything — call this from the UI's
  /// own repaint ticker to get a smoothly-updating clock between real
  /// events (mirrors `TimerSessionController.currentDisplaySnapshot`).
  MatchSessionSnapshot? currentDisplaySnapshot() {
    final baseline = state.value;
    if (baseline == null) return null;

    final matchState =
        baseline.matchState.clock.status == TimerStatus.running &&
            _monotonicAnchorMs != null
        ? MatchEngine.projectLiveElapsed(
            baseline.matchRule,
            baseline.matchState,
            _baselineElapsedMs +
                (ref.read(clockProvider).monotonicNowMillis() -
                    _monotonicAnchorMs!),
          )
        : baseline.matchState;

    final shotClockState =
        baseline.shotClockState?.status == TimerStatus.running &&
            _shotClockMonotonicAnchorMs != null
        ? ShotClockEngine.projectLiveElapsed(
            baseline.shotClockState!,
            _shotClockBaselineElapsedMs +
                (ref.read(clockProvider).monotonicNowMillis() -
                    _shotClockMonotonicAnchorMs!),
          )
        : baseline.shotClockState;

    if (identical(matchState, baseline.matchState) &&
        identical(shotClockState, baseline.shotClockState)) {
      return baseline;
    }

    return MatchSessionSnapshot(
      sides: baseline.sides,
      matchRule: baseline.matchRule,
      scoreState: baseline.scoreState,
      matchState: matchState,
      shootoutState: baseline.shootoutState,
      shotClockState: shotClockState,
      timeoutState: baseline.timeoutState,
      teamFoulState: baseline.teamFoulState,
      status: baseline.status,
      startedAt: baseline.startedAt,
      endedAt: baseline.endedAt,
    );
  }

  /// Called by the UI ticker after each repaint (STOPPED_CLOCK sports
  /// only — Basketball, Futsal): if the live display just crossed into a
  /// natural period expiry, persist it exactly once and advance to
  /// whatever comes next (mirrors
  /// `TimerSessionController.checkLiveCompletion`).
  Future<void> checkLivePeriodExpiry() async {
    if (_mutationInFlight) return;
    final current = state.value;
    final display = currentDisplaySnapshot();
    if (current == null || display == null) return;
    if (current.status != SessionStatus.active) return;
    if (!MatchEngine.isUnfinalizedStoppedPeriodCompletion(
      display.matchRule,
      display.matchState,
      false,
    )) {
      return;
    }
    _mutationInFlight = true;
    try {
      final rawEvents = await ref
          .read(eventRepositoryProvider)
          .getEventsForSession(sessionId);
      await _finalizePeriodEnd(rawEvents: rawEvents, current: current);
      final snapshot = await _load();
      _resetAnchor(snapshot);
      state = AsyncData(snapshot);
    } finally {
      _mutationInFlight = false;
    }
  }

  /// Records one point: [sideId] scored [amount] (validated against
  /// `matchRule.scoreRule.allowedIncrements` by `ScoreEngine` itself).
  /// Never ends the match on its own — these sports only end via period/
  /// overtime/shootout resolution, never by reaching a score number.
  Future<void> addPoint(String sideId, int amount) async {
    if (_mutationInFlight) return;
    final current = state.value;
    if (current == null || current.status != SessionStatus.active) return;

    _mutationInFlight = true;
    try {
      await ref
          .read(eventRepositoryProvider)
          .appendPhoneEvent(
            id: _uuid.v4(),
            sessionId: sessionId,
            type: SessionEventType.pointScored,
            payload: {'side': sideId, 'amount': amount},
            timestamp: ref.read(clockProvider).now(),
          );
      final snapshot = await _load();
      _resetAnchor(snapshot);
      state = AsyncData(snapshot);
    } finally {
      _mutationInFlight = false;
    }
  }

  /// The single START/PAUSE control: starts the clock the first time (no
  /// elapsed time yet this period), resumes it after a pause, or pauses it
  /// while running — one button, like the brief's mockup.
  ///
  /// Paired one-way with the shot clock (Basketball): pausing the game
  /// clock always pauses a currently-running shot clock too, in the same
  /// transaction — a shot clock that kept ticking while the game is
  /// paused would be a real bug (see the brief section 4). Resuming the
  /// game clock deliberately does **not** auto-resume the shot clock —
  /// that would invent a possession/whistle decision PlayTap never makes
  /// on its own; the scorer resumes or resets it explicitly.
  Future<void> togglePlayPause() async {
    if (_mutationInFlight) return;
    final current = state.value;
    if (current == null || current.status != SessionStatus.active) return;
    final clock = current.matchState.clock;

    final type = switch (clock.status) {
      TimerStatus.running => SessionEventType.timerPaused,
      TimerStatus.paused when clock.elapsedMs == 0 =>
        SessionEventType.timerStarted,
      TimerStatus.paused => SessionEventType.timerResumed,
      TimerStatus.completed => null, // period already over: nothing to toggle.
    };
    if (type == null) return;

    _mutationInFlight = true;
    try {
      final now = ref.read(clockProvider).now();
      final pausingWhileShotClockRuns =
          type == SessionEventType.timerPaused &&
          current.shotClockState?.status == TimerStatus.running;

      if (pausingWhileShotClockRuns) {
        final db = ref.read(databaseProvider);
        await db.transaction(() async {
          await ref
              .read(eventRepositoryProvider)
              .appendPhoneEvent(
                id: _uuid.v4(),
                sessionId: sessionId,
                type: type,
                payload: const {},
                timestamp: now,
              );
          await ref
              .read(eventRepositoryProvider)
              .appendPhoneEvent(
                id: _uuid.v4(),
                sessionId: sessionId,
                type: SessionEventType.shotClockPaused,
                payload: const {},
                timestamp: now,
              );
        });
      } else {
        await ref
            .read(eventRepositoryProvider)
            .appendPhoneEvent(
              id: _uuid.v4(),
              sessionId: sessionId,
              type: type,
              payload: const {},
              timestamp: now,
            );
      }
      final snapshot = await _load();
      _resetAnchor(snapshot);
      state = AsyncData(snapshot);
    } finally {
      _mutationInFlight = false;
    }
  }

  /// Announces added time for a RUNNING_CLOCK period (the referee's
  /// "board up" moment — Law 7: added time is at the referee's discretion,
  /// PlayTap never invents it). Purely informational for the display
  /// ("45+3") — the clock itself keeps free-running regardless, see
  /// `MatchState.announcedAddedTimeMs`.
  Future<void> announceAddedTime(Duration addedTime) async {
    if (_mutationInFlight) return;
    final current = state.value;
    if (current == null || current.status != SessionStatus.active) return;
    if (current.matchRule.clock != MatchClockKind.runningClock) return;

    _mutationInFlight = true;
    try {
      await ref
          .read(eventRepositoryProvider)
          .appendPhoneEvent(
            id: _uuid.v4(),
            sessionId: sessionId,
            type: SessionEventType.addedTimeAnnounced,
            payload: {
              'periodIndex': current.matchState.periodIndex,
              'addedTimeMs': addedTime.inMilliseconds,
            },
            timestamp: ref.read(clockProvider).now(),
          );
      final snapshot = await _load();
      _resetAnchor(snapshot);
      state = AsyncData(snapshot);
    } finally {
      _mutationInFlight = false;
    }
  }

  /// Shot clock (Basketball) START/PAUSE — same "started doubles as
  /// resume" behavior as `ShotClockEngine` itself (see its doc note).
  Future<void> toggleShotClockPlayPause() async {
    if (_mutationInFlight) return;
    final current = state.value;
    if (current == null || current.status != SessionStatus.active) return;
    final shotClock = current.shotClockState;
    if (shotClock == null) return; // no shot clock rule for this sport.

    final type = switch (shotClock.status) {
      TimerStatus.running => SessionEventType.shotClockPaused,
      TimerStatus.paused => SessionEventType.shotClockStarted,
      TimerStatus.completed => null, // buzzer already sounded: reset first.
    };
    if (type == null) return;

    _mutationInFlight = true;
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
      _mutationInFlight = false;
    }
  }

  /// The "24"/"14" quick-reset actions — PlayTap never infers which one
  /// applies (see `ShotClockRule`'s doc note); the scorer picks. Starts
  /// running immediately if the shot clock was already running (a reset
  /// happens at a live-ball moment), otherwise stays paused at the new
  /// duration until the scorer taps start.
  Future<void> resetShotClock(Duration duration) async {
    if (_mutationInFlight) return;
    final current = state.value;
    if (current == null || current.status != SessionStatus.active) return;
    if (current.shotClockState == null) return;

    _mutationInFlight = true;
    try {
      await ref
          .read(eventRepositoryProvider)
          .appendPhoneEvent(
            id: _uuid.v4(),
            sessionId: sessionId,
            type: SessionEventType.shotClockReset,
            payload: {'durationMs': duration.inMilliseconds},
            timestamp: ref.read(clockProvider).now(),
          );
      final snapshot = await _load();
      _resetAnchor(snapshot);
      state = AsyncData(snapshot);
    } finally {
      _mutationInFlight = false;
    }
  }

  /// Called by the UI ticker (Basketball only): if the live shot-clock
  /// display just crossed into a natural expiry, persist it exactly once
  /// — purely informational (the buzzer), never forces anything else to
  /// happen (see `ShotClockRule`'s doc note: the ref/scorer decides what
  /// comes next, PlayTap only tracks the clock itself).
  Future<void> checkLiveShotClockExpiry() async {
    if (_mutationInFlight) return;
    final current = state.value;
    final display = currentDisplaySnapshot();
    if (current == null || display?.shotClockState == null) return;
    if (current.status != SessionStatus.active) return;
    if (!ShotClockEngine.isUnfinalizedCompletion(
      display!.shotClockState!,
      false,
    )) {
      return;
    }
    _mutationInFlight = true;
    try {
      await ref
          .read(eventRepositoryProvider)
          .appendPhoneEvent(
            id: _uuid.v4(),
            sessionId: sessionId,
            type: SessionEventType.shotClockCompleted,
            payload: const {},
            timestamp: ref.read(clockProvider).now(),
          );
      final snapshot = await _load();
      _resetAnchor(snapshot);
      state = AsyncData(snapshot);
    } finally {
      _mutationInFlight = false;
    }
  }

  /// Records [sideId] taking a timeout — refuses if `TimeoutEngine.
  /// remainingForSide` says none are left right now (quota enforced by
  /// the ruleset, never a UI constant). The match context (period/
  /// overtime/remaining clock) is captured from the live display at this
  /// exact instant, into the event's own payload — see `TimeoutRecord`'s
  /// doc note on why replay never needs to re-derive it later.
  Future<void> takeTimeout(String sideId) async {
    if (_mutationInFlight) return;
    final current = state.value;
    if (current == null || current.status != SessionStatus.active) return;
    final rule = current.matchRule.timeoutRule;
    final timeoutState = current.timeoutState;
    if (rule == null || timeoutState == null) return;

    final display = currentDisplaySnapshot() ?? current;
    final matchState = display.matchState;
    final remaining = TimeoutEngine.remainingForSide(
      rule,
      timeoutState,
      sideId,
      periodIndex: matchState.periodIndex,
      isOvertimePeriod: matchState.isOvertimePeriod,
      overtimeCount: matchState.overtimeCount,
      periodRemainingMs:
          matchState.clock.remainingMs ?? matchState.clock.elapsedMs,
    );
    if (remaining <= 0) return;

    _mutationInFlight = true;
    try {
      await ref
          .read(eventRepositoryProvider)
          .appendPhoneEvent(
            id: _uuid.v4(),
            sessionId: sessionId,
            type: SessionEventType.timeoutTaken,
            payload: {
              'sideId': sideId,
              'periodIndex': matchState.periodIndex,
              'isOvertimePeriod': matchState.isOvertimePeriod,
              'overtimeCount': matchState.overtimeCount,
              'periodRemainingMsAtTime':
                  matchState.clock.remainingMs ?? matchState.clock.elapsedMs,
            },
            timestamp: ref.read(clockProvider).now(),
          );
      final snapshot = await _load();
      _resetAnchor(snapshot);
      state = AsyncData(snapshot);
    } finally {
      _mutationInFlight = false;
    }
  }

  /// Records one team foul on [sideId] — the scorer taps this for
  /// whatever they judge countable; PlayTap never infers foul type (see
  /// `TeamFoulRule`'s doc note).
  Future<void> addTeamFoul(String sideId) async {
    if (_mutationInFlight) return;
    final current = state.value;
    if (current == null || current.status != SessionStatus.active) return;
    if (current.matchRule.teamFoulRule == null) return;

    _mutationInFlight = true;
    try {
      await ref
          .read(eventRepositoryProvider)
          .appendPhoneEvent(
            id: _uuid.v4(),
            sessionId: sessionId,
            type: SessionEventType.teamFoulAdded,
            payload: {'sideId': sideId},
            timestamp: ref.read(clockProvider).now(),
          );
      final snapshot = await _load();
      _resetAnchor(snapshot);
      state = AsyncData(snapshot);
    } finally {
      _mutationInFlight = false;
    }
  }

  /// The referee's whistle for a RUNNING_CLOCK sport (Football) — nothing
  /// auto-expires a running clock, so ending a period is always this
  /// explicit action (see the secondary "⋯" panel).
  Future<void> endPeriodManually() async {
    if (_mutationInFlight) return;
    final current = state.value;
    if (current == null || current.status != SessionStatus.active) return;
    if (current.matchRule.clock != MatchClockKind.runningClock) return;

    _mutationInFlight = true;
    try {
      final rawEvents = await ref
          .read(eventRepositoryProvider)
          .getEventsForSession(sessionId);
      await _finalizePeriodEnd(rawEvents: rawEvents, current: current);
      final snapshot = await _load();
      _resetAnchor(snapshot);
      state = AsyncData(snapshot);
    } finally {
      _mutationInFlight = false;
    }
  }

  /// Records one shootout kick; if it just decided the shootout, persists
  /// `SHOOTOUT_COMPLETED` + `SESSION_COMPLETED` (endReason `DECIDED_BY_
  /// SHOOTOUT`) atomically — mirrors the period-end auto-detection shape,
  /// but shootout resolution is synchronous (no clock to wait on).
  Future<void> recordShootoutAttempt(
    String sideId, {
    required bool scored,
  }) async {
    if (_mutationInFlight) return;
    final current = state.value;
    if (current == null || current.status != SessionStatus.active) return;
    if (current.matchState.phase != MatchPhase.shootoutInProgress) return;

    _mutationInFlight = true;
    try {
      final now = ref.read(clockProvider).now();
      await ref
          .read(eventRepositoryProvider)
          .appendPhoneEvent(
            id: _uuid.v4(),
            sessionId: sessionId,
            type: SessionEventType.shootoutAttempt,
            payload: {'side': sideId, 'scored': scored},
            timestamp: now,
          );
      final reloaded = await _load();
      if (reloaded.shootoutState?.decided ?? false) {
        final db = ref.read(databaseProvider);
        await db.transaction(() async {
          await ref
              .read(eventRepositoryProvider)
              .appendPhoneEvent(
                id: _uuid.v4(),
                sessionId: sessionId,
                type: SessionEventType.shootoutCompleted,
                payload: const {},
                timestamp: now,
              );
          await ref
              .read(eventRepositoryProvider)
              .appendPhoneEvent(
                id: _uuid.v4(),
                sessionId: sessionId,
                type: SessionEventType.sessionCompleted,
                payload: {
                  'endReason': MatchEndReason.decidedByShootout.toJson(),
                },
                timestamp: now,
              );
          await ref
              .read(sessionRepositoryProvider)
              .completeSession(sessionId, endedAt: now);
        });
      }
      final snapshot = await _load();
      _resetAnchor(snapshot);
      state = AsyncData(snapshot);
    } finally {
      _mutationInFlight = false;
    }
  }

  /// Undoes the single most recent meaningful event — a point, a period
  /// ending, a shootout attempt, or the event that completed the match
  /// (see `resolveMatchUndoTarget`). If it was the event that completed
  /// the match, this reopens the session (mirrors
  /// `PetanqueSessionController.undoLast`'s identical `reopenSession`
  /// call).
  Future<void> undoLast() async {
    if (_mutationInFlight) return;
    final current = state.value;
    if (current == null) return;
    final wasComplete = current.matchState.matchEnded;
    if (current.status != SessionStatus.active && !wasComplete) return;

    _mutationInFlight = true;
    try {
      final rawEvents = await ref
          .read(eventRepositoryProvider)
          .getEventsForSession(sessionId);
      final target = resolveMatchUndoTarget(rawEvents);
      if (target == null) return;

      await ref
          .read(eventRepositoryProvider)
          .appendPhoneEvent(
            id: _uuid.v4(),
            sessionId: sessionId,
            type: SessionEventType.undo,
            payload: {'targetEventId': target},
            timestamp: ref.read(clockProvider).now(),
          );
      final reloaded = await _load();
      if (wasComplete && !reloaded.matchState.matchEnded) {
        await ref.read(sessionRepositoryProvider).reopenSession(sessionId);
      }
      final snapshot = await _load();
      _resetAnchor(snapshot);
      state = AsyncData(snapshot);
    } finally {
      _mutationInFlight = false;
    }
  }

  /// Shared by the auto-detected STOPPED_CLOCK expiry path
  /// ([checkLivePeriodExpiry]) and the manual RUNNING_CLOCK whistle
  /// ([endPeriodManually]): appends the period-ending event(s) *and*
  /// whatever `MatchEngine.decideNextPhase` says comes next — computed
  /// entirely in-memory from [rawEvents] plus the synthetic events about
  /// to be appended (no mid-transaction DB round-trip needed), then
  /// persisted together in one transaction, exactly like
  /// `startPetanqueSession`'s atomic multi-event append.
  Future<void> _finalizePeriodEnd({
    required List<SessionEvent> rawEvents,
    required MatchSessionSnapshot current,
  }) async {
    final rule = current.matchRule;
    final now = ref.read(clockProvider).now();
    final nowMs = now.millisecondsSinceEpoch;

    final toAppend = <(SessionEventType, Map<String, dynamic>)>[
      if (rule.clock == MatchClockKind.stoppedClock)
        (SessionEventType.timerCompleted, const {}),
      (SessionEventType.periodEnded, const {}),
    ];

    final syntheticMatchEvents = [
      ...rawEvents
          .map((e) => e.toMatchEngineEvent())
          .whereType<MatchEngineEvent>(),
      for (final (type, payload) in toAppend)
        MatchEngineEvent(
          id: _uuid.v4(),
          type: MatchEngineEventType.tryFromJson(type.toJson())!,
          atMs: nowMs,
          payload: payload,
        ),
    ];
    final stateAfterPeriodEnd = MatchEngine.replay(
      rule,
      syntheticMatchEvents,
      nowMs: nowMs,
    );
    final decision = MatchEngine.decideNextPhase(
      rule,
      stateAfterPeriodEnd,
      current.scoreState,
    );

    switch (decision.action) {
      case NextPhaseAction.continueRegulation:
        toAppend.add((
          SessionEventType.periodStarted,
          {'periodIndex': decision.nextPeriodIndex, 'kind': 'REGULATION'},
        ));
      case NextPhaseAction.startOvertime:
        toAppend.add((
          SessionEventType.periodStarted,
          {'kind': 'OVERTIME', 'overtimeNumber': decision.overtimeNumber},
        ));
      case NextPhaseAction.startShootout:
        toAppend.add((SessionEventType.shootoutStarted, const {}));
      case NextPhaseAction.matchEnds:
        toAppend.add((
          SessionEventType.sessionCompleted,
          {'endReason': decision.endReason!.toJson()},
        ));
    }

    // A new regulation/overtime period always starts with a fresh shot
    // clock (paused at the default duration — never auto-started, exactly
    // like the game clock itself waits for an explicit START).
    if (rule.shotClockRule != null &&
        (decision.action == NextPhaseAction.continueRegulation ||
            decision.action == NextPhaseAction.startOvertime)) {
      toAppend.add((
        SessionEventType.shotClockReset,
        {'durationMs': rule.shotClockRule!.defaultDurationMs},
      ));
    }

    final db = ref.read(databaseProvider);
    await db.transaction(() async {
      for (final (type, payload) in toAppend) {
        await ref
            .read(eventRepositoryProvider)
            .appendPhoneEvent(
              id: _uuid.v4(),
              sessionId: sessionId,
              type: type,
              payload: payload,
              timestamp: now,
            );
      }
      if (decision.action == NextPhaseAction.matchEnds) {
        await ref
            .read(sessionRepositoryProvider)
            .completeSession(sessionId, endedAt: now);
      }
    });
  }
}
