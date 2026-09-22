// Unit coverage for the Pétanque format -> ScoreRule mapping — the bug
// class this guards against: tête-à-tête (max 3 boules/side/mène per FIPJP
// Article 1, see docs/SPORT_RULES.md) accepting +4/+5/+6 because the
// persisted rule used a hardcoded [1..6] regardless of format.
import 'package:flutter_test/flutter_test.dart';
import 'package:playtap/domain/engines/score_engine.dart';
import 'package:playtap/domain/events/score_engine_event.dart';
import 'package:playtap/features/score_petanque/petanque_actions.dart';
import 'package:playtap/features/score_petanque/petanque_format.dart';

ScoreEngineEvent point(String id, String side, int amount) => ScoreEngineEvent(
  id: id,
  type: ScoreEngineEventType.pointScored,
  payload: {'side': side, 'amount': amount},
);

void main() {
  group('buildPetanqueRule — format-dependent allowedIncrements', () {
    test('tête-à-tête allows exactly 1, 2, 3', () {
      final rule = buildPetanqueRule(PetanqueFormat.headToHead);
      expect(rule.allowedIncrements, [1, 2, 3]);
    });

    test('doublette allows 1 through 6', () {
      final rule = buildPetanqueRule(PetanqueFormat.doublette);
      expect(rule.allowedIncrements, [1, 2, 3, 4, 5, 6]);
    });

    test('triplette allows 1 through 6', () {
      final rule = buildPetanqueRule(PetanqueFormat.triplette);
      expect(rule.allowedIncrements, [1, 2, 3, 4, 5, 6]);
    });

    test('tête-à-tête still composes the target-13 win condition', () {
      final rule = buildPetanqueRule(PetanqueFormat.headToHead);
      expect(rule.target?.targetScore, 13);
      expect(rule.target?.automaticCompletion, isTrue);
    });
  });

  group('ScoreEngine — tête-à-tête caps a mène at +3', () {
    test('+1, +2 and +3 are accepted', () {
      final rule = buildPetanqueRule(PetanqueFormat.headToHead);
      final state = ScoreEngine.replay(rule, [
        point('e1', sideATeamId, 1),
        point('e2', sideATeamId, 2),
        point('e3', sideBTeamId, 3),
      ]);
      expect(state.scores, {sideATeamId: 3, sideBTeamId: 3});
      expect(state.appliedEventCount, 3);
    });

    test('+4, +5 and +6 are rejected, not silently clamped', () {
      final rule = buildPetanqueRule(PetanqueFormat.headToHead);
      final state = ScoreEngine.replay(rule, [
        point('e1', sideATeamId, 4),
        point('e2', sideATeamId, 5),
        point('e3', sideATeamId, 6),
      ]);
      expect(state.scores, {sideATeamId: 0, sideBTeamId: 0});
      expect(state.appliedEventCount, 0);
      expect(state.rounds, isEmpty);
    });

    test('doublette accepts up to +6 (unlike tête-à-tête)', () {
      final rule = buildPetanqueRule(PetanqueFormat.doublette);
      final state = ScoreEngine.replay(rule, [point('e1', sideATeamId, 6)]);
      expect(state.scores[sideATeamId], 6);
    });

    test('triplette accepts up to +6', () {
      final rule = buildPetanqueRule(PetanqueFormat.triplette);
      final state = ScoreEngine.replay(rule, [point('e1', sideATeamId, 6)]);
      expect(state.scores[sideATeamId], 6);
    });
  });

  group('PetanqueFormat.fromPersisted — recoverable without ambiguity', () {
    test('round-trips every format through its persisted shape', () {
      for (final format in PetanqueFormat.values) {
        final recovered = PetanqueFormat.fromPersisted(
          playersPerSide: format.playersPerSide,
          allowedIncrements: format.allowedIncrements,
        );
        expect(recovered, format, reason: 'failed to recover $format');
      }
    });

    test('an unrecognized combination returns null, never guesses', () {
      expect(
        PetanqueFormat.fromPersisted(
          playersPerSide: 4,
          allowedIncrements: const [1, 2],
        ),
        isNull,
      );
    });
  });
}
