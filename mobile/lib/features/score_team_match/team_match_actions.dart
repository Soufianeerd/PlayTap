import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../app/providers/database_providers.dart';
import '../../domain/events/session_event.dart';
import '../../domain/models/match_rule.dart';
import '../../domain/models/origin_device.dart';
import '../../domain/models/scoring_side.dart';
import '../../domain/models/session_category.dart';

const _uuid = Uuid();

const sideATeamId = 'team_a';
const sideBTeamId = 'team_b';

/// Creates a new team-match session (Basketball/Football/Futsal — see
/// `MatchRule`) and its `SESSION_STARTED` + first `PERIOD_STARTED` events
/// atomically, then returns the new session id — mirrors
/// `features/score_petanque/petanque_actions.dart#startPetanqueSession`'s
/// shape. The period's clock is deliberately **not** started here: the
/// match exists and its first period is open, but the clock only starts
/// once the user taps the active session's START control (mirrors how a
/// referee starts play, not session creation) — see
/// `TeamMatchSessionController.togglePlayPause`. [presetRef] is what
/// `features/shared/session_actions.dart` routes on to tell the three
/// sports apart.
Future<String> startTeamMatchSession(
  WidgetRef ref, {
  required MatchRule matchRule,
  required ScoringSide teamA,
  required ScoringSide teamB,
  required String presetRef,
}) async {
  final sessionId = _uuid.v4();
  final now = DateTime.now().toUtc();

  final db = ref.read(databaseProvider);
  await db.transaction(() async {
    await ref
        .read(sessionRepositoryProvider)
        .createSession(
          id: sessionId,
          category: SessionCategory.score,
          ownerDevice: OriginDevice.phone,
          presetRef: presetRef,
          startedAt: now,
        );
    await ref
        .read(eventRepositoryProvider)
        .appendPhoneEvent(
          id: _uuid.v4(),
          sessionId: sessionId,
          type: SessionEventType.sessionStarted,
          payload: {
            'matchRule': matchRule.toJson(),
            'sides': [teamA.toJson(), teamB.toJson()],
          },
          timestamp: now,
        );
    await ref
        .read(eventRepositoryProvider)
        .appendPhoneEvent(
          id: _uuid.v4(),
          sessionId: sessionId,
          type: SessionEventType.periodStarted,
          payload: const {'periodIndex': 0, 'kind': 'REGULATION'},
          timestamp: now,
        );
  });

  return sessionId;
}
