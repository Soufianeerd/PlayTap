import 'team_match_format.dart';
import '../models/match_clock_kind.dart';
import '../models/match_end_rule.dart';
import '../models/match_rule.dart';
import '../models/overtime_rule.dart';
import '../models/period_rule.dart';
import '../models/score_rule.dart';
import '../models/shootout_rule.dart';

/// IFAB Laws of the Game 2026/27, in force since 2026-07-01 — see
/// docs/SPORT_RULES.md. Law 7: 2x45 min halves, running clock; added time
/// is referee discretion (never auto-computed — see
/// `features/score_team_match/`'s "announce added time" action, never a
/// fixed "+X min" the app invents on its own). Extra time (commonly 2x15)
/// and the penalty-shootout resolution path are competition rules, not
/// mandated for every match, so they're only present for
/// [TeamMatchFormat.knockout].
MatchRule resolveDefaultFootballRuleset(DateTime now, TeamMatchFormat format) {
  final knockout = format == TeamMatchFormat.knockout;
  return MatchRule(
    schemaVersion: 1,
    rulesetId: 'football.ifab.2026_27',
    scoreRule: const TeamScoreRule(
      schemaVersion: 1,
      sideIds: ['team_a', 'team_b'],
      allowedIncrements: [1],
    ),
    clock: MatchClockKind.runningClock,
    periods: List.generate(2, (i) => PeriodRule(index: i, durationMs: 2700000)),
    // Fixed-length block: both 15-minute periods are always played out in
    // full, regardless of score partway through — see the dual semantics
    // documented on `OvertimeRule.maxCount`.
    overtime: knockout
        ? const OvertimeRule(durationMs: 900000, maxCount: 2)
        : null,
    shootout: knockout
        ? const ShootoutRule(kicksPerRound: 5, suddenDeath: true)
        : null,
    matchEnd: MatchEndRule(drawAllowed: !knockout),
  );
}
