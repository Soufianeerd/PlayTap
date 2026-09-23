import '../events/racket_engine_event.dart';
import '../models/racket_rule.dart';
import '../models/racket_state.dart';

/// Pure, deterministic racket-match derivation — see `playtap-score-engine`
/// and the architecture note on `RacketMatchRule`. No Flutter, no
/// Riverpod, no Drift, no I/O, no clock: `replay` is a plain function of
/// its two arguments, exactly like `ScoreEngine.replay`/`MatchEngine.
/// replay`.
///
/// ## Why full re-simulation instead of incremental state
///
/// `ScoreEngine` can undo in O(1) (subtract the undone point's amount)
/// because a flat score is additive. Games/sets are not: removing an
/// arbitrary point from the middle of a match changes everything that
/// followed it (which side served, whether a tie-break was ever entered,
/// ...). So `replay` resolves the full *undo-adjusted* ordered list of
/// surviving points first, then walks a pure state machine over exactly
/// that list from scratch every time (see [_simulate]) — cheap in
/// practice (a tennis match is at most a few hundred points), and it's
/// the only way undo of a non-latest point stays correct. `appliedEventCount`
/// and "no more points accepted once the match is complete" are still
/// computed incrementally over the *raw* event stream (mirroring
/// `ScoreEngine._replayPointBased` exactly), so behavior matches the rest
/// of the codebase's engines event-for-event.
abstract final class RacketEngine {
  static RacketMatchState replay(
    RacketMatchRule rule,
    List<RacketEngineEvent> events,
  ) {
    final seenEventIds = <String>{};
    final pointEventIds = <String>[];
    final pointSideById = <String, String>{};
    final undoneEventIds = <String>{};
    var appliedEventCount = 0;
    var manuallyCompleted = false;
    var sim = _simulate(rule, const []);

    for (final event in events) {
      if (!seenEventIds.add(event.id)) continue; // duplicate id: no-op.

      switch (event.type) {
        case RacketEngineEventType.pointScored:
          if (sim.matchComplete || manuallyCompleted) {
            continue; // match over: no more scoring.
          }
          final sideId = event.payload['side'] as String?;
          if (sideId == null || !rule.sideIds.contains(sideId)) {
            continue; // unknown side: ignored, not fatal.
          }
          pointEventIds.add(event.id);
          pointSideById[event.id] = sideId;
          appliedEventCount++;
          sim = _simulate(
            rule,
            _effectivePoints(pointEventIds, pointSideById, undoneEventIds),
          );

        case RacketEngineEventType.undo:
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
          // Undoing the point that just completed the match reopens it —
          // `_simulate` naturally stops short of `matchComplete` once that
          // point is removed from the surviving list (see the class doc).
          sim = _simulate(
            rule,
            _effectivePoints(pointEventIds, pointSideById, undoneEventIds),
          );

        case RacketEngineEventType.sessionCompleted:
          if (sim.matchComplete) continue; // already over: no-op.
          // Manual completion (mirrors `ScoreEngine`'s FreeScoreRule/
          // manual-TeamScore path): permanent, never reopened by a later
          // UNDO — see `ScoreEngine._replayPointBased`'s `completionEventId
          // == null` case, which this deliberately matches.
          manuallyCompleted = true;
      }
    }

    final matchComplete = sim.matchComplete || manuallyCompleted;
    var winner = sim.winner;
    if (manuallyCompleted && winner == null) {
      winner = _leaderBySets(rule, sim.setsWon);
    }

    return RacketMatchState(
      currentGamePoints: sim.currentGamePoints,
      gamesWonInCurrentSet: sim.gamesWonInCurrentSet,
      setsWon: sim.setsWon,
      completedSets: sim.completedSets,
      currentSetIndex: sim.currentSetIndex,
      isTieBreak: sim.isTieBreak,
      isMatchTieBreak: sim.isMatchTieBreak,
      tieBreakPoints: sim.tieBreakPoints,
      currentServerSlotId: sim.currentServerSlotId,
      matchComplete: matchComplete,
      winner: winner,
      appliedEventCount: appliedEventCount,
      changeEndsDue: sim.changeEndsDue,
    );
  }

  static List<String> _effectivePoints(
    List<String> pointEventIds,
    Map<String, String> pointSideById,
    Set<String> undoneEventIds,
  ) => [
    for (final id in pointEventIds)
      if (!undoneEventIds.contains(id)) pointSideById[id]!,
  ];

