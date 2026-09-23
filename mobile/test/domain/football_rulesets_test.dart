import 'package:flutter_test/flutter_test.dart';
import 'package:playtap/domain/models/match_clock_kind.dart';
import 'package:playtap/domain/rulesets/football_rulesets.dart';
import 'package:playtap/domain/rulesets/team_match_format.dart';

void main() {
  group('Football rulesets', () {
    test('league: 2x45, running clock, no overtime/shootout, draw allowed', () {
      final rule = resolveDefaultFootballRuleset(
        DateTime.utc(2026, 9, 23),
        TeamMatchFormat.league,
      );
      expect(rule.rulesetId, 'football.ifab.2026_27');
      expect(rule.periods.length, 2);
      expect(rule.periods.every((p) => p.durationMs == 2700000), isTrue);
      expect(rule.clock, MatchClockKind.runningClock);
      expect(rule.overtime, isNull);
      expect(rule.shootout, isNull);
      expect(rule.matchEnd.drawAllowed, isTrue);
      expect(rule.scoreRule.allowedIncrements, [1]);
    });

    test(
      'knockout: extra time (2x15, fixed-length block) + shootout, no draw',
      () {
        final rule = resolveDefaultFootballRuleset(
          DateTime.utc(2026, 9, 23),
          TeamMatchFormat.knockout,
        );
        expect(rule.overtime?.durationMs, 900000);
        expect(rule.overtime?.maxCount, 2); // fixed-length block, not uncapped.
        expect(rule.shootout?.kicksPerRound, 5);
        expect(rule.shootout?.suddenDeath, isTrue);
        expect(rule.matchEnd.drawAllowed, isFalse);
      },
    );

    test(
      'TeamMatchFormat.fromPersisted reconstructs the format from the persisted rule',
      () {
        final league = resolveDefaultFootballRuleset(
          DateTime.utc(2026, 9, 23),
          TeamMatchFormat.league,
        );
        final knockout = resolveDefaultFootballRuleset(
          DateTime.utc(2026, 9, 23),
          TeamMatchFormat.knockout,
        );
        expect(TeamMatchFormat.fromPersisted(league), TeamMatchFormat.league);
        expect(
          TeamMatchFormat.fromPersisted(knockout),
          TeamMatchFormat.knockout,
        );
      },
    );
  });
}
