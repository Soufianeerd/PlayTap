import 'team_match_format.dart';
import '../models/match_clock_kind.dart';
import '../models/match_end_rule.dart';
import '../models/match_rule.dart';
import '../models/overtime_rule.dart';
import '../models/period_rule.dart';
import '../models/score_rule.dart';
import '../models/shootout_rule.dart';

/// FIFA Futsal Laws of the Game — latest edition **verified** at the time
/// this was written is 2025-26 (effective 2025-07-01). A newer 2026-27
/// futsal-specific edition could not be confirmed to exist or not exist —
/// re-check FIFA's official digital hub before treating this as final; see
/// docs/SPORT_RULES.md for the full citation and this caveat. Law 7: 2x20
/// min halves, stopped clock. Extra time/shootout format, like football,
/// is a competition rule — only present for [TeamMatchFormat.knockout].
/// Timeouts (1/team/period) and accumulated fouls (from the 6th/period)
/// are real FIFA rules this app does not yet enforce — see the v1 scope
/// note in docs/SPORT_RULES.md.
MatchRule resolveDefaultFutsalRuleset(DateTime now, TeamMatchFormat format) {
  final knockout = format == TeamMatchFormat.knockout;
  return MatchRule(
    schemaVersion: 1,
    rulesetId: 'futsal.fifa.2025_26',
    scoreRule: const TeamScoreRule(
      schemaVersion: 1,
      sideIds: ['team_a', 'team_b'],
      allowedIncrements: [1],
    ),
    clock: MatchClockKind.stoppedClock,
    periods: List.generate(2, (i) => PeriodRule(index: i, durationMs: 1200000)),
    overtime: knockout
        ? const OvertimeRule(durationMs: 300000, maxCount: 2)
        : null,
    shootout: knockout
        ? const ShootoutRule(kicksPerRound: 5, suddenDeath: true)
        : null,
    matchEnd: MatchEndRule(drawAllowed: !knockout),
  );
}
