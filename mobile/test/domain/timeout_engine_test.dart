import 'package:flutter_test/flutter_test.dart';
import 'package:playtap/domain/engines/timeout_engine.dart';
import 'package:playtap/domain/events/timeout_engine_event.dart';
import 'package:playtap/domain/models/timeout_rule.dart';

// Basketball-shaped rule: 2 in H1 (Q0-Q1), 3 in H2 (Q2-Q3), sub-cap of 2
// usable once Q3 (index 3) has <=120000ms remaining, 1 per overtime.
final _basketballRule = TimeoutRule(
  schemaVersion: 1,
  regulationGroups: const [
    TimeoutQuotaGroup(periodIndices: [0, 1], quota: 2),
    TimeoutQuotaGroup(periodIndices: [2, 3], quota: 3),
  ],
  quotaPerOvertimePeriod: 1,
  lateGameSubCap: const TimeoutLateGameSubCap(
    periodIndex: 3,
    remainingMsThreshold: 120000,
    maxUsableWithinWindow: 2,
  ),
);

// Futsal-shaped rule: 1 per period, each its own group, none in overtime.
const _futsalRule = TimeoutRule(
  schemaVersion: 1,
  regulationGroups: [
    TimeoutQuotaGroup(periodIndices: [0], quota: 1),
    TimeoutQuotaGroup(periodIndices: [1], quota: 1),
  ],
  quotaPerOvertimePeriod: 0,
);

TimeoutEngineEvent taken(
  String id, {
  required String sideId,
  required int periodIndex,
  bool isOvertimePeriod = false,
  int overtimeCount = 0,
  int periodRemainingMsAtTime = 600000,
}) => TimeoutEngineEvent(
  id: id,
  type: TimeoutEngineEventType.taken,
  payload: {
    'sideId': sideId,
    'periodIndex': periodIndex,
    'isOvertimePeriod': isOvertimePeriod,
    'overtimeCount': overtimeCount,
    'periodRemainingMsAtTime': periodRemainingMsAtTime,
  },
);

TimeoutEngineEvent undo(String id, {required String targetEventId}) =>
    TimeoutEngineEvent(
      id: id,
      type: TimeoutEngineEventType.undo,
      payload: {'targetEventId': targetEventId},
    );

