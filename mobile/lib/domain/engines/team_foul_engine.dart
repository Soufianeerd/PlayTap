import '../events/team_foul_engine_event.dart';
import '../models/team_foul_rule.dart';
import '../models/team_foul_state.dart';

/// Pure, deterministic team-foul-counter derivation — one generic engine
/// reused by both Basketball's bonus (FIBA Article 41) and Futsal's
/// accumulated-foul DFKSAF mechanism (see `TeamFoulRule`'s doc note for
/// why these share one abstraction and one reset rule).
///
/// The count resets to zero at every **regulation** `PERIOD_STARTED` and
/// carries forward unchanged into every **overtime** `PERIOD_STARTED` —
/// verified identical for both sports in this phase, so it's the engine's
/// own fixed behavior, not a configurable [TeamFoulRule] field.
abstract final class TeamFoulEngine {
  static TeamFoulState replay(
    TeamFoulRule rule,
    List<String> sideIds,
    List<TeamFoulEngineEvent> events,
  ) {
    final undoneIds = <String>{};
    for (final event in events) {
      if (event.type != TeamFoulEngineEventType.undo) continue;
      final target = event.payload['targetEventId'] as String?;
      if (target != null) undoneIds.add(target);
    }

    var counts = {for (final side in sideIds) side: 0};
    final seenEventIds = <String>{};

    for (final event in events) {
      if (event.type == TeamFoulEngineEventType.undo) continue; // instruction.
      if (undoneIds.contains(event.id)) continue; // this event was undone.
      if (!seenEventIds.add(event.id)) continue; // duplicate id: no-op.

      switch (event.type) {
        case TeamFoulEngineEventType.periodStarted:
          if (event.payload['kind'] == 'REGULATION') {
            // Fresh bracket — overtime deliberately never clears.
            counts = {for (final side in sideIds) side: 0};
          }

        case TeamFoulEngineEventType.foulAdded:
          final sideId = event.payload['sideId'] as String;
          counts[sideId] = (counts[sideId] ?? 0) + 1;

        case TeamFoulEngineEventType.undo:
          break; // unreachable — filtered above.
      }
    }

    return TeamFoulState(
      countsBySide: counts,
      bonusThreshold: rule.bonusThreshold,
    );
  }
}
