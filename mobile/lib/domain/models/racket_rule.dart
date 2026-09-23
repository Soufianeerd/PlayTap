/// Racket Core — engine-facing configuration for hierarchical
/// point→game→set→match sports (Tennis now; Padel/Table Tennis/Badminton
/// later — see `playtap-sports-rules`). Point/label formatting concerns
/// live in `RacketEngine`; this file is pure configuration.
///
/// ## Why a composed concrete class, not a sealed `ScoreRule` mode
///
/// Tennis's scoring is hierarchical (point → game → set → match), unlike
/// every existing `ScoreRule` (a flat per-event counter). Forcing it into
/// `SEQUENTIAL_SCORE`/`SETS`/`BEST_OF`/`WIN_BY` as independent `ScoreRule`
/// facets (the shape the original Phase 0 audit proposed — see
/// docs/ROADMAP.md) would mean `ScoreEngine.replay` — a flat `Map<String,
/// int>` reducer — somehow also tracking games/sets/tie-breaks/service,
/// which it fundamentally cannot express without becoming a second engine
/// wearing `ScoreRule`'s clothes. Instead, Racket Core mirrors the
/// `MatchRule` precedent (`domain/models/match_rule.dart`): **one concrete
/// class**, not a sealed hierarchy, because the state machine (advance
/// through points → games → sets, decide tie-breaks, rotate service) is
/// identical for every racket sport this architecture targets — only the
/// numbers/booleans/sub-rule choices differ (a `TargetScoreRule`-flavored
/// racket sport like table tennis would still reuse the same `SetRule`/
/// `MatchFormatRule`/`ServiceRule` shapes, just with a different
/// point-scoring facet — not built in this phase, see CLAUDE.md scope
/// note). This is a brand-new, sport-agnostic **Racket Engine**, parallel
/// to `ScoreEngine`/`MatchEngine`, not a `ScoreRule` subtype — see
/// `RacketEngine` and docs/DATA_MODEL.md.
class RacketMatchRule {
  const RacketMatchRule({
    required this.schemaVersion,
    required this.rulesetId,
    required this.sideIds,
    required this.gameScoring,
    required this.setRule,
    required this.matchFormat,
    required this.service,
  });

  final int schemaVersion;

  /// Opaque, persisted identifier of the exact ruleset this match was
  /// created under (e.g. `tennis.itf.2026`) — data for display/versioning
  /// only, never switched on by the engine. See docs/SPORT_RULES.md for
  /// the source citation and `domain/rulesets/tennis_rulesets.dart` for how
  /// one is chosen at session-creation time. A future `tennis.itf.2027`
  /// must never change how an already-started session replays (see
  /// [RacketMatchRule] persisted whole into `SESSION_STARTED`).
  final String rulesetId;

  /// Always exactly 2 scoring sides (`side_a`/`side_b`) regardless of
  /// singles/doubles — see `playtap-sports-rules`: "joueurs != sides de
  /// scoring". Doubles rosters live on `ScoringSide.players`; individual
  /// server identity lives on [service].
  final List<String> sideIds;

  final GameScoringRule gameScoring;

  /// The `SetRule` every set uses, including the deciding set unless
  /// [MatchFormatRule.decidingSetFormat] overrides it with
  /// [MatchTieBreakDecidingSet] — see `MatchFormatRule`.
  final SetRule setRule;

  final MatchFormatRule matchFormat;

  final ServiceRule service;

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'rulesetId': rulesetId,
    'sides': sideIds,
    'gameScoring': gameScoring.toJson(),
    'setRule': setRule.toJson(),
    'matchFormat': matchFormat.toJson(),
    'service': service.toJson(),
  };

  factory RacketMatchRule.fromJson(Map<String, dynamic> json) =>
      RacketMatchRule(
        schemaVersion: json['schemaVersion'] as int,
        rulesetId: json['rulesetId'] as String,
        sideIds: (json['sides'] as List).cast<String>(),
        gameScoring: GameScoringRule.fromJson(
          (json['gameScoring'] as Map).cast<String, dynamic>(),
        ),
        setRule: SetRule.fromJson(
          (json['setRule'] as Map).cast<String, dynamic>(),
        ),
        matchFormat: MatchFormatRule.fromJson(
          (json['matchFormat'] as Map).cast<String, dynamic>(),
        ),
        service: ServiceRule.fromJson(
          (json['service'] as Map).cast<String, dynamic>(),
        ),
      );
}

/// How a standard game resolves at 40-40 — ITF *Rules of Tennis*, Rule 5
/// (Score in a Game) and its official "No-Ad"/"Deciding point" alternative
/// method — see docs/SPORT_RULES.md.
enum AdvantageMode {
  /// Deuce → advantage → game: the standard method. A side must win by a
  /// 2-point margin from 40-40 onward, however long that takes.
  advantage,

