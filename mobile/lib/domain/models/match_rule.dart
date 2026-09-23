import 'match_clock_kind.dart';
import 'match_end_rule.dart';
import 'overtime_rule.dart';
import 'period_rule.dart';
import 'score_rule.dart';
import 'shootout_rule.dart';

/// Engine-facing match configuration for period/clock/overtime/shootout
/// sports (Basketball, Football, Futsal) — see `playtap-score-engine`,
/// `MatchEngine`, and docs/DATA_MODEL.md.
///
/// Deliberately **one concrete class**, not a sealed hierarchy like
/// [ScoreRule]: `ScoreRule` is sealed because the replay *algorithm*
/// differs per mode ([FreeScoreRule] vs [TargetScoreRule] vs
/// [TeamScoreRule]); here the state machine — advance through periods, run
/// a clock, decide overtime/shootout/draw — is identical for every sport
/// this phase covers. Only the numbers and booleans differ. A sealed
/// per-sport hierarchy would invite exactly the `if (sport == ...)`
/// branching the generic-architecture rule forbids the first time a case
/// needed special-casing in `MatchEngine.replay`. Sport differences live
/// entirely in this object's field values, resolved once at session
/// creation by a ruleset resolver (see `domain/rulesets/`) and persisted
/// whole into `SESSION_STARTED.payload['matchRule']` — never recomputed
/// from "what does the app currently default to," so an old session never
/// changes rules under a new PlayTap version (see [rulesetId]).
class MatchRule {
  const MatchRule({
    required this.schemaVersion,
    required this.rulesetId,
    required this.scoreRule,
    required this.clock,
    required this.periods,
    required this.matchEnd,
    this.overtime,
    this.shootout,
  });

  final int schemaVersion;

  /// Opaque, persisted identifier of the exact ruleset this match was
  /// created under (e.g. `basketball.fiba.2024`, `football.ifab.2026_27`,
  /// `futsal.fifa.2025_26`) — data for display/versioning only, never
  /// switched on by the engine. See `docs/SPORT_RULES.md` for the source
  /// citation behind each id and `domain/rulesets/` for how one is chosen
  /// at session-creation time.
  final String rulesetId;

  /// The existing generic TEAM_SCORE rule (`{1,2,3}` for Basketball,
  /// `{1}` for Football/Futsal), always with `target: null` — these
  /// sports never auto-complete on a score number, only via period/
  /// overtime/shootout resolution (see `MatchEngine.decideNextPhase`).
  final TeamScoreRule scoreRule;

  final MatchClockKind clock;

  /// Regulation periods only (quarters or halves) — overtime periods are
  /// generated on demand from [overtime], not listed here.
  final List<PeriodRule> periods;

  /// Null = this sport never plays overtime (e.g. a league match that
  /// allows a draw with no shootout either).
  final OvertimeRule? overtime;

  /// Null = this sport never resolves a tie via penalties.
  final ShootoutRule? shootout;

  final MatchEndRule matchEnd;

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'rulesetId': rulesetId,
    'scoreRule': scoreRule.toJson(),
    'clock': clock.toJson(),
    'periods': periods.map((p) => p.toJson()).toList(),
    'matchEnd': matchEnd.toJson(),
    if (overtime != null) 'overtime': overtime!.toJson(),
    if (shootout != null) 'shootout': shootout!.toJson(),
  };

  factory MatchRule.fromJson(Map<String, dynamic> json) => MatchRule(
    schemaVersion: json['schemaVersion'] as int,
    rulesetId: json['rulesetId'] as String,
    scoreRule:
        ScoreRule.fromJson((json['scoreRule'] as Map).cast<String, dynamic>())
            as TeamScoreRule,
    clock: MatchClockKind.fromJson(json['clock'] as String),
    periods: (json['periods'] as List)
        .cast<Map<String, dynamic>>()
        .map(PeriodRule.fromJson)
        .toList(),
    matchEnd: MatchEndRule.fromJson(
      (json['matchEnd'] as Map).cast<String, dynamic>(),
    ),
    overtime: json['overtime'] != null
        ? OvertimeRule.fromJson(
            (json['overtime'] as Map).cast<String, dynamic>(),
          )
        : null,
    shootout: json['shootout'] != null
        ? ShootoutRule.fromJson(
            (json['shootout'] as Map).cast<String, dynamic>(),
          )
        : null,
  );
}
