import 'package:flutter_test/flutter_test.dart';
import 'package:playtap/domain/models/match_clock_kind.dart';
import 'package:playtap/domain/rulesets/basketball_rulesets.dart';

void main() {
  group('Basketball rulesets', () {
    test('2024 and 2026 rulesets differ only by rulesetId', () {
      final r2024 = basketballFiba2024();
      final r2026 = basketballFiba2026();
      expect(r2024.rulesetId, 'basketball.fiba.2024');
      expect(r2026.rulesetId, 'basketball.fiba.2026');
      expect(
        r2024.toJson()..remove('rulesetId'),
        r2026.toJson()..remove('rulesetId'),
      );
    });

    test('4 quarters of 10 minutes, uncapped overtime, no draw, +1/+2/+3', () {
      final rule = basketballFiba2024();
      expect(rule.periods.length, 4);
      expect(rule.periods.every((p) => p.durationMs == 600000), isTrue);
      expect(rule.overtime?.durationMs, 300000);
      expect(rule.overtime?.maxCount, isNull);
      expect(rule.matchEnd.drawAllowed, isFalse);
      expect(rule.clock, MatchClockKind.stoppedClock);
      expect(rule.scoreRule.allowedIncrements, [1, 2, 3]);
      expect(rule.shootout, isNull);
    });

    test('shot clock: 24s standard, 14s short reset', () {
      final rule = basketballFiba2024();
      expect(rule.shotClockRule?.defaultDurationMs, 24000);
      expect(rule.shotClockRule?.shortResetDurationMs, 14000);
    });

    test(
      'timeouts: 2 in H1, 3 in H2 with a late-game sub-cap, 1 per overtime',
      () {
        final rule = basketballFiba2024();
        final groups = rule.timeoutRule!.regulationGroups;
        expect(groups[0].periodIndices, [0, 1]);
        expect(groups[0].quota, 2);
        expect(groups[1].periodIndices, [2, 3]);
        expect(groups[1].quota, 3);
        expect(rule.timeoutRule?.quotaPerOvertimePeriod, 1);
        expect(rule.timeoutRule?.lateGameSubCap?.periodIndex, 3);
        expect(rule.timeoutRule?.lateGameSubCap?.remainingMsThreshold, 120000);
        expect(rule.timeoutRule?.lateGameSubCap?.maxUsableWithinWindow, 2);
      },
    );

    test('team fouls: bonus from the 5th foul', () {
      final rule = basketballFiba2024();
      expect(rule.teamFoulRule?.bonusThreshold, 5);
    });

    test('resolves to FIBA 2024 strictly before the cutover', () {
      final rule = resolveDefaultBasketballRuleset(
        DateTime.utc(2026, 9, 30, 23, 59, 59),
      );
      expect(rule.rulesetId, 'basketball.fiba.2024');
    });

    test('resolves to FIBA 2026 exactly at and after the cutover', () {
      final atCutover = resolveDefaultBasketballRuleset(
        basketballFiba2026CutoverUtc,
      );
      expect(atCutover.rulesetId, 'basketball.fiba.2026');
      final afterCutover = resolveDefaultBasketballRuleset(
        DateTime.utc(2026, 10, 1, 0, 0, 1),
      );
      expect(afterCutover.rulesetId, 'basketball.fiba.2026');
    });

    test('a session created before the cutover keeps FIBA 2024 forever — the '
        'resolved MatchRule is a value, not re-evaluated later', () {
      final resolvedBefore = resolveDefaultBasketballRuleset(
        DateTime.utc(2026, 9, 1),
      );
      // Simulates persisting `resolvedBefore` at SESSION_STARTED time, then
      // asking "what would the app default to today" long after the
      // cutover — the persisted value must never be swapped for the new
      // default.
      final appDefaultLater = resolveDefaultBasketballRuleset(
        DateTime.utc(2027, 1, 1),
      );
      expect(resolvedBefore.rulesetId, 'basketball.fiba.2024');
      expect(appDefaultLater.rulesetId, 'basketball.fiba.2026');
      expect(resolvedBefore.rulesetId, isNot(appDefaultLater.rulesetId));
    });
  });
}
