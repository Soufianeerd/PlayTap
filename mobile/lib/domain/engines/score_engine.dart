import '../events/score_engine_event.dart';
import '../models/score_rule.dart';
import '../models/score_state.dart';

/// Pure, deterministic score derivation — see `playtap-score-engine`.
///
/// No Flutter, no Riverpod, no Drift, no I/O, no clock: `replay` is a plain
/// function of its two arguments. `state = replay(events)` must hold for
/// any prefix or full replay of the same event list, every time.
abstract final class ScoreEngine {
  static ScoreState replay(ScoreRule rule, List<ScoreEngineEvent> events) {
    return switch (rule) {
      FreeScoreRule() => _replayFreeScore(rule, events),
    };
  }

  static ScoreState _replayFreeScore(
    FreeScoreRule rule,
    List<ScoreEngineEvent> events,
  ) {
    final knownSides = rule.sideIds.toSet();

    // Points recorded in processing order; each carries whether it has
    // since been undone. Undo always targets the most recent not-yet-undone
    // point unless a specific `targetEventId` is given.
    final pointEventIds = <String>[];
    final pointSideById = <String, String>{};
    final pointAmountById = <String, int>{};
    final undoneEventIds = <String>{};
    final seenEventIds = <String>{};

    final scores = {for (final side in rule.sideIds) side: 0};
    var appliedEventCount = 0;
    var matchComplete = false;

    for (final event in events) {
      if (matchComplete) break; // SESSION_COMPLETED ends replay defensively.
      if (!seenEventIds.add(event.id)) continue; // duplicate id: no-op.

      switch (event.type) {
        case ScoreEngineEventType.pointScored:
          final sideId = event.payload['side'] as String?;
          final amount = event.payload['amount'];
          if (sideId == null ||
              !knownSides.contains(sideId) ||
              amount is! int ||
              amount <= 0) {
            continue; // unknown side / invalid increment: ignored, not fatal.
          }
          pointEventIds.add(event.id);
          pointSideById[event.id] = sideId;
          pointAmountById[event.id] = amount;
          scores[sideId] = scores[sideId]! + amount;
          appliedEventCount++;

        case ScoreEngineEventType.undo:
          final targetId = event.payload['targetEventId'] as String?;
          final resolvedTarget =
              targetId ??
              pointEventIds.reversed.firstWhere(
                (id) => !undoneEventIds.contains(id),
                orElse: () => '',
              );
          if (resolvedTarget.isEmpty ||
              !pointSideById.containsKey(resolvedTarget) ||
              undoneEventIds.contains(resolvedTarget)) {
            continue; // nothing eligible to undo: no-op, never throws.
          }
          undoneEventIds.add(resolvedTarget);
          final side = pointSideById[resolvedTarget]!;
          scores[side] = scores[side]! - pointAmountById[resolvedTarget]!;

        case ScoreEngineEventType.sessionCompleted:
          matchComplete = true;
      }
    }

    String? winner;
    if (matchComplete && scores.isNotEmpty) {
      final maxScore = scores.values.reduce((a, b) => a > b ? a : b);
      final leaders = scores.entries.where((e) => e.value == maxScore);
      winner = leaders.length == 1 ? leaders.first.key : null;
    }

    return ScoreState(
      scores: scores,
      matchComplete: matchComplete,
      winner: winner,
      appliedEventCount: appliedEventCount,
    );
  }
}
