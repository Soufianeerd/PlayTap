import '../models/match_clock_kind.dart';
import '../models/match_end_rule.dart';
import '../models/match_rule.dart';
import '../models/overtime_rule.dart';
import '../models/period_rule.dart';
import '../models/score_rule.dart';

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