  /// No-Ad: at 40-40 ("deciding point"), the next point wins the game
  /// outright — no advantage state ever occurs.
  noAd;

  String toJson() => switch (this) {
    AdvantageMode.advantage => 'ADVANTAGE',
    AdvantageMode.noAd => 'NO_AD',
  };

  static AdvantageMode fromJson(String value) => switch (value) {
    'ADVANTAGE' => AdvantageMode.advantage,
    'NO_AD' => AdvantageMode.noAd,
    _ => throw ArgumentError.value(value, 'value', 'Unknown AdvantageMode'),
  };
}

/// How a single game is scored — see [AdvantageMode]. `RacketEngine` stores
/// raw per-side point counters, never `"15"/"30"/"40"` strings, as the
/// source of truth; this only decides the win condition (see
/// `RacketEngine._simulate`'s margin-needed formula) — display labels are
/// derived separately (`RacketLabels.pointLabel`), never persisted (see
/// CLAUDE.md brief section 4: "Ne jamais stocker uniquement les labels").
class GameScoringRule {
  const GameScoringRule({
    required this.schemaVersion,
    required this.advantageMode,
  });

  final int schemaVersion;
  final AdvantageMode advantageMode;

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'advantageMode': advantageMode.toJson(),
  };

  factory GameScoringRule.fromJson(Map<String, dynamic> json) =>
      GameScoringRule(
        schemaVersion: json['schemaVersion'] as int,
        advantageMode: AdvantageMode.fromJson(json['advantageMode'] as String),
      );
}

/// A tie-break's win condition — shared shape for both a set tie-break
/// (target 7) and a Match Tie-Break (target 10, see
/// [MatchTieBreakDecidingSet]) — ITF Rules of Tennis, Rule 5 (Tie-break
/// game) and Appendix (Match Tie-break). No artificial cap: a tie-break
/// keeps going past its target until [winBy] is satisfied (14-12, ...).
class TieBreakRule {
  const TieBreakRule({
    required this.schemaVersion,
    required this.target,
    this.winBy = 2,
  });

  final int schemaVersion;
  final int target;
  final int winBy;

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'target': target,
    'winBy': winBy,
  };

  factory TieBreakRule.fromJson(Map<String, dynamic> json) => TieBreakRule(
    schemaVersion: json['schemaVersion'] as int,
    target: json['target'] as int,
    winBy: json['winBy'] as int? ?? 2,
  );
}

/// How one set is won — ITF Rules of Tennis, Rule 5 (Score in a Set).
/// Reused for every set in the match unless [MatchFormatRule.
/// decidingSetFormat] overrides the deciding set with
/// [MatchTieBreakDecidingSet] (which bypasses `SetRule` entirely for that
/// one "set" — see `RacketEngine`).
class SetRule {
  const SetRule({
    required this.schemaVersion,
    required this.gamesToWin,
    this.tieBreak,
  });

  final int schemaVersion;

  /// 6 for a standard tennis set — the *floor*, not a cap: with
  /// [tieBreak] null (advantage set), a side must still win by 2 games
  /// however long that takes (e.g. 9-7).
  final int gamesToWin;

  /// Present = a tie-break is played once both sides reach [gamesToWin]
  /// (standard 6-6 → 7-point tie-break). Null = advantage set — no
  /// tie-break ever, play continues past [gamesToWin] until either side
  /// leads by 2 games.
  final TieBreakRule? tieBreak;

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'gamesToWin': gamesToWin,
    if (tieBreak != null) 'tieBreak': tieBreak!.toJson(),
  };

  factory SetRule.fromJson(Map<String, dynamic> json) => SetRule(
    schemaVersion: json['schemaVersion'] as int,
    gamesToWin: json['gamesToWin'] as int,
    tieBreak: json['tieBreak'] != null
        ? TieBreakRule.fromJson(
            (json['tieBreak'] as Map).cast<String, dynamic>(),
          )
        : null,
  );
}

/// What the deciding set (the last set that can be reached, e.g. set 3 of
/// a Best of 3) is played as — sealed so `RacketEngine` can exhaustively
/// switch. [RegularDecidingSet] plays it exactly like every other set
/// (through [RacketMatchRule.setRule]); [MatchTieBreakDecidingSet]
/// replaces the entire deciding set with a single Match Tie-Break (target
/// 10) — a common alternative format, see docs/SPORT_RULES.md. An
/// "advantage set" deciding set (no tie-break, ever) is expressed as
/// [RegularDecidingSet] combined with [RacketMatchRule.setRule].tieBreak
/// == null, not a third variant here — see the composition note on
/// [SetRule].
sealed class DecidingSetFormat {
  const DecidingSetFormat();

