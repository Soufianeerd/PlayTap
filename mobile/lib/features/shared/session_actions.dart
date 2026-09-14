import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../app/providers/database_providers.dart';
import '../../data/repositories/session_repository.dart';
import '../../domain/events/session_event.dart';
import '../../domain/models/session_category.dart';

const _uuid = Uuid();

/// Abandons an in-progress session, whatever its category (see
/// docs/DATA_MODEL.md — ABANDONED is distinct from COMPLETED and excluded
/// from the main history). Generic: contains no Score/Timer-specific rule.
Future<void> abandonSession(WidgetRef ref, String sessionId) async {
  final now = DateTime.now().toUtc();
  final db = ref.read(databaseProvider);
  await db.transaction(() async {
    await ref
        .read(eventRepositoryProvider)
        .appendPhoneEvent(
          id: _uuid.v4(),
          sessionId: sessionId,
          type: SessionEventType.sessionAbandoned,
          payload: const {},
          timestamp: now,
        );
    await ref
        .read(sessionRepositoryProvider)
        .abandonSession(sessionId, endedAt: now);
  });
}

/// Where "REPRENDRE" should navigate for a given active session — see
/// section 26/27 of the Phase 1B.2 brief: Home's resume CTA and the
/// "session already active" dialog must route by category generically,
/// not assume Score Libre.
String activeSessionRoute(SessionSummary session) {
  return switch (session.category) {
    SessionCategory.score => '/score/free/session/${session.id}',
    SessionCategory.timer => '/timer/session/${session.id}',
    SessionCategory.training => throw UnimplementedError(
      'Training sessions do not exist yet',
    ),
    SessionCategory.custom => throw UnimplementedError(
      'Custom sessions do not exist yet',
    ),
  };
}
