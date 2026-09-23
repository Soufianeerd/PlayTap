import '../events/shootout_engine_event.dart';
import '../models/shootout_rule.dart';
import '../models/shootout_state.dart';

/// Pure, deterministic penalty-shootout derivation — generic across
/// Football and Football/Futsal alike (identical [ShootoutRule] shape,
/// identical procedure per IFAB Law 10 / FIFA Futsal Law 10 §3). Shootout
/// score is never merged into match score (see `playtap-score-engine`'s
/// composition note) — this is a fully separate mini-match.
///
/// Undo (including of the decisive attempt) is implemented the same way
/// as `MatchEngine.replay`: filter the undone event out, then forward-
/// replay the remainder — so "undo reopens a decided shootout" falls out
/// for free, with no bespoke reversal logic to get wrong.
abstract final class ShootoutEngine {
  static ShootoutState replay(
    ShootoutRule rule,
    List<String> sideIds,
    List<ShootoutEngineEvent> events,
  ) {
    assert(sideIds.length == 2, 'Shootout is defined for exactly two sides.');
    final sideA = sideIds[0];
    final sideB = sideIds[1];

    final undoneIds = <String>{};
    for (final event in events) {
      if (event.type != ShootoutEngineEventType.undo) continue;
      final target = event.payload['targetEventId'] as String?;
      if (target != null) undoneIds.add(target);
    }

    final attempts = <ShootoutAttempt>[];
    final kicksTaken = {sideA: 0, sideB: 0};
    final scores = {sideA: 0, sideB: 0};
    var decided = false;
    String? winner;
    final seenEventIds = <String>{};

    for (final event in events) {
      if (event.type == ShootoutEngineEventType.undo) continue; // instruction.
      if (undoneIds.contains(event.id)) continue; // this event was undone.
      if (!seenEventIds.add(event.id)) continue; // duplicate id: no-op.
      if (event.type != ShootoutEngineEventType.shootoutAttempt) {
        continue; // shootoutStarted/shootoutCompleted carry no state here.
      }
      if (decided) continue; // shootout over: no more kicks.

      final side = event.payload['side'] as String?;
      final scored = event.payload['scored'] as bool?;
      if (side == null || scored == null || !kicksTaken.containsKey(side)) {
        continue; // unknown side / malformed payload: ignored, not fatal.
      }
      final expectedKicker = kicksTaken[sideA]! == kicksTaken[sideB]!
          ? sideA
          : sideB;
      if (side != expectedKicker) {
        continue; // out-of-order kick: ignored, not fatal.
      }

      attempts.add(
        ShootoutAttempt(eventId: event.id, side: side, scored: scored),
      );
      kicksTaken[side] = kicksTaken[side]! + 1;
      if (scored) scores[side] = scores[side]! + 1;

      final bothPastInitialRound =
          kicksTaken[sideA]! >= rule.kicksPerRound &&
          kicksTaken[sideB]! >= rule.kicksPerRound;

      if (!bothPastInitialRound) {
        // Early termination: decided as soon as the trailing side can no
        // longer catch up even if it scored every kick it has left in the
        // initial round — computed generically from `kicksPerRound`,
        // never a hardcoded "5". This formula also naturally covers "not
        // level after the full initial round" (remaining == 0 for both).
        final remainingA = rule.kicksPerRound - kicksTaken[sideA]!;
        final remainingB = rule.kicksPerRound - kicksTaken[sideB]!;
        if (scores[sideA]! > scores[sideB]! + remainingB) {
          decided = true;
          winner = sideA;
        } else if (scores[sideB]! > scores[sideA]! + remainingA) {
          decided = true;
          winner = sideB;
        }
      } else if (rule.suddenDeath &&
          kicksTaken[sideA] == kicksTaken[sideB] &&
          scores[sideA] != scores[sideB]) {
        // Sudden death: decided once both have taken their kick in the
        // same round and the scores now differ.
        decided = true;
        winner = scores[sideA]! > scores[sideB]! ? sideA : sideB;
      }
    }

    final bothPastInitialRound =
        kicksTaken[sideA]! >= rule.kicksPerRound &&
        kicksTaken[sideB]! >= rule.kicksPerRound;
    final stalemateNoSuddenDeath =
        bothPastInitialRound && !rule.suddenDeath && !decided;

    return ShootoutState(
      attempts: attempts,
      scores: scores,
      nextKicker: decided || stalemateNoSuddenDeath
          ? null
          : (kicksTaken[sideA]! == kicksTaken[sideB]! ? sideA : sideB),
      decided: decided,
      winner: winner,
    );
  }
}
