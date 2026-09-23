import '../models/match_clock_kind.dart';
import '../models/match_end_rule.dart';
import '../models/match_rule.dart';
import '../models/overtime_rule.dart';
import '../models/period_rule.dart';
import '../models/score_rule.dart';
import '../models/shot_clock_rule.dart';
import '../models/team_foul_rule.dart';
import '../models/timeout_rule.dart';

/// FIBA's 2026 rules become effective 2026-10-01 — see
/// https://about.fiba.basketball/en/news/fiba-official-basketball-rules-changes-2026-summary-now-available
/// and docs/SPORT_RULES.md. The 2024/2026 editions carry no differences
/// relevant to period/clock/scoring/timeout structure (2026 changes:
/// instant replay, foul reclassification, cosmetic uniform rules) — see
/// [_basketballRuleset]: the two rulesets differ **only** by [MatchRule.
/// rulesetId], never by field values, per the "don't duplicate identical
/// values" rule.
final basketballFiba2026CutoverUtc = DateTime.utc(2026, 10, 1);

/// FIBA Official Basketball Rules, Article 8 (Playing time, tied score,
/// overtime) and Article 16 (Goal value): 4 quarters x 10 minutes, tied at
/// the end of Q4 -> as many 5-minute overtimes as necessary (never a
/// draw), +1/+2/+3. Source: FIBA Official Basketball Rules 2024, verified
/// PDF (see docs/SPORT_RULES.md) — identical structure carried into the
/// 2026 edition.
///
/// Article 29 (shot clock): 24s standard, 14s short reset — PlayTap
/// never infers *why* a reset applies (see `ShotClockEngine`'s doc note),
/// only offers both durations as quick actions.
///
/// Article 18 (timeouts): 2 in the first half (Q1-Q2), 3 in the second
/// half (Q3-Q4, of which at most 2 may be used once Q4's clock is at or
/// below 2:00 — [TimeoutLateGameSubCap]), 1 fresh timeout per overtime
/// period, never carried between halves/overtimes.
///
/// Article 41 (team fouls): bonus/penalty from the 5th team foul in the
/// current bracket; overtime never resets the count, it continues from
/// Q4's tally — see `TeamFoulRule`'s doc note (verified identical to
/// Futsal's accumulated-foul carry-into-extra-time behavior, hence the
/// shared engine).
MatchRule _basketballRuleset(String rulesetId) => MatchRule(
  schemaVersion: 1,
  rulesetId: rulesetId,
  scoreRule: const TeamScoreRule(
    schemaVersion: 1,
    sideIds: ['team_a', 'team_b'],
    allowedIncrements: [1, 2, 3],
  ),
  clock: MatchClockKind.stoppedClock,
  periods: List.generate(4, (i) => PeriodRule(index: i, durationMs: 600000)),
  overtime: const OvertimeRule(durationMs: 300000, maxCount: null), // uncapped.
  matchEnd: const MatchEndRule(drawAllowed: false),
  shotClockRule: const ShotClockRule(
    schemaVersion: 1,
    defaultDurationMs: 24000,
    shortResetDurationMs: 14000,
  ),
  timeoutRule: const TimeoutRule(
    schemaVersion: 1,
    regulationGroups: [
      TimeoutQuotaGroup(periodIndices: [0, 1], quota: 2),
      TimeoutQuotaGroup(periodIndices: [2, 3], quota: 3),
    ],
    quotaPerOvertimePeriod: 1,
    lateGameSubCap: TimeoutLateGameSubCap(
      periodIndex: 3,
      remainingMsThreshold: 120000, // last 2 minutes of Q4.
      maxUsableWithinWindow: 2,
    ),
  ),
  teamFoulRule: const TeamFoulRule(schemaVersion: 1, bonusThreshold: 5),
);

MatchRule basketballFiba2024() => _basketballRuleset('basketball.fiba.2024');

MatchRule basketballFiba2026() => _basketballRuleset('basketball.fiba.2026');

/// Picks the ruleset a **new** session should use right now — never
/// re-consulted for an existing session (its fully-resolved `MatchRule` is
/// persisted whole into `SESSION_STARTED`, so a session started before the
/// cutover keeps FIBA 2024 forever — see docs/DATA_MODEL.md).
MatchRule resolveDefaultBasketballRuleset(DateTime now) =>
    now.toUtc().isBefore(basketballFiba2026CutoverUtc)
    ? basketballFiba2024()
    : basketballFiba2026();
