import 'package:flutter_test/flutter_test.dart';
import 'package:playtap/domain/engines/team_foul_engine.dart';
import 'package:playtap/domain/events/team_foul_engine_event.dart';
import 'package:playtap/domain/models/team_foul_rule.dart';

const _basketballRule = TeamFoulRule(schemaVersion: 1, bonusThreshold: 5);
const _futsalRule = TeamFoulRule(schemaVersion: 1, bonusThreshold: 6);
const _sides = ['a', 'b'];

TeamFoulEngineEvent periodStarted(String id, {required String kind}) =>
    TeamFoulEngineEvent(
      id: id,
      type: TeamFoulEngineEventType.periodStarted,
      payload: {'kind': kind},
    );

TeamFoulEngineEvent foul(String id, String sideId) => TeamFoulEngineEvent(
  id: id,
  type: TeamFoulEngineEventType.foulAdded,
  payload: {'sideId': sideId},
);

TeamFoulEngineEvent undo(String id, {required String targetEventId}) =>
    TeamFoulEngineEvent(
      id: id,
      type: TeamFoulEngineEventType.undo,
      payload: {'targetEventId': targetEventId},
    );

void main() {
  group('TeamFoulEngine', () {
    test('both sides start at 0 even with no events', () {
      final state = TeamFoulEngine.replay(_basketballRule, _sides, []);
      expect(state.countsBySide, {'a': 0, 'b': 0});
    });

    test('increments the tapped side only', () {
      final events = [
        periodStarted('p0', kind: 'REGULATION'),
        foul('f1', 'a'),
        foul('f2', 'a'),
      ];
      final state = TeamFoulEngine.replay(_basketballRule, _sides, events);
      expect(state.countsBySide, {'a': 2, 'b': 0});
    });

    test('isInBonus flips true at the bonus threshold, not before', () {
      final events = [
        periodStarted('p0', kind: 'REGULATION'),
        for (var i = 0; i < 4; i++) foul('f$i', 'a'),
      ];
      final notYet = TeamFoulEngine.replay(_basketballRule, _sides, events);
      expect(notYet.isInBonus('a'), isFalse); // 4th foul: not yet bonus.

      final atThreshold = TeamFoulEngine.replay(_basketballRule, _sides, [
        ...events,
        foul('f4', 'a'),
      ]);
      expect(atThreshold.isInBonus('a'), isTrue); // 5th foul: bonus.
    });

    test('futsal DFKSAF threshold is 6, not 5', () {
      final events = [
        periodStarted('p0', kind: 'REGULATION'),
        for (var i = 0; i < 5; i++) foul('f$i', 'a'),
      ];
      final at5 = TeamFoulEngine.replay(_futsalRule, _sides, events);
      expect(at5.isInBonus('a'), isFalse);
      final at6 = TeamFoulEngine.replay(_futsalRule, _sides, [
        ...events,
        foul('f5', 'a'),
      ]);
      expect(at6.isInBonus('a'), isTrue);
    });

    test(
      'a REGULATION PERIOD_STARTED resets the count to zero for both sides',
      () {
        final events = [
          periodStarted('p0', kind: 'REGULATION'),
          foul('f1', 'a'),
          foul('f2', 'b'),
          foul('f3', 'b'),
          periodStarted('p1', kind: 'REGULATION'), // next quarter.
        ];
        final state = TeamFoulEngine.replay(_basketballRule, _sides, events);
        expect(state.countsBySide, {'a': 0, 'b': 0});
      },
    );

    test('an OVERTIME PERIOD_STARTED does NOT reset — carries forward from '
        'the last regulation period (FIBA: OT fouls count as Q4 fouls)', () {
      final events = [
        periodStarted('p0', kind: 'REGULATION'),
        foul('f1', 'a'),
        foul('f2', 'a'),
        foul('f3', 'a'),
        periodStarted('p1', kind: 'OVERTIME'),
        foul('f4', 'a'),
      ];
      final state = TeamFoulEngine.replay(_basketballRule, _sides, events);
      expect(state.countsBySide['a'], 4); // 3 from Q4 + 1 in OT, not reset.
    });

    test('a second OVERTIME PERIOD_STARTED also does not reset', () {
      final events = [
        periodStarted('p0', kind: 'REGULATION'),
        foul('f1', 'a'),
        foul('f2', 'a'),
        periodStarted('p1', kind: 'OVERTIME'),
        foul('f3', 'a'),
        periodStarted('p2', kind: 'OVERTIME'),
      ];
      final state = TeamFoulEngine.replay(_basketballRule, _sides, events);
      expect(state.countsBySide['a'], 3); // still carrying.
    });

    test(
      'undo reopens the count and can reverse a bonus threshold crossing',
      () {
        final events = [
          periodStarted('p0', kind: 'REGULATION'),
          for (var i = 0; i < 5; i++) foul('f$i', 'a'),
          undo('u1', targetEventId: 'f4'),
        ];
        final state = TeamFoulEngine.replay(_basketballRule, _sides, events);
        expect(state.countsBySide['a'], 4);
        expect(state.isInBonus('a'), isFalse);
      },
    );

    test('replay is deterministic and duplicate event ids apply once', () {
      final events = [
        periodStarted('p0', kind: 'REGULATION'),
        foul('f1', 'a'),
        foul('f1', 'a'), // duplicate id.
      ];
      final s1 = TeamFoulEngine.replay(_basketballRule, _sides, events);
      final s2 = TeamFoulEngine.replay(_basketballRule, _sides, events);
      expect(s1, s2);
      expect(s1.countsBySide['a'], 1);
    });
  });
}
