// Unit coverage for the Tennis config -> RacketMatchRule mapping — the bug
// class this guards against: a doubles service order that doesn't actually
// alternate teams, or an initial-server choice silently dropped between the
// config screen and the persisted rule (see the note on
// `RacketSessionSnapshot.racketRule`: the UI must always read back what was
// actually persisted, never recompute it).
import 'package:flutter_test/flutter_test.dart';
import 'package:playtap/domain/models/racket_rule.dart';
import 'package:playtap/features/score_tennis/tennis_actions.dart';
import 'package:playtap/features/score_tennis/tennis_format.dart';

void main() {
  group('buildTennisServiceOrder', () {
    test('singles: 2 slots, one per side, no playerIndex', () {
      final service = buildTennisServiceOrder(
        matchType: TennisMatchType.singles,
        initialServerSideId: sideATennisId,
      );
      expect(service.order, hasLength(2));
      expect(service.order[0].id, sideATennisId);
      expect(service.order[0].sideId, sideATennisId);
      expect(service.order[0].playerIndex, isNull);
      expect(service.order[1].sideId, sideBTennisId);
    });

    test('singles: starting side_b puts side_b first', () {
      final service = buildTennisServiceOrder(
        matchType: TennisMatchType.singles,
        initialServerSideId: sideBTennisId,
      );
      expect(service.order[0].sideId, sideBTennisId);
      expect(service.order[1].sideId, sideATennisId);
    });

    test(
      'doubles: 4 slots strictly alternating teams, starting side first',
      () {
        final service = buildTennisServiceOrder(
          matchType: TennisMatchType.doubles,
          initialServerSideId: sideATennisId,
          initialServerPlayerIndex: 1,
        );
        expect(service.order, hasLength(4));
        final sideSequence = service.order.map((s) => s.sideId).toList();
        expect(sideSequence, [
          sideATennisId,
          sideBTennisId,
          sideATennisId,
          sideBTennisId,
        ]);
        // The chosen starting player (index 1) serves first; their partner
        // (index 0) serves the side's second turn.
        expect(service.order[0].playerIndex, 1);
        expect(service.order[2].playerIndex, 0);
        // The other side's roster order is used as-is for both its turns.
        expect(service.order[1].playerIndex, 0);
        expect(service.order[3].playerIndex, 1);
      },
    );

    test('every slot id is unique', () {
      final service = buildTennisServiceOrder(
        matchType: TennisMatchType.doubles,
        initialServerSideId: sideBTennisId,
        initialServerPlayerIndex: 0,
      );
      final ids = service.order.map((s) => s.id).toSet();
      expect(ids, hasLength(4));
    });
  });

  group('buildDecidingSetFormat', () {
    test('tieBreakSet resolves to RegularDecidingSet', () {
      final format = buildDecidingSetFormat(
        TennisDecidingSetChoice.tieBreakSet,
      );
      expect(format, isA<RegularDecidingSet>());
    });

    test(
      'matchTieBreak10 resolves to a target-10 MatchTieBreakDecidingSet',
      () {
        final format = buildDecidingSetFormat(
          TennisDecidingSetChoice.matchTieBreak10,
        );
        expect(format, isA<MatchTieBreakDecidingSet>());
        expect((format as MatchTieBreakDecidingSet).matchTieBreak.target, 10);
      },
    );
  });

  group('buildTennisRule', () {
    test('threads advantage mode, deciding set, and service through', () {
      final service = buildTennisServiceOrder(
        matchType: TennisMatchType.singles,
        initialServerSideId: sideATennisId,
      );
      final rule = buildTennisRule(
        advantageMode: AdvantageMode.noAd,
        decidingSet: TennisDecidingSetChoice.matchTieBreak10,
        service: service,
      );
      expect(rule.rulesetId, 'tennis.itf.2026');
      expect(rule.gameScoring.advantageMode, AdvantageMode.noAd);
      expect(
        rule.matchFormat.decidingSetFormat,
        isA<MatchTieBreakDecidingSet>(),
      );
      expect(rule.service, service);
      expect(rule.sideIds, [sideATennisId, sideBTennisId]);
    });

    test(
      'default Best of 3 / tie-break-set config round-trips through JSON',
      () {
        final service = buildTennisServiceOrder(
          matchType: TennisMatchType.doubles,
          initialServerSideId: sideBTennisId,
          initialServerPlayerIndex: 1,
        );
        final rule = buildTennisRule(
          advantageMode: AdvantageMode.advantage,
          decidingSet: TennisDecidingSetChoice.tieBreakSet,
          service: service,
        );
        final decoded = rule.toJson();
        final rebuilt = RacketMatchRule.fromJson(decoded);
        expect(rebuilt.toJson(), decoded);
      },
    );
  });

  group('TennisMatchType', () {
    test('playersPerSide: 1 for singles, 2 for doubles', () {
      expect(TennisMatchType.singles.playersPerSide, 1);
      expect(TennisMatchType.doubles.playersPerSide, 2);
    });

    test('fromPlayersPerSide recovers the match type without ambiguity', () {
      expect(TennisMatchType.fromPlayersPerSide(1), TennisMatchType.singles);
      expect(TennisMatchType.fromPlayersPerSide(2), TennisMatchType.doubles);
    });
  });
}
