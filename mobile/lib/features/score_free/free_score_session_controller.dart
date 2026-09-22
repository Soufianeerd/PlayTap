import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../app/providers/database_providers.dart';
import '../../domain/engines/score_session_deriver.dart';
import '../../domain/events/session_event.dart';
import '../../domain/models/score_session_snapshot.dart';
import '../../domain/models/session_status.dart';

const _uuid = Uuid();

final freeScoreSessionControllerProvider =
    AsyncNotifierProvider.family<
      FreeScoreSessionController,
      ScoreSessionSnapshot,
      String
    >(FreeScoreSessionController.new);

/// UI -> this controller -> event creation -> repositories -> ScoreEngine
/// replay -> ScoreState -> UI (see CLAUDE.md / the Phase 1B.1 brief). The
/// engine itself stays pure; only this controller knows about Riverpod.
class FreeScoreSessionController extends AsyncNotifier<ScoreSessionSnapshot> {
  FreeScoreSessionController(this.sessionId);

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

  Future<void> addPoint(String sideId) async {
    final current = state.value;
    if (current == null || current.status != SessionStatus.active) return;

    await ref
        .read(eventRepositoryProvider)
        .appendPhoneEvent(
          id: _uuid.v4(),
          sessionId: sessionId,
          type: SessionEventType.pointScored,
          payload: {'side': sideId, 'amount': 1},
          timestamp: DateTime.now().toUtc(),
        );
    state = AsyncData(await _load());
  }

  Future<void> undoLast() async {
    final current = state.value;
    if (current == null ||
        current.status != SessionStatus.active ||
        !current.isUndoAvailable) {
      return;
    }

    await ref
        .read(eventRepositoryProvider)
        .appendPhoneEvent(
          id: _uuid.v4(),
          sessionId: sessionId,
          type: SessionEventType.undo,
          payload: const {},
          timestamp: DateTime.now().toUtc(),
        );
    state = AsyncData(await _load());
  }

  Future<void> complete() async {
    final current = state.value;
    if (current == null || current.status != SessionStatus.active) return;

    final db = ref.read(databaseProvider);
    final now = DateTime.now().toUtc();
    await db.transaction(() async {
      await ref
          .read(eventRepositoryProvider)
          .appendPhoneEvent(
            id: _uuid.v4(),
            sessionId: sessionId,
            type: SessionEventType.sessionCompleted,
            payload: const {},
            timestamp: now,
          );
      await ref
          .read(sessionRepositoryProvider)
          .completeSession(sessionId, endedAt: now);
    });
    state = AsyncData(await _load());
  }
}
