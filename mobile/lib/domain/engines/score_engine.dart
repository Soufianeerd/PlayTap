import '../events/score_engine_event.dart';
import '../models/score_rule.dart';
import '../models/score_round.dart';
import '../models/score_state.dart';
import '../models/score_target.dart';

/// Pure, deterministic score derivation — see `playtap-score-engine`.
///
/// No Flutter, no Riverpod, no Drift, no I/O, no clock: `replay` is a plain
/// function of its two arguments. `state = replay(events)` must hold for
/// any prefix or full replay of the same event list, every time.
abstract final class ScoreEngine {
  static ScoreState replay(ScoreRule rule, List<ScoreEngineEvent> events) {
    return switch (rule) {
      FreeScoreRule() => _replayFreeScore(rule, events),
      TargetScoreRule() => _replayPointBased(
        sideIds: rule.sideIds,
        events: events,
        target: rule.target,
        resolveAmount: (raw) {
          if (raw == null) return 1; // TARGET_SCORE always scores 1/event.
          return raw is int && raw == 1 ? 1 : null;
        },
      ),
      TeamScoreRule() => _replayPointBased(
        sideIds: rule.sideIds,
        events: events,
        target: rule.target,
        resolveAmount: (raw) =>
            raw is int && rule.allowedIncrements.contains(raw) ? raw : null,
      ),
    };
  }

  /// Shared core for every mode that scores via plain `POINT_SCORED`
  /// events and optionally ends automatically once a side crosses a
  /// [ScoreTarget] — see the composition note on `ScoreRule`. [FreeScoreRule]
  /// deliberately does *not* go through this path (kept as
  /// [_replayFreeScore], untouched, to guarantee zero regression risk on an
  /// already-shipped mode).
  ///
  /// Undo is always reversible, including the round that just completed the
  /// match: undoing the exact `POINT_SCORED` event that crossed the target
  /// reopens the match (`matchComplete` back to false) rather than the undo
  /// being silently dropped — see `playtap-score-engine` "Undo obligatoire"
  /// and the Pétanque brief section 14.
  static ScoreState _replayPointBased({
    required List<String> sideIds,
    required List<ScoreEngineEvent> events,
    required ScoreTarget? target,
    required int? Function(dynamic rawAmount) resolveAmount,
  }) {
    final knownSides = sideIds.toSet();

    final pointEventIds = <String>[];
    final pointSideById = <String, String>{};
    final pointAmountById = <String, int>{};
    final undoneEventIds = <String>{};
    final seenEventIds = <String>{};

    final scores = {for (final side in sideIds) side: 0};
    var appliedEventCount = 0;
    var matchComplete = false;
    String? winner;
    String? completionEventId;

    for (final event in events) {
      if (!seenEventIds.add(event.id)) continue; // duplicate id: no-op.

      switch (event.type) {
        case ScoreEngineEventType.pointScored:
          if (matchComplete) continue; // match over: no more scoring.
          final sideId = event.payload['side'] as String?;
          final amount = resolveAmount(event.payload['amount']);
          if (sideId == null ||
              !knownSides.contains(sideId) ||
              amount == null) {
            continue; // unknown side / invalid increment: ignored, not fatal.
          }
          pointEventIds.add(event.id);
          pointSideById[event.id] = sideId;
          pointAmountById[event.id] = amount;
          scores[sideId] = scores[sideId]! + amount;
          appliedEventCount++;

          if (target != null && target.automaticCompletion) {
            final leaderScore = scores[sideId]!;
            if (leaderScore >= target.targetScore &&
                _marginSatisfied(target, sideId, scores)) {
              matchComplete = true;
              winner = sideId;
              completionEventId = event.id;
            }
          }

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
          if (resolvedTarget == completionEventId) {
            // Undoing the round that ended the match reopens it.
            matchComplete = false;
            winner = null;
            completionEventId = null;
          }

        case ScoreEngineEventType.sessionCompleted:
          if (matchComplete) continue; // already over: no-op.
          matchComplete = true;
          completionEventId = null; // manual: not tied to a specific round.
          if (scores.isNotEmpty) {
            final maxScore = scores.values.reduce((a, b) => a > b ? a : b);
            final leaders = scores.entries.where((e) => e.value == maxScore);
            winner = leaders.length == 1 ? leaders.first.key : null;
          }
      }
    }

    final rounds = [
      for (final id in pointEventIds)
        if (!undoneEventIds.contains(id))
          ScoreRound(sideId: pointSideById[id]!, amount: pointAmountById[id]!),
    ];

    return ScoreState(
      scores: scores,
      matchComplete: matchComplete,
      winner: winner,
      appliedEventCount: appliedEventCount,
      rounds: rounds,
    );
  }

  /// True when [target] has no win-by-margin clause, or when [sideId]'s
  /// margin over every other side already meets it.
  static bool _marginSatisfied(
    ScoreTarget target,
    String sideId,
    Map<String, int> scores,
  ) {
    final winBy = target.winBy;
    if (winBy == null || !winBy.enabled) return true;
    final leaderScore = scores[sideId]!;
    final otherMax = scores.entries
        .where((e) => e.key != sideId)
        .map((e) => e.value)
        .fold<int>(0, (a, b) => a > b ? a : b);
    return (leaderScore - otherMax) >= winBy.margin;
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
