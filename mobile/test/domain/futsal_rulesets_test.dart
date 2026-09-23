import 'package:flutter_test/flutter_test.dart';
import 'package:playtap/domain/models/match_clock_kind.dart';
import 'package:playtap/domain/rulesets/futsal_rulesets.dart';
import 'package:playtap/domain/rulesets/team_match_format.dart';

void main() {
  group('Futsal rulesets', () {
    test('league: 2x20, stopped clock, no overtime/shootout, draw allowed', () {
      final rule = resolveDefaultFutsalRuleset(
        DateTime.utc(2026, 9, 23),
        TeamMatchFormat.league,
      );
      expect(rule.rulesetId, 'futsal.fifa.2025_26');
      expect(rule.periods.length, 2);
      expect(rule.periods.every((p) => p.durationMs == 1200000), isTrue);
      expect(rule.clock, MatchClockKind.stoppedClock);
      expect(rule.overtime, isNull);
      expect(rule.shootout, isNull);
      expect(rule.matchEnd.drawAllowed, isTrue);
      expect(rule.scoreRule.allowedIncrements, [1]);
    });

    test(
      'knockout: extra time + shootout, no draw — same shootout shape as football',
      () {
        final rule = resolveDefaultFutsalRuleset(
          DateTime.utc(2026, 9, 23),
          TeamMatchFormat.knockout,
        );
        expect(rule.overtime?.maxCount, 2);
        expect(rule.shootout?.kicksPerRound, 5);
        expect(rule.shootout?.suddenDeath, isTrue);
        expect(rule.matchEnd.drawAllowed, isFalse);
      },
    );
  });
}
