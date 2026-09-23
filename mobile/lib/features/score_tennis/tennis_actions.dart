import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../app/providers/database_providers.dart';
import '../../domain/events/session_event.dart';
import '../../domain/models/origin_device.dart';
import '../../domain/models/preset_ids.dart';
import '../../domain/models/racket_rule.dart';
import '../../domain/models/scoring_side.dart';
import '../../domain/models/session_category.dart';
import '../../domain/rulesets/tennis_rulesets.dart';
import 'tennis_format.dart';

export '../../domain/models/preset_ids.dart' show tennisPresetRef;

const _uuid = Uuid();

const sideATennisId = 'side_a';
const sideBTennisId = 'side_b';

/// Builds the doubles-ready [ServiceRule]: 2 slots for Simple (one per
/// side, no [ServiceSlot.playerIndex]), 4 for Double — starting from
/// [initialServerSideId]/[initialServerPlayerIndex], then alternating
/// teams, with each side's own partner order fixed to roster order (a
/// deterministic, legal ITF Rule 15/16 order — see the doc note on
/// `TennisDecidingSetChoice` for why the config screen doesn't expose a
/// full 4-way order picker in V1).
ServiceRule buildTennisServiceOrder({
  required TennisMatchType matchType,
  required String initialServerSideId,
  int initialServerPlayerIndex = 0,
}) {
  final otherSideId = initialServerSideId == sideATennisId
      ? sideBTennisId
      : sideATennisId;

  final order = switch (matchType) {
    TennisMatchType.singles => [
      ServiceSlot(id: initialServerSideId, sideId: initialServerSideId),
      ServiceSlot(id: otherSideId, sideId: otherSideId),
    ],
    TennisMatchType.doubles => [
      ServiceSlot(
        id: '${initialServerSideId}_p$initialServerPlayerIndex',
        sideId: initialServerSideId,
        playerIndex: initialServerPlayerIndex,
      ),
      ServiceSlot(id: '${otherSideId}_p0', sideId: otherSideId, playerIndex: 0),
      ServiceSlot(
        id: '${initialServerSideId}_p${1 - initialServerPlayerIndex}',
        sideId: initialServerSideId,
        playerIndex: 1 - initialServerPlayerIndex,
      ),
      ServiceSlot(id: '${otherSideId}_p1', sideId: otherSideId, playerIndex: 1),
    ],
  };

  return ServiceRule(schemaVersion: 1, order: order);
}

/// Resolves [TennisDecidingSetChoice] into the engine-facing
/// `DecidingSetFormat` — the only place this mapping is decided; everything
/// downstream reads it back from the persisted `RacketMatchRule`, never
/// recomputes it (see the note on `RacketSessionSnapshot.racketRule`).
DecidingSetFormat buildDecidingSetFormat(TennisDecidingSetChoice choice) =>
    switch (choice) {
      TennisDecidingSetChoice.tieBreakSet => const RegularDecidingSet(),
      TennisDecidingSetChoice.matchTieBreak10 => const MatchTieBreakDecidingSet(
        matchTieBreak: tennisMatchTieBreak,
      ),
    };

RacketMatchRule buildTennisRule({
  required AdvantageMode advantageMode,
  required TennisDecidingSetChoice decidingSet,
  required ServiceRule service,
}) => tennisItf2026Ruleset(
  advantageMode: advantageMode,
  decidingSetFormat: buildDecidingSetFormat(decidingSet),
  service: service,
);

/// Creates a new Tennis session and its `SESSION_STARTED` event atomically,
/// then returns the new session id — mirrors `startPetanqueSession`'s
/// shape (callers must have already handled the "one active session"
/// choice, see `features/shared/session_actions.dart`).
Future<String> startTennisSession(
  WidgetRef ref, {
  required RacketMatchRule rule,
  required ScoringSide sideA,
  required ScoringSide sideB,
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
          presetRef: tennisPresetRef,
          startedAt: now,
        );
    await ref
        .read(eventRepositoryProvider)
        .appendPhoneEvent(
          id: _uuid.v4(),
          sessionId: sessionId,
          type: SessionEventType.sessionStarted,
          payload: {
            'racketRule': rule.toJson(),
            'sides': [sideA.toJson(), sideB.toJson()],
          },
          timestamp: now,
        );
  });

  return sessionId;
}
