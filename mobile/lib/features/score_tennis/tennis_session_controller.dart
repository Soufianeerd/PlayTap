import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../app/providers/database_providers.dart';
import '../../domain/engines/racket_session_deriver.dart';
import '../../domain/events/session_event.dart';
import '../../domain/models/racket_session_snapshot.dart';
import '../../domain/models/session_status.dart';

const _uuid = Uuid();

final tennisSessionControllerProvider =
    AsyncNotifierProvider.family<
      TennisSessionController,
      RacketSessionSnapshot,
      String
    >(TennisSessionController.new);

/// Same UI -> controller -> events -> repositories -> RacketEngine shape as
/// `PetanqueSessionController`, adapted for single-point scoring
/// (`amount` is always implicitly 1 — no per-round increment picker) and a
/// hierarchical (game/set/match, not flat) auto-completing match. Every
/// `POINT_SCORED` is one point; `RacketEngine` already knows how to derive
/// games/sets, auto-complete the match, and reopen on undo — this
/// controller's only extra responsibility is keeping the persisted
/// `Session.status` in sync with the derived `matchComplete` flag, exactly
/// like Pétanque.
class TennisSessionController extends AsyncNotifier<RacketSessionSnapshot> {
  TennisSessionController(this.sessionId);

  final String sessionId;

  /// Guards [addPoint]/[undoLast] against overlapping calls — a rapid
  /// double-tap on the same scoring zone fires two `onPressed` calls
  /// before either `await` settles, which would otherwise append two
  /// `POINT_SCORED` events for what the user experiences as one tap (see
  /// `PetanqueSessionController._mutationInFlight`, same shape, same
  /// reason — CLAUDE.md brief section 25).
  bool _mutationInFlight = false;

  @override
  Future<RacketSessionSnapshot> build() => _load();

  Future<RacketSessionSnapshot> _load() async {
    final session = await ref
        .read(sessionRepositoryProvider)
        .getSessionById(sessionId);
    if (session == null) {
      throw StateError('Session $sessionId does not exist');
    }
    final events = await ref
        .read(eventRepositoryProvider)
        .getEventsForSession(sessionId);
    return deriveRacketSessionSnapshot(
      status: session.status,
      startedAt: session.startedAt,
      endedAt: session.endedAt,
      events: events,
    );
  }

  /// Records one point for [sideId]. If this completes the match,
  /// persists the session as COMPLETED so it shows up in History — mirrors
  /// `PetanqueSessionController.addRoundPoints`.
  Future<void> addPoint(String sideId) async {
    if (_mutationInFlight) return;
    final current = state.value;
    if (current == null || current.status != SessionStatus.active) return;
    if (current.matchState.matchComplete) return;
    // Authoritative guard, independent of the UI (CLAUDE.md brief section
    // 2): `ActiveTennisSessionPage` already disables the tap zones while a
    // doubles service-order confirmation is pending, but any other future
    // caller of this controller (watch sync, a direct action) must not be
    // able to bypass that gate by calling `addPoint` straight through.
    if (current.matchState.needsServiceConfiguration) return;

    _mutationInFlight = true;
    try {
      final now = DateTime.now().toUtc();
      await ref
          .read(eventRepositoryProvider)
          .appendPhoneEvent(
            id: _uuid.v4(),
            sessionId: sessionId,
            type: SessionEventType.pointScored,
            payload: {'side': sideId, 'amount': 1},
            timestamp: now,
          );
      final reloaded = await _load();
      if (reloaded.matchState.matchComplete) {
        await ref
            .read(sessionRepositoryProvider)
            .completeSession(sessionId, endedAt: now);
      }
      state = AsyncData(await _load());
    } finally {
      _mutationInFlight = false;
    }
  }

  /// Persists a doubles per-segment service-order choice (see
  /// `RacketEngine`'s "Doubles service order" section) — the confirmation
  /// step gating scoring on `matchState.needsServiceConfiguration`
  /// (CLAUDE.md brief section 8). [order] must be built with
  /// `buildDoublesSegmentServiceOrder`, starting from `matchState.
  /// pendingServiceConfigurationSideId` — never an arbitrary side, which
  /// `RacketEngine.replay` would reject anyway (see CLAUDE.md brief
  /// section 9). Guarded by the same [_mutationInFlight] flag as
  /// [addPoint]/[undoLast] so a double-tap on "Continuer" can never
  /// persist two competing configs for the same segment.
  Future<void> configureServiceOrder({
    required int segmentIndex,
    required List<String> order,
  }) async {
    if (_mutationInFlight) return;
    final current = state.value;
    if (current == null || current.status != SessionStatus.active) return;
    if (!current.matchState.needsServiceConfiguration) return;

    _mutationInFlight = true;
    try {
      await ref
          .read(eventRepositoryProvider)
          .appendPhoneEvent(
            id: _uuid.v4(),
            sessionId: sessionId,
            type: SessionEventType.serviceOrderConfigured,
            payload: {
              'schemaVersion': 1,
              'segmentIndex': segmentIndex,
              'order': order,
            },
            timestamp: DateTime.now().toUtc(),
          );
      state = AsyncData(await _load());
    } finally {
      _mutationInFlight = false;
    }
  }

  /// Undoes the last point. If it was the point that auto-completed the
  /// match, `RacketEngine` reopens `matchComplete` — this reopens the
  /// persisted session status to match, so play can continue.
  Future<void> undoLast() async {
    if (_mutationInFlight) return;
    final current = state.value;
    if (current == null || !current.isUndoAvailable) return;
    final wasComplete = current.matchState.matchComplete;
    if (current.status != SessionStatus.active && !wasComplete) return;

    _mutationInFlight = true;
    try {
      await ref
          .read(eventRepositoryProvider)
          .appendPhoneEvent(
            id: _uuid.v4(),
            sessionId: sessionId,
            type: SessionEventType.undo,
            payload: const {},
            timestamp: DateTime.now().toUtc(),
          );
      final reloaded = await _load();
      if (wasComplete && !reloaded.matchState.matchComplete) {
        await ref.read(sessionRepositoryProvider).reopenSession(sessionId);
      }
      state = AsyncData(await _load());
    } finally {
      _mutationInFlight = false;
    }
  }
}
