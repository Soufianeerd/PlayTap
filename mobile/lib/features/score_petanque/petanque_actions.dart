import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../app/providers/database_providers.dart';
import '../../domain/events/session_event.dart';
import '../../domain/models/origin_device.dart';
import '../../domain/models/preset_ids.dart';
import '../../domain/models/score_rule.dart';
import '../../domain/models/score_target.dart';
import '../../domain/models/scoring_side.dart';
import '../../domain/models/session_category.dart';

export '../../domain/models/preset_ids.dart' show petanquePresetRef;

const _uuid = Uuid();

const sideATeamId = 'team_a';
const sideBTeamId = 'team_b';

/// Always 2 scoring sides regardless of format (tête-à-tête/doublette/
/// triplette) — see `playtap-sports-rules`: "joueurs != sides de scoring".
TeamScoreRule buildPetanqueRule() => const TeamScoreRule(
  schemaVersion: 1,
  sideIds: [sideATeamId, sideBTeamId],
  allowedIncrements: [1, 2, 3, 4, 5, 6],
  target: ScoreTarget(targetScore: 13, automaticCompletion: true),
);

/// Creates a new Pétanque session and its `SESSION_STARTED` event
/// atomically, then returns the new session id — mirrors
/// `features/score_free/free_score_actions.dart`'s shape (callers must have
/// already handled the "one active session" choice, see
/// `features/shared/session_actions.dart`).
Future<String> startPetanqueSession(
  WidgetRef ref, {
  required ScoringSide teamA,
  required ScoringSide teamB,
}) async {
  final sessionId = _uuid.v4();
  final now = DateTime.now().toUtc();
  final rule = buildPetanqueRule();

  final db = ref.read(databaseProvider);
  await db.transaction(() async {
    await ref
        .read(sessionRepositoryProvider)
        .createSession(
          id: sessionId,
          category: SessionCategory.score,
          ownerDevice: OriginDevice.phone,
          presetRef: petanquePresetRef,
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
            'sides': [teamA.toJson(), teamB.toJson()],
          },
          timestamp: now,
        );
  });

  return sessionId;
}
