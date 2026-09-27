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

/// Builds segment 0's (the match's first set) [ServiceRule]: 2 slots for
/// Simple (one per side, no [ServiceSlot.playerIndex]), 4 for Double.
///
/// In Doubles, ITF Rule 14 gives *each side* its own independent choice of
/// which player opens its own service — [firstServerPlayerIndex] is
/// [initialServerSideId]'s pick, [secondServerPlayerIndex] is the other
/// side's (for the match's second game). Never infer the second side's
/// choice from the first (CLAUDE.md brief section 6) — a config screen
/// that only exposes one picker silently hands it `playerIndex: 0` always,
/// which is not a real choice.
ServiceRule buildTennisServiceOrder({
  required TennisMatchType matchType,
  required String initialServerSideId,
  int firstServerPlayerIndex = 0,
  int secondServerPlayerIndex = 0,
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
        id: '${initialServerSideId}_p$firstServerPlayerIndex',
        sideId: initialServerSideId,
        playerIndex: firstServerPlayerIndex,
      ),
      ServiceSlot(
        id: '${otherSideId}_p$secondServerPlayerIndex',
        sideId: otherSideId,
        playerIndex: secondServerPlayerIndex,
      ),
      ServiceSlot(
        id: '${initialServerSideId}_p${1 - firstServerPlayerIndex}',
        sideId: initialServerSideId,
        playerIndex: 1 - firstServerPlayerIndex,
      ),
      ServiceSlot(
        id: '${otherSideId}_p${1 - secondServerPlayerIndex}',
        sideId: otherSideId,
        playerIndex: 1 - secondServerPlayerIndex,
      ),
    ],
  };

  return ServiceRule(schemaVersion: 1, order: order);
}

/// Builds a later doubles segment's (set >= 1, or a Match Tie-break
/// replacing the deciding set) reconfigured service order — the payload
/// for a `SERVICE_ORDER_CONFIGURED` event (see `RacketEngine`'s "Doubles
/// service order" section). [startingSideId] must be `RacketMatchState.
/// pendingServiceConfigurationSideId` — the mechanically-correct side,
/// never a free UI choice; only [startingSidePlayerIndex] (that side's
/// pick) and [otherSidePlayerIndex] (the other side's, for the segment's
/// second game) are.
List<String> buildDoublesSegmentServiceOrder({
  required String startingSideId,
  required int startingSidePlayerIndex,
  required int otherSidePlayerIndex,
}) {
  final otherSideId = startingSideId == sideATennisId
      ? sideBTennisId
      : sideATennisId;
  return [
    '${startingSideId}_p$startingSidePlayerIndex',
    '${otherSideId}_p$otherSidePlayerIndex',
    '${startingSideId}_p${1 - startingSidePlayerIndex}',
    '${otherSideId}_p${1 - otherSidePlayerIndex}',
  ];
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