  Map<String, dynamic> toJson();

  factory DecidingSetFormat.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    return switch (type) {
      'REGULAR' => const RegularDecidingSet(),
      'MATCH_TIE_BREAK' => MatchTieBreakDecidingSet.fromJson(json),
      _ => throw ArgumentError.value(type, 'type', 'Unknown DecidingSetFormat'),
    };
  }
}

class RegularDecidingSet extends DecidingSetFormat {
  const RegularDecidingSet();

  @override
  Map<String, dynamic> toJson() => {'type': 'REGULAR'};
}

class MatchTieBreakDecidingSet extends DecidingSetFormat {
  const MatchTieBreakDecidingSet({required this.matchTieBreak});

  /// Target 10, win by 2 — ITF Match Tie-break. A distinct [TieBreakRule]
  /// instance from any regular set's tie-break (never conflated — see
  /// `RacketMatchState.isMatchTieBreak` vs `isSetTieBreak`).
  final TieBreakRule matchTieBreak;

  @override
  Map<String, dynamic> toJson() => {
    'type': 'MATCH_TIE_BREAK',
    'matchTieBreak': matchTieBreak.toJson(),
  };

  factory MatchTieBreakDecidingSet.fromJson(Map<String, dynamic> json) =>
      MatchTieBreakDecidingSet(
        matchTieBreak: TieBreakRule.fromJson(
          (json['matchTieBreak'] as Map).cast<String, dynamic>(),
        ),
      );
}

/// Best-of / sets-to-win abstraction — ITF Rules of Tennis, Rule 5 (Score
/// in a Match). [setsToWin] is the number of sets that decides the match
/// (2 for Best of 3, 3 for Best of 5) — the engine never assumes "2 sets
/// always wins" (see CLAUDE.md brief section 9).
class MatchFormatRule {
  const MatchFormatRule({
    required this.schemaVersion,
    required this.setsToWin,
    required this.decidingSetFormat,
  });

  final int schemaVersion;
  final int setsToWin;
  final DecidingSetFormat decidingSetFormat;

  /// Zero-based index of the deciding set — the last set index a match
  /// under this format can ever reach (e.g. Best of 3: index 2).
  int get decidingSetIndex => (2 * setsToWin) - 2;

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'setsToWin': setsToWin,
    'decidingSetFormat': decidingSetFormat.toJson(),
  };

  factory MatchFormatRule.fromJson(Map<String, dynamic> json) =>
      MatchFormatRule(
        schemaVersion: json['schemaVersion'] as int,
        setsToWin: json['setsToWin'] as int,
        decidingSetFormat: DecidingSetFormat.fromJson(
          (json['decidingSetFormat'] as Map).cast<String, dynamic>(),
        ),
      );
}

/// One server "slot" in the persisted service order — see `ServiceRule`.
/// [id] is an opaque, stable identifier for this slot (never a display
/// name); the UI resolves a display name via [sideId] + [playerIndex] into
/// `ScoringSide.players`.
class ServiceSlot {
  const ServiceSlot({required this.id, required this.sideId, this.playerIndex});

  final String id;
  final String sideId;

  /// Index into that side's `ScoringSide.players` — null for singles,
  /// where the side itself has no separate roster and its `name` already
  /// is the player's name.
  final int? playerIndex;

  Map<String, dynamic> toJson() => {
    'id': id,
    'sideId': sideId,
    if (playerIndex != null) 'playerIndex': playerIndex,
  };

  factory ServiceSlot.fromJson(Map<String, dynamic> json) => ServiceSlot(
    id: json['id'] as String,
    sideId: json['sideId'] as String,
    playerIndex: json['playerIndex'] as int?,
  );
}

/// Persisted service rotation order — ITF Rules of Tennis, Rule 15
/// (Order of Service) and Rule 16 (Order of Receiving in Doubles).
/// [order] has 2 entries for singles (the two sides alternate every game)
/// or 4 for doubles (rotates through all four players — the pair's chosen
/// serving order for the match, fixed once chosen, see
/// `RacketEngine.serverSlotForRotation`). Decided once at session creation
/// and persisted whole — never recomputed from "who served last" at
/// display time (see [RacketMatchRule.rulesetId]'s persistence note).
class ServiceRule {
  const ServiceRule({required this.schemaVersion, required this.order});

  final int schemaVersion;
  final List<ServiceSlot> order;

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'order': order.map((s) => s.toJson()).toList(),
  };

  factory ServiceRule.fromJson(Map<String, dynamic> json) => ServiceRule(
    schemaVersion: json['schemaVersion'] as int,
    order: (json['order'] as List)
        .cast<Map<String, dynamic>>()
        .map(ServiceSlot.fromJson)
        .toList(),
  );
}
