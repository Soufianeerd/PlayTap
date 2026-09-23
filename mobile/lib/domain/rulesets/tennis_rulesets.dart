import '../models/racket_rule.dart';

/// ITF *Rules of Tennis 2026* — official source:
/// https://www.itftennis.com/en/about-us/governance/rules-and-regulations/
/// (see docs/SPORT_RULES.md for the full citation per rule). No 2027
/// edition exists yet, so unlike Basketball's FIBA 2024/2026 cutover
/// (`basketball_rulesets.dart`) there is only one persisted ruleset id for
/// now — `rulesetId` still exists precisely so a future `tennis.itf.2027`
/// can be added the same additive way, without ever changing how an
/// already-started session replays (see [RacketMatchRule.rulesetId]).
///
/// - Rule 4 (Score in a Game): standard 0/15/30/40, deuce/advantage, or the
///   official No-Ad ("deciding point") alternative — [AdvantageMode].
/// - Rule 5 (Score in a Set): first to 6 games, win by 2; a tie-break at
///   6-6 is the standard method (the alternative "advantage set", with no
///   tie-break ever, is expressible via `SetRule.tieBreak == null` but not
///   offered by the V1 config screen — CLAUDE.md brief section 6).
/// - Tie-break game: first to 7 points, win by 2 — [tennisSetTieBreak].
/// - Match Tie-break (an alternative deciding-set format some competitions
///   use in place of a full deciding set): first to 10 points, win by 2 —
///   [tennisMatchTieBreak].
/// - Rule 5 (Score in a Match): Best of 3 sets (first to 2) is the only
///   format the V1 config screen offers (CLAUDE.md brief section 9); the
///   engine itself never assumes 2 — see `MatchFormatRule.setsToWin`.
const tennisSetTieBreak = TieBreakRule(schemaVersion: 1, target: 7, winBy: 2);

const tennisMatchTieBreak = TieBreakRule(
  schemaVersion: 1,
  target: 10,
  winBy: 2,
);

/// Builds the full [RacketMatchRule] for a new Tennis session under the
/// `tennis.itf.2026` ruleset, given the choices made on the config screen
/// (advantage/No-Ad, deciding-set format, and the resolved [service]
/// order) — mirrors `basketball_rulesets.dart`'s shape. The structural
/// constants (games-to-win 6, set tie-break 7, Match Tie-break 10) are
/// never configurable: they're the rule, not a preference.
RacketMatchRule tennisItf2026Ruleset({
  required AdvantageMode advantageMode,
  required DecidingSetFormat decidingSetFormat,
  required ServiceRule service,
}) => RacketMatchRule(
  schemaVersion: 1,
  rulesetId: 'tennis.itf.2026',
  sideIds: const ['side_a', 'side_b'],
  gameScoring: GameScoringRule(schemaVersion: 1, advantageMode: advantageMode),
  setRule: const SetRule(
    schemaVersion: 1,
    gamesToWin: 6,
    tieBreak: tennisSetTieBreak,
  ),
  matchFormat: MatchFormatRule(
    schemaVersion: 1,
    setsToWin: 2,
    decidingSetFormat: decidingSetFormat,
  ),
  service: service,
);
