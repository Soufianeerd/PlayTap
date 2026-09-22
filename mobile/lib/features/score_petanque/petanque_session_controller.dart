import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../app/providers/database_providers.dart';
import '../../domain/engines/score_session_deriver.dart';
import '../../domain/events/session_event.dart';
import '../../domain/models/score_session_snapshot.dart';
import '../../domain/models/session_status.dart';

const _uuid = Uuid();

final petanqueSessionControllerProvider =
    AsyncNotifierProvider.family<
      PetanqueSessionController,
      ScoreSessionSnapshot,
      String
    >(PetanqueSessionController.new);

/// Same UI -> controller -> events -> repositories -> ScoreEngine shape as
/// `FreeScoreSessionController`, adapted for a round-based, variable
/// increment (1-6) and auto-completing match — see `playtap-score-engine`
/// and the Pétanque brief sections 10-14. The engine itself already knows
/// how to auto-complete at 13 and reopen on undo (`ScoreEngine.
/// _replayPointBased`); this controller's only extra responsibility is
/// keeping the persisted `Session.status` in sync with that derived
/// `matchComplete` flag, since status lives outside the event log.
class PetanqueSessionController extends AsyncNotifier<ScoreSessionSnapshot> {
  PetanqueSessionController(this.sessionId);

  final String sessionId;

  @override
  Future<ScoreSessionSnapshot> build() => _load();

  Future<ScoreSessionSnapshot> _load() async {
    final session = await ref
        .read(sessionRepositoryProvider)
        .getSessionById(sessionId);
    if (session == null) {
      throw StateError('Session $sessionId does not exist');
    }
    final events = await ref
        .read(eventRepositoryProvider)
        .getEventsForSession(sessionId);
    return deriveScoreSessionSnapshot(
      status: session.status,
      startedAt: session.startedAt,
      endedAt: session.endedAt,
      events: events,
    );
  }

  /// Records one mène: [sideId] scored [amount] points (1-6). If this
  /// crosses the target (13+), the match auto-completes — see
  /// `ScoreEngine._replayPointBased` — and this method persists that as
  /// the session's COMPLETED status so it shows up in History.
  Future<void> addRoundPoints(String sideId, int amount) async {
    final current = state.value;
    if (current == null || current.status != SessionStatus.active) return;

    final now = DateTime.now().toUtc();
    await ref
        .read(eventRepositoryProvider)
        .appendPhoneEvent(
          id: _uuid.v4(),
          sessionId: sessionId,
          type: SessionEventType.pointScored,
          payload: {'side': sideId, 'amount': amount},
          timestamp: now,
        );
    final reloaded = await _load();
    if (reloaded.scoreState.matchComplete) {
      await ref
          .read(sessionRepositoryProvider)
          .completeSession(sessionId, endedAt: now);
    }
    state = AsyncData(await _load());
  }

  /// Undoes the last mène. If it was the mène that auto-completed the
  /// match, the engine reopens `matchComplete` — this reopens the
  /// persisted session status to match, so play can continue (see
  /// `SessionRepository.reopenSession`).
  Future<void> undoLast() async {
    final current = state.value;
    if (current == null || !current.isUndoAvailable) return;
    final wasComplete = current.scoreState.matchComplete;
    if (current.status != SessionStatus.active && !wasComplete) return;

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
    if (wasComplete && !reloaded.scoreState.matchComplete) {
      await ref.read(sessionRepositoryProvider).reopenSession(sessionId);
    }
    state = AsyncData(await _load());
  }
}
