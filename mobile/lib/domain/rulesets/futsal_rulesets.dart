import 'team_match_format.dart';
import '../models/match_clock_kind.dart';
import '../models/match_end_rule.dart';
import '../models/match_rule.dart';
import '../models/overtime_rule.dart';
import '../models/period_rule.dart';
import '../models/score_rule.dart';
import '../models/shootout_rule.dart';
import '../models/team_foul_rule.dart';
import '../models/timeout_rule.dart';

/// FIFA Futsal Laws of the Game — **re-verified** 2026-09-23 directly
/// against FIFA's official digital hub (every futsal edition listed there
/// from 2020/21 through 2025-26, with no 2026-27 entry): **2025-26
/// (effective 2025-07-01) is confirmed as the current edition**, not a
/// guess — see docs/SPORT_RULES.md for the full citation. Law 7: 2x20 min
/// halves, stopped clock. Extra time/shootout format, like football, is a
/// competition rule — only present for [TeamMatchFormat.knockout].
///
/// Timeouts: 1 per team per period (each period its own quota, never
/// carried to the other), none in extra time.
///
/// Accumulated fouls (DFKSAF, Law 12/13): from the 6th team foul in the
/// current bracket — same [TeamFoulRule] abstraction Basketball's bonus
/// uses, same reset rule (fresh at the 2nd period, carries unchanged into
/// extra time — see `TeamFoulRule`'s doc note, verified identical for
/// both sports). PlayTap does not distinguish direct-free-kick fouls from
/// penalty-kick fouls (a 2025-26 rule nuance that excludes the latter from
/// the official tally) — the scorer taps "add team foul" for whatever
/// they judge countable, never auto-detected (see docs/SPORT_RULES.md).
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
    timeoutRule: const TimeoutRule(
      schemaVersion: 1,
      regulationGroups: [
        TimeoutQuotaGroup(periodIndices: [0], quota: 1),
        TimeoutQuotaGroup(periodIndices: [1], quota: 1),
      ],
      quotaPerOvertimePeriod: 0, // none in extra time.
    ),
    teamFoulRule: const TeamFoulRule(schemaVersion: 1, bonusThreshold: 6),
  );
}
