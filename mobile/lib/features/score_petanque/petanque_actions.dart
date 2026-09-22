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
import 'petanque_format.dart';

export '../../domain/models/preset_ids.dart' show petanquePresetRef;

const _uuid = Uuid();

const sideATeamId = 'team_a';
const sideBTeamId = 'team_b';

/// Always 2 scoring sides regardless of format (tête-à-tête/doublette/
/// triplette) — see `playtap-sports-rules`: "joueurs != sides de scoring".
/// [format] drives the persisted `allowedIncrements`: tête-à-tête maxes out
/// at +3 (1 player × 3 boules), doublette/triplette at +6 — see
/// `PetanqueFormat.allowedIncrements` and docs/SPORT_RULES.md (FIPJP
/// Article 1). This is the *only* place `allowedIncrements` is decided;
/// everything downstream (the active session UI) reads it back from the
/// persisted `ScoreRule`, never recomputes it — see the note on
/// `ScoreSessionSnapshot.scoreRule`.
TeamScoreRule buildPetanqueRule(PetanqueFormat format) => TeamScoreRule(
  schemaVersion: 1,
  sideIds: const [sideATeamId, sideBTeamId],
  allowedIncrements: format.allowedIncrements,
  target: const ScoreTarget(targetScore: 13, automaticCompletion: true),
);

/// Creates a new Pétanque session and its `SESSION_STARTED` event
/// atomically, then returns the new session id — mirrors
/// `features/score_free/free_score_actions.dart`'s shape (callers must have
/// already handled the "one active session" choice, see
/// `features/shared/session_actions.dart`).
Future<String> startPetanqueSession(
  WidgetRef ref, {
  required PetanqueFormat format,
  required ScoringSide teamA,
  required ScoringSide teamB,
}) async {
  final sessionId = _uuid.v4();
  final now = DateTime.now().toUtc();
  final rule = buildPetanqueRule(format);

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