void main() {
  group('TimeoutEngine — Basketball-shaped rule', () {
    test('remaining is the full group quota before any timeout is taken', () {
      final state = TimeoutEngine.replay([]);
      expect(
        TimeoutEngine.remainingForSide(
          _basketballRule,
          state,
          'a',
          periodIndex: 0,
          isOvertimePeriod: false,
          overtimeCount: 0,
          periodRemainingMs: 600000,
        ),
        2,
      );
    });

    test(
      'a timeout in Q1 (group 0-1) decrements the H1 group for both Q0 and Q1',
      () {
        final events = [
          taken(
            'e1',
            sideId: 'a',
            periodIndex: 0,
            periodRemainingMsAtTime: 300000,
          ),
        ];
        final state = TimeoutEngine.replay(events);
        expect(
          TimeoutEngine.remainingForSide(
            _basketballRule,
            state,
            'a',
            periodIndex: 1, // still in the same H1 group.
            isOvertimePeriod: false,
            overtimeCount: 0,
            periodRemainingMs: 600000,
          ),
          1,
        );
      },
    );

    test('H1 usage never affects H2s separate quota', () {
      final events = [
        taken('e1', sideId: 'a', periodIndex: 0),
        taken('e2', sideId: 'a', periodIndex: 1),
      ]; // both of H1's 2 used.
      final state = TimeoutEngine.replay(events);
      expect(
        TimeoutEngine.remainingForSide(
          _basketballRule,
          state,
          'a',
          periodIndex: 2, // Q3 -> H2 group.
          isOvertimePeriod: false,
          overtimeCount: 0,
          periodRemainingMs: 600000,
        ),
        3, // full H2 quota, untouched.
      );
    });

    test('over-quota is rejected: remaining never goes negative and the '
        'controller must refuse a take once remaining is 0', () {
      final events = [
        taken('e1', sideId: 'a', periodIndex: 0),
        taken('e2', sideId: 'a', periodIndex: 0),
      ];
      final state = TimeoutEngine.replay(events);
      expect(
        TimeoutEngine.remainingForSide(
          _basketballRule,
          state,
          'a',
          periodIndex: 0,
          isOvertimePeriod: false,
          overtimeCount: 0,
          periodRemainingMs: 600000,
        ),
        0,
      );
    });

    test(
      'late-game sub-cap: at most 2 of the 3 H2 timeouts usable once Q3 <= 2:00',
      () {
        final events = [
          taken(
            'e1',
            sideId: 'a',
            periodIndex: 3,
            periodRemainingMsAtTime: 100000,
          ), // inside the window.
          taken(
            'e2',
            sideId: 'a',
            periodIndex: 3,
            periodRemainingMsAtTime: 90000,
          ), // inside the window: 2nd.
        ];
        final state = TimeoutEngine.replay(events);
        // Group quota remaining would be 1 (3 - 2), but the window cap (2
        // already used inside the window) reduces it further to 0.
        expect(
          TimeoutEngine.remainingForSide(
            _basketballRule,
            state,
            'a',
            periodIndex: 3,
            isOvertimePeriod: false,
            overtimeCount: 0,
            periodRemainingMs: 80000, // still inside the window.
          ),
          0,
        );
      },
    );

    test('the sub-cap does not apply before entering the late-game window', () {
      final events = [
        taken(
          'e1',
          sideId: 'a',
          periodIndex: 3,
          periodRemainingMsAtTime: 300000,
        ),
      ];
      final state = TimeoutEngine.replay(events);
      expect(
        TimeoutEngine.remainingForSide(
          _basketballRule,
          state,
          'a',
          periodIndex: 3,
          isOvertimePeriod: false,
          overtimeCount: 0,
          periodRemainingMs: 300000, // not yet inside the window.
        ),
        2, // 3 - 1, sub-cap irrelevant outside the window.
      );
    });

    test(
      'overtime gets a fresh quota per OT number, independent of regulation usage',
      () {
        final events = [
          taken('e1', sideId: 'a', periodIndex: 2),
          taken('e2', sideId: 'a', periodIndex: 2),
          taken('e3', sideId: 'a', periodIndex: 2), // H2 quota exhausted.
        ];
        final state = TimeoutEngine.replay(events);
        expect(
          TimeoutEngine.remainingForSide(
            _basketballRule,
            state,
            'a',
            periodIndex: 0,
            isOvertimePeriod: true,
            overtimeCount: 1,
            periodRemainingMs: 300000,
          ),
          1, // OT1's own fresh quota.
        );
      },
    );

    test('a used OT1 timeout does not carry into OT2', () {
      final events = [
        taken(
          'e1',
          sideId: 'a',
          periodIndex: 0,
          isOvertimePeriod: true,
          overtimeCount: 1,
        ),
      ];
      final state = TimeoutEngine.replay(events);
      expect(
        TimeoutEngine.remainingForSide(
          _basketballRule,
          state,
          'a',
          periodIndex: 0,
          isOvertimePeriod: true,
          overtimeCount: 2,
          periodRemainingMs: 300000,
        ),
        1, // OT2 is fresh.
      );
    });

    test('undo reopens a used timeout', () {
      final events = [
        taken('e1', sideId: 'a', periodIndex: 0),
        undo('e2', targetEventId: 'e1'),
      ];
      final state = TimeoutEngine.replay(events);
      expect(
        TimeoutEngine.remainingForSide(
          _basketballRule,
          state,
          'a',
          periodIndex: 0,
          isOvertimePeriod: false,
          overtimeCount: 0,
          periodRemainingMs: 600000,
        ),
        2,
      );
    });

    test('sides are independent', () {
      final events = [taken('e1', sideId: 'a', periodIndex: 0)];
      final state = TimeoutEngine.replay(events);
      expect(
        TimeoutEngine.remainingForSide(
          _basketballRule,
          state,
          'b',
          periodIndex: 0,
          isOvertimePeriod: false,
          overtimeCount: 0,
          periodRemainingMs: 600000,
        ),
        2,
      );
    });
  });

  group('TimeoutEngine — Futsal-shaped rule (per-period groups, no OT)', () {
    test('period 0 and period 1 have fully independent quotas', () {
      final events = [taken('e1', sideId: 'a', periodIndex: 0)];
      final state = TimeoutEngine.replay(events);
      expect(
        TimeoutEngine.remainingForSide(
          _futsalRule,
          state,
          'a',
          periodIndex: 1,
          isOvertimePeriod: false,
          overtimeCount: 0,
          periodRemainingMs: 1200000,
        ),
        1, // period 1's own quota, untouched by period 0's use.
      );
    });

    test('no timeouts at all in overtime', () {
      final state = TimeoutEngine.replay([]);
      expect(
        TimeoutEngine.remainingForSide(
          _futsalRule,
          state,
          'a',
          periodIndex: 0,
          isOvertimePeriod: true,
          overtimeCount: 1,
          periodRemainingMs: 300000,
        ),
        0,
      );
    });
  });
}
