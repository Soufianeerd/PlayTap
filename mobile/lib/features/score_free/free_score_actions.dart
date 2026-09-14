import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../app/providers/database_providers.dart';
import '../../domain/events/session_event.dart';
import '../../domain/models/origin_device.dart';
import '../../domain/models/score_rule.dart';
import '../../domain/models/scoring_side.dart';
import '../../domain/models/session_category.dart';

const _uuid = Uuid();
const _freeScorePresetRef = 'free_score';

/// Creates a new Score Libre session and its SESSION_STARTED event
/// atomically, then returns the new session id (see docs/RELEASE_0_1.md —
/// callers must have already handled the "one active session" choice, see
/// `features/shared/session_actions.dart`).
Future<String> startFreeScoreSession(
  WidgetRef ref,
  List<ScoringSide> sides,
) async {
  final sessionId = _uuid.v4();
  final now = DateTime.now().toUtc();
  final rule = FreeScoreRule(
    schemaVersion: 1,
    sideIds: sides.map((s) => s.id).toList(),
    defaultIncrement: 1,
  );

  final db = ref.read(databaseProvider);
  await db.transaction(() async {
    await ref
        .read(sessionRepositoryProvider)
        .createSession(
          id: sessionId,
          category: SessionCategory.score,
          ownerDevice: OriginDevice.phone,
          presetRef: _freeScorePresetRef,
          startedAt: now,
        );
    await ref
        .read(eventRepositoryProvider)
        .appendPhoneEvent(
          id: _uuid.v4(),
          sessionId: sessionId,
          type: SessionEventType.sessionStarted,
          payload: {
            'scoreRule': rule.toJson(),
            'sides': sides.map((s) => s.toJson()).toList(),
          },
          timestamp: now,
        );
  });

  return sessionId;
}
