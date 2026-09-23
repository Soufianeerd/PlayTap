import 'package:flutter_test/flutter_test.dart';
import 'package:playtap/domain/models/racket_rule.dart';
import 'package:playtap/domain/rulesets/tennis_rulesets.dart';

void main() {
  group('Tennis rulesets', () {
    const service = ServiceRule(
      schemaVersion: 1,
      order: [
        ServiceSlot(id: 'side_a', sideId: 'side_a'),
        ServiceSlot(id: 'side_b', sideId: 'side_b'),
      ],
    );

    test('tennis.itf.2026: 6 games to win a set, 7-point tie-break', () {
      final rule = tennisItf2026Ruleset(
        advantageMode: AdvantageMode.advantage,
        decidingSetFormat: const RegularDecidingSet(),
        service: service,
      );
      expect(rule.rulesetId, 'tennis.itf.2026');
      expect(rule.setRule.gamesToWin, 6);
      expect(rule.setRule.tieBreak?.target, 7);
      expect(rule.setRule.tieBreak?.winBy, 2);
      expect(rule.matchFormat.setsToWin, 2);
      expect(rule.sideIds, ['side_a', 'side_b']);
    });

    test('Match Tie-break constant is target 10, win by 2', () {
      expect(tennisMatchTieBreak.target, 10);
      expect(tennisMatchTieBreak.winBy, 2);
    });

    test('Set tie-break constant is target 7, win by 2', () {
      expect(tennisSetTieBreak.target, 7);
      expect(tennisSetTieBreak.winBy, 2);
    });

    test('deciding set index for Best of 3 is 2 (the third set)', () {
      final rule = tennisItf2026Ruleset(
        advantageMode: AdvantageMode.advantage,
        decidingSetFormat: const RegularDecidingSet(),
        service: service,
      );
      expect(rule.matchFormat.decidingSetIndex, 2);
    });

    test('No-Ad and Match Tie-break choices are both threaded through', () {
      final rule = tennisItf2026Ruleset(
        advantageMode: AdvantageMode.noAd,
        decidingSetFormat: const MatchTieBreakDecidingSet(
          matchTieBreak: tennisMatchTieBreak,
        ),
        service: service,
      );
      expect(rule.gameScoring.advantageMode, AdvantageMode.noAd);
      expect(
        rule.matchFormat.decidingSetFormat,
        isA<MatchTieBreakDecidingSet>(),
      );
    });
  });
}
