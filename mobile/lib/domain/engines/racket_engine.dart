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
/// ## Doubles service order (ITF Rule 14)
///
/// `RacketMatchRule.service.order` is decided once, at session creation,
/// and never changes — it's segment 0's order (the match's first set) and,
/// for singles, the *only* order the match ever needs (server/receiver
/// simply keep alternating every game, continuously, with no set-boundary
/// reset — see `_gameServerSlot`).
///
/// Doubles is different: Rule 14 lets each side re-pick which of its two
/// players opens its own service *in every set* — and again before a Match
/// Tie-break replacing the deciding set (which side serves first is still
/// mechanically fixed by the match's continuous team-level rotation, never
/// a free choice) — while the rotation cadence within that segment (this
/// side's players alternate every time their side comes up to serve)
/// resets fresh at slot 0 for the segment's own first game. A
/// `SERVICE_ORDER_CONFIGURED` event (`RacketEngineEventType.
/// serviceOrderConfigured`) persists that per-set choice; `replay` resolves
/// every one of them, once, against the final simulated state (see
/// `_configuredOrders`/`_resolveServerSlot`) — never threaded through
/// `_simulate` itself, since which order applies has zero effect on
/// score/set/match progression, only on [RacketMatchState.
/// currentServerSlotId] and [RacketMatchState.needsServiceConfiguration].
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

        case RacketEngineEventType.serviceOrderConfigured:
        // Doesn't affect score simulation at all — handled below, once,
        // against the final `sim` (see `_configuredOrders`). Processing it
        // here would be premature: whether a given event is even valid
        // depends on `sim.segmentStartGames`, which only exists once every
        // surviving point has been simulated.
      }
    }

    final matchComplete = sim.matchComplete || manuallyCompleted;
    var winner = sim.winner;
    if (manuallyCompleted && winner == null) {
      winner = _leaderBySets(rule, sim.setsWon);
    }

    // Doubles service order (CLAUDE.md brief section 3-11): ITF Rule 14
    // lets each side re-pick which of its two players opens its own
    // service in every set (and again before a Match Tie-break replacing
    // the deciding set), while which *side* serves a segment's first game
    // stays the mechanical continuation of the match's continuous
    // team-level rotation — never a free choice. `_configuredOrders`
    // resolves every persisted `SERVICE_ORDER_CONFIGURED` event against
    // that constraint; `_resolveServerSlot` is a no-op override for
    // singles and for the match's first set, which never need
    // reconfiguring.
    final configuredOrders = _configuredOrders(rule, events, sim);
    final currentServerSlotId = _resolveServerSlot(rule, sim, configuredOrders);
    final needsServiceConfiguration =
        !matchComplete &&
        rule.service.order.length == 4 &&
        sim.currentSetIndex >= 1 &&
        !configuredOrders.containsKey(sim.currentSetIndex);
    final pendingServiceConfigurationSideId = needsServiceConfiguration
        ? _expectedStartingSide(
            rule,
            sim.segmentStartGames,
            sim.currentSetIndex,
          )
        : null;

    return RacketMatchState(
      currentGamePoints: sim.currentGamePoints,
      gamesWonInCurrentSet: sim.gamesWonInCurrentSet,
      setsWon: sim.setsWon,
      completedSets: sim.completedSets,
      currentSetIndex: sim.currentSetIndex,
      isTieBreak: sim.isTieBreak,
      isMatchTieBreak: sim.isMatchTieBreak,
      tieBreakPoints: sim.tieBreakPoints,
      currentServerSlotId: currentServerSlotId,
      matchComplete: matchComplete,
      winner: winner,
      appliedEventCount: appliedEventCount,
      changeEndsDue: sim.changeEndsDue,
      needsServiceConfiguration: needsServiceConfiguration,
      pendingServiceConfigurationSideId: pendingServiceConfigurationSideId,
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
    final segmentStartGames = <int, int>{0: 0};

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
          segmentStartGames[setIndex] = totalGamesForRotation;
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
          segmentStartGames[setIndex] = totalGamesForRotation;
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
            rule.service.order,
            tieBreakRotationBase,
            tieBreakPoints[sideA]! + tieBreakPoints[sideB]! + 1,
          )
        : _gameServerSlot(rule.service.order, totalGamesForRotation);

    // ITF Rule 10 (Change of Ends): games are counted *within a set*, reset
    // at each set boundary — never `totalGamesForRotation`'s match-wide
    // total, which would miss the change due after just the first game of
    // a new set when the previous set ended on an odd total (e.g. 6-3: 9
    // games, change due at the end of the set *and again* after the very
    // next set's first game — CLAUDE.md brief section 13/14).
    //
    // `gamesInSet` itself isn't enough: it's already reset to {0, 0} by
    // the moment a set-deciding point finishes processing (needed so
    // `gamesWonInCurrentSet` reads right for the *next* set immediately),
    // so evaluated right at that exact boundary it reads 0 either way —
    // which segment's parity it should reflect depends on whether any
    // game has actually been played in the new segment yet. `effectiveGames`
    // resolves that: mid-segment, it's just `gamesInSet`'s sum; exactly at
    // a fresh boundary (0 games into the new segment, 0 points into
    // whatever game comes next), it falls back to the *just-concluded*
    // segment's own final tally via `segmentStartGames` — the only place
    // that tally still exists once `gamesInSet` has been reset.
    //
    // The tie-break/Match-Tie-break branch mirrors this at its own entry
    // boundary (0 tie-break points played yet: still the just-concluded
    // set's own parity, since Rule 10's "at the end of each set" clause
    // fires regardless of what follows — a new set's game 1 or a
    // tie-break) and switches to the official every-6-points checkpoint
    // the instant a tie-break point is actually played — which then also
    // clears the indicator one point later for free, satisfying CLAUDE.md
    // brief section 17 without an extra guard (unlike the non-tie-break
    // branch, which needs `pointsIntoCurrentGame == 0` explicitly since a
    // game's own points don't reset anything ends-relevant on their own).
    final gamesInSetSum = gamesInSet[sideA]! + gamesInSet[sideB]!;
    final pointsIntoCurrentGame = gamePoints[sideA]! + gamePoints[sideB]!;
    final tieBreakPointsPlayed =
        tieBreakPoints[sideA]! + tieBreakPoints[sideB]!;
    final effectiveGames = gamesInSetSum > 0
        ? gamesInSetSum
        : (setIndex >= 1
              ? segmentStartGames[setIndex]! - segmentStartGames[setIndex - 1]!
              : 0);
    final changeEndsDue = isTieBreak || isMatchTieBreak
        ? (tieBreakPointsPlayed > 0
              ? tieBreakPointsPlayed % 6 == 0
              : effectiveGames.isOdd)
        : pointsIntoCurrentGame == 0 && effectiveGames.isOdd;

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
      totalGamesForRotation: totalGamesForRotation,
      tieBreakRotationBase: tieBreakRotationBase,
      segmentStartGames: segmentStartGames,
    );
  }

  /// ITF Rule 14 (Order of Service): the server rotates by one slot every
  /// completed game (a tie-break counts as exactly one game for this
  /// purpose — see [_tieBreakServerSlot]), continuously — never reset,
  /// whether walking the match-wide [order] (singles, and segment 0 of a
  /// doubles match) or a single reconfigured doubles segment's own local
  /// order (see `_resolveServerSlot`, [gamesCompleted] is then games
  /// completed *within that segment* rather than match-wide).
  static String _gameServerSlot(List<ServiceSlot> order, int gamesCompleted) =>
      order[gamesCompleted % order.length].id;

  /// ITF Rule 14: within a tie-break, the player next in rotation serves
  /// point 1 alone, then service alternates every 2 points thereafter
  /// (points 2-3 the other side, 4-5 back, ...) — never approximated as a
  /// simple per-point alternation (CLAUDE.md brief section 13).
  /// [rotationBaseGames] is the games-completed counter (see
  /// [_gameServerSlot]) frozen at the moment the tie-break started;
  /// [pointNumber] is the 1-based point about to be played.
  static String _tieBreakServerSlot(
    List<ServiceSlot> order,
    int rotationBaseGames,
    int pointNumber,
  ) {
    final offset = pointNumber <= 1 ? 0 : 1 + ((pointNumber - 2) ~/ 2);
    return order[(rotationBaseGames + offset) % order.length].id;
  }

  /// Resolves the server slot that actually applies once doubles
  /// per-segment reconfiguration is taken into account — see the
  /// "Doubles service order" section on [replay]. Singles and segment 0
  /// (a match's first set) always use [sim]'s own [_SimResult.
  /// currentServerSlotId], computed against the match-wide, never-
  /// reconfigured `rule.service.order` exactly as before; only a doubles
  /// segment >= 1 with a validated override in [configuredOrders] changes
  /// anything.
  static String _resolveServerSlot(
    RacketMatchRule rule,
    _SimResult sim,
    Map<int, List<ServiceSlot>> configuredOrders,
  ) {
    if (rule.service.order.length != 4 || sim.currentSetIndex == 0) {
      return sim.currentServerSlotId;
    }
    final order = configuredOrders[sim.currentSetIndex] ?? rule.service.order;
    final segmentStart = sim.segmentStartGames[sim.currentSetIndex] ?? 0;
    if (sim.isTieBreak || sim.isMatchTieBreak) {
      return _tieBreakServerSlot(
        order,
        sim.tieBreakRotationBase - segmentStart,
        sim.tieBreakPoints.values.fold(0, (a, b) => a + b) + 1,
      );
    }
    return _gameServerSlot(order, sim.totalGamesForRotation - segmentStart);
  }

  /// The side that must mechanically serve [segmentIndex]'s first game —
  /// ITF Rule 14's continuous team-level rotation, never a free choice
  /// (CLAUDE.md brief section 9) — or null if that segment hasn't been
  /// reached yet. [rule.service.order] must be a doubles order (4 slots);
  /// singles never calls this (its rotation never needs reconfiguring).
  static String? _expectedStartingSide(
    RacketMatchRule rule,
    Map<int, int> segmentStartGames,
    int segmentIndex,
  ) {
    final segmentStart = segmentStartGames[segmentIndex];
    if (segmentStart == null) return null;
    final initialServingSide = rule.service.order[0].sideId;
    final otherSide = rule.sideIds.firstWhere((s) => s != initialServingSide);
    return segmentStart.isEven ? initialServingSide : otherSide;
  }

  /// Builds the validated segment -> order map from every persisted
  /// `SERVICE_ORDER_CONFIGURED` event — see the "Doubles service order"
  /// section on [replay]. Singles ([rule.service.order] has 2 slots, not
  /// 4) never consults this; the map is simply left empty for it.
  static Map<int, List<ServiceSlot>> _configuredOrders(
    RacketMatchRule rule,
    List<RacketEngineEvent> events,
    _SimResult sim,
  ) {
    final result = <int, List<ServiceSlot>>{};
    if (rule.service.order.length != 4) return result;

    final slotById = {for (final s in rule.service.order) s.id: s};

    for (final event in events) {
      if (event.type != RacketEngineEventType.serviceOrderConfigured) {
        continue;
      }
      final segmentIndex = event.payload['segmentIndex'];
      final rawOrder = event.payload['order'];
      if (segmentIndex is! int || segmentIndex < 1 || rawOrder is! List) {
        continue; // malformed: ignored, never fatal (mirrors POINT_SCORED).
      }
      if (result.containsKey(segmentIndex)) {
        continue; // first valid config for a segment wins — no re-editing.
      }
      final segmentStart = sim.segmentStartGames[segmentIndex];
      if (segmentStart == null) {
        continue; // segment never (yet) reached: stale/premature, ignored.
      }
      if (rawOrder.length != 4 || rawOrder.any((id) => id is! String)) {
        continue;
      }
      final ids = rawOrder.cast<String>();
      if (ids.toSet().length != 4 || !ids.every(slotById.containsKey)) {
        continue; // not a permutation of this match's own 4 known slots.
      }
      final slots = ids.map((id) => slotById[id]!).toList();
      final sides = slots.map((s) => s.sideId).toList();
      // Slots 0/2 must be one side's two players (that side serves this
      // segment's 1st and 3rd game), 1/3 the other's — never a same-side
      // pair sharing both parities, never one side occupying all 4.
      if (sides[0] != sides[2] ||
          sides[1] != sides[3] ||
          sides[0] == sides[1]) {
        continue;
      }
      // The side serving this segment's first game is never the user's
      // choice — it's the mechanical continuation of the continuous
      // team-level rotation (ITF Rule 14), validated here so a malformed
      // or replayed-out-of-order event can never hand service to the
      // wrong side (CLAUDE.md brief section 9).
      final expectedSide = _expectedStartingSide(
        rule,
        sim.segmentStartGames,
        segmentIndex,
      );
      if (sides[0] != expectedSide) continue;

      result[segmentIndex] = slots;
    }
    return result;
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
    required this.totalGamesForRotation,
    required this.tieBreakRotationBase,
    required this.segmentStartGames,
  });

  final Map<String, int> currentGamePoints;
  final Map<String, int> gamesWonInCurrentSet;
  final Map<String, int> setsWon;
  final List<RacketSetResult> completedSets;
  final int currentSetIndex;
  final bool isTieBreak;
  final bool isMatchTieBreak;
  final Map<String, int> tieBreakPoints;

  /// The server slot the *default* (never-reconfigured) rotation would use
  /// — `rule.service.order` walked continuously by [totalGamesForRotation]/
  /// [tieBreakRotationBase], exactly as singles always works and as
  /// segment 0 (the match's first set) always works for doubles too. Only
  /// a doubles segment >= 1 with a valid `SERVICE_ORDER_CONFIGURED` event
  /// ever overrides this — see `RacketEngine._resolveServerSlot`.
  final String currentServerSlotId;
  final bool matchComplete;
  final String? winner;
  final bool changeEndsDue;

  /// Games completed so far in the whole match, continuously across set
  /// boundaries — drives singles/segment-0 rotation ([currentServerSlotId])
  /// and, combined with [segmentStartGames], the *local* (per-segment)
  /// rotation a reconfigured doubles order needs.
  final int totalGamesForRotation;

  /// [totalGamesForRotation] frozen at the moment the current tie-break
  /// (set tie-break or Match Tie-break) began — meaningless unless
  /// [isTieBreak] or [isMatchTieBreak].
  final int tieBreakRotationBase;

  /// [totalGamesForRotation] at the moment each segment (set index, or the
  /// Match Tie-break sharing its deciding set's index) began — only
  /// contains keys for segments actually entered so far (0..
  /// [currentSetIndex]). Segment 0 is always `{0: 0}`. Purely a function of
  /// the surviving point list, never of any `SERVICE_ORDER_CONFIGURED`
  /// event, which is exactly what lets `RacketEngine.replay` validate a
  /// segment's configured order against the mechanically-correct serving
  /// side without a circular dependency (CLAUDE.md brief section 9).
  final Map<int, int> segmentStartGames;
}