  /// Strictly-higher-sets side, or null on an exact tie (retirement with
  /// sets even — no forced winner, mirrors `FreeScoreRule`'s tie handling).
  static String? _leaderBySets(RacketMatchRule rule, Map<String, int> setsWon) {
    final maxSets = setsWon.values.reduce((a, b) => a > b ? a : b);
    final leaders = setsWon.entries.where((e) => e.value == maxSets);
    return leaders.length == 1 ? leaders.first.key : null;
  }

  /// The pure point→game→set→match state machine — see the class doc for
  /// why this always runs over the full surviving point list rather than
  /// incrementally. [orderedSides] is the side id of each surviving
  /// `POINT_SCORED`, in application order.
  static _SimResult _simulate(RacketMatchRule rule, List<String> orderedSides) {
    final sideIds = rule.sideIds;
    assert(sideIds.length == 2, 'RacketMatchRule always has exactly 2 sides');
    final sideA = sideIds[0];
    final sideB = sideIds[1];
    String other(String side) => side == sideA ? sideB : sideA;

    var gamePoints = {sideA: 0, sideB: 0};
    var gamesInSet = {sideA: 0, sideB: 0};
    var setsWon = {sideA: 0, sideB: 0};
    var tieBreakPoints = {sideA: 0, sideB: 0};
    var setIndex = 0;
    var isTieBreak = false;
    var isMatchTieBreak = false;
    var totalGamesForRotation = 0;
    var tieBreakRotationBase = 0;
    final completedSets = <RacketSetResult>[];
    var matchComplete = false;
    String? winner;

    bool decidingSetIsMatchTieBreak(int idx) =>
        idx == rule.matchFormat.decidingSetIndex &&
        rule.matchFormat.decidingSetFormat is MatchTieBreakDecidingSet;

    for (final side in orderedSides) {
      if (matchComplete) break;
      final opp = other(side);

      if (isMatchTieBreak) {
        tieBreakPoints[side] = tieBreakPoints[side]! + 1;
        final mtb =
            (rule.matchFormat.decidingSetFormat as MatchTieBreakDecidingSet)
                .matchTieBreak;
        final my = tieBreakPoints[side]!;
        final theirs = tieBreakPoints[opp]!;
        if (my >= mtb.target && (my - theirs) >= mtb.winBy) {
          setsWon[side] = setsWon[side]! + 1;
          completedSets.add(
            RacketSetResult(
              games: {sideA: 0, sideB: 0},
              tieBreakScore: Map.of(tieBreakPoints),
              isMatchTieBreak: true,
            ),
          );
          matchComplete = true;
          winner = side;
        }
        continue;
      }

      if (isTieBreak) {
        tieBreakPoints[side] = tieBreakPoints[side]! + 1;
        final tb = rule.setRule.tieBreak!;
        final my = tieBreakPoints[side]!;
        final theirs = tieBreakPoints[opp]!;
        if (my >= tb.target && (my - theirs) >= tb.winBy) {
          gamesInSet[side] = gamesInSet[side]! + 1;
          totalGamesForRotation++;
          setsWon[side] = setsWon[side]! + 1;
          completedSets.add(
            RacketSetResult(
              games: Map.of(gamesInSet),
              tieBreakScore: Map.of(tieBreakPoints),
            ),
          );
          setIndex++;
          gamesInSet = {sideA: 0, sideB: 0};
          tieBreakPoints = {sideA: 0, sideB: 0};
          isTieBreak = false;
          if (setsWon[side]! >= rule.matchFormat.setsToWin) {
            matchComplete = true;
            winner = side;
          } else if (decidingSetIsMatchTieBreak(setIndex)) {
            isMatchTieBreak = true;
            tieBreakRotationBase = totalGamesForRotation;
          }
        }
        continue;
      }

      // Standard game point.
      gamePoints[side] = gamePoints[side]! + 1;
      final marginNeeded = rule.gameScoring.advantageMode == AdvantageMode.noAd
          ? 1
          : 2;
      final my = gamePoints[side]!;
      final theirs = gamePoints[opp]!;
      if (my >= 4 && (my - theirs) >= marginNeeded) {
        gamesInSet[side] = gamesInSet[side]! + 1;
        totalGamesForRotation++;
        gamePoints = {sideA: 0, sideB: 0};
        final myGames = gamesInSet[side]!;
        final oppGames = gamesInSet[opp]!;
        final tieBreak = rule.setRule.tieBreak;

        if (myGames >= rule.setRule.gamesToWin && (myGames - oppGames) >= 2) {
          setsWon[side] = setsWon[side]! + 1;
          completedSets.add(RacketSetResult(games: Map.of(gamesInSet)));
          setIndex++;
          gamesInSet = {sideA: 0, sideB: 0};
          if (setsWon[side]! >= rule.matchFormat.setsToWin) {
            matchComplete = true;
            winner = side;
          } else if (decidingSetIsMatchTieBreak(setIndex)) {
            isMatchTieBreak = true;
            tieBreakRotationBase = totalGamesForRotation;
          }
        } else if (tieBreak != null &&
            myGames == rule.setRule.gamesToWin &&
            oppGames == rule.setRule.gamesToWin) {
          isTieBreak = true;
          tieBreakRotationBase = totalGamesForRotation;
        }
      }
    }

    final currentServerSlotId = isTieBreak || isMatchTieBreak
        ? _tieBreakServerSlot(
            rule,
            tieBreakRotationBase,
            tieBreakPoints[sideA]! + tieBreakPoints[sideB]! + 1,
          )
        : _gameServerSlot(rule, totalGamesForRotation);

    final changeEndsDue = isTieBreak || isMatchTieBreak
        ? (tieBreakPoints[sideA]! + tieBreakPoints[sideB]!) > 0 &&
              (tieBreakPoints[sideA]! + tieBreakPoints[sideB]!) % 6 == 0
        : totalGamesForRotation.isOdd;

    return _SimResult(
      currentGamePoints: gamePoints,
      gamesWonInCurrentSet: gamesInSet,
      setsWon: setsWon,
      completedSets: completedSets,
      currentSetIndex: setIndex,
      isTieBreak: isTieBreak,
      isMatchTieBreak: isMatchTieBreak,
      tieBreakPoints: tieBreakPoints,
      currentServerSlotId: currentServerSlotId,
      matchComplete: matchComplete,
      winner: winner,
      changeEndsDue: changeEndsDue,
    );
  }

  /// ITF Rule 15 (Order of Service): the server rotates by one slot every
  /// completed game (a tie-break counts as exactly one game for this
  /// purpose — see [_tieBreakServerSlot]), continuously across set
  /// boundaries — never reset per set.
  static String _gameServerSlot(RacketMatchRule rule, int gamesCompleted) {
    final order = rule.service.order;
    return order[gamesCompleted % order.length].id;
  }

  /// ITF Rule 15: within a tie-break, the player next in rotation serves
  /// point 1 alone, then service alternates every 2 points thereafter
  /// (points 2-3 the other side, 4-5 back, ...) — never approximated as a
  /// simple per-point alternation (CLAUDE.md brief section 13).
  /// [rotationBaseGames] is [totalGamesForRotation] frozen at the moment
  /// the tie-break started; [pointNumber] is the 1-based point about to be
  /// played.
  static String _tieBreakServerSlot(
    RacketMatchRule rule,
    int rotationBaseGames,
    int pointNumber,
  ) {
    final order = rule.service.order;
    final offset = pointNumber <= 1 ? 0 : 1 + ((pointNumber - 2) ~/ 2);
    return order[(rotationBaseGames + offset) % order.length].id;
  }
}

class _SimResult {
  const _SimResult({
    required this.currentGamePoints,
    required this.gamesWonInCurrentSet,
    required this.setsWon,
    required this.completedSets,
    required this.currentSetIndex,
    required this.isTieBreak,
    required this.isMatchTieBreak,
    required this.tieBreakPoints,
    required this.currentServerSlotId,
    required this.matchComplete,
    required this.winner,
    required this.changeEndsDue,
  });

  final Map<String, int> currentGamePoints;
  final Map<String, int> gamesWonInCurrentSet;
  final Map<String, int> setsWon;
  final List<RacketSetResult> completedSets;
  final int currentSetIndex;
  final bool isTieBreak;
  final bool isMatchTieBreak;
  final Map<String, int> tieBreakPoints;
  final String currentServerSlotId;
  final bool matchComplete;
  final String? winner;
  final bool changeEndsDue;
}
