import 'package:flutter_test/flutter_test.dart';
import 'package:playtap/domain/engines/clock_engine.dart';

void main() {
  group(
    'ClockAccumulator — the primitive TimerEngine and MatchEngine share',
    () {
      test('initial state: not started, elapsed 0 regardless of atMs', () {
        const clock = ClockAccumulator();
        expect(clock.started, isFalse);
        expect(clock.elapsedAt(999999), 0);
      });

      test('start then elapsed after 1s', () {
        var clock = const ClockAccumulator();
        clock = clock.apply(ClockCommandType.started, 0);
        expect(clock.started, isTrue);
        expect(clock.elapsedAt(1000), 1000);
      });

      test('a duplicate start is a no-op — does not reset runningSinceMs', () {
        var clock = const ClockAccumulator();
        clock = clock.apply(ClockCommandType.started, 0);
        clock = clock.apply(ClockCommandType.started, 500);
        expect(clock.elapsedAt(1000), 1000); // still measured from 0, not 500.
      });

      test(
        'pause freezes elapsed regardless of how much time passes after',
        () {
          var clock = const ClockAccumulator();
          clock = clock.apply(ClockCommandType.started, 0);
          clock = clock.apply(ClockCommandType.paused, 10000);
          expect(clock.elapsedAt(12000), 10000);
          expect(clock.elapsedAt(999000), 10000);
        },
      );

      test('pause while not running is a no-op', () {
        const clock = ClockAccumulator(); // never started.
        final after = clock.apply(ClockCommandType.paused, 5000);
        expect(after.started, isFalse);
        expect(after.accumulatedMs, 0);
      });

      test('resume continues accumulating from where it left off', () {
        var clock = const ClockAccumulator();
        clock = clock.apply(ClockCommandType.started, 0);
        clock = clock.apply(ClockCommandType.paused, 10000);
        clock = clock.apply(ClockCommandType.resumed, 15000);
        expect(clock.elapsedAt(20000), 15000);
      });

      test('resume while already running is a no-op', () {
        var clock = const ClockAccumulator();
        clock = clock.apply(ClockCommandType.started, 0);
        final beforeResume = clock;
        clock = clock.apply(ClockCommandType.resumed, 5000);
        expect(clock.runningSinceMs, beforeResume.runningSinceMs);
      });

      test('completed banks the final elapsed and freezes it', () {
        var clock = const ClockAccumulator();
        clock = clock.apply(ClockCommandType.started, 0);
        clock = clock.apply(ClockCommandType.completed, 7000);
        expect(clock.completed, isTrue);
        expect(clock.elapsedAt(999999), 7000); // atMs ignored once completed.
      });

      test(
        'completed while paused banks the accumulated value, not a live one',
        () {
          var clock = const ClockAccumulator();
          clock = clock.apply(ClockCommandType.started, 0);
          clock = clock.apply(ClockCommandType.paused, 10000);
          clock = clock.apply(ClockCommandType.completed, 999000);
          expect(clock.elapsedAt(0), 10000);
        },
      );

      test('completed while never started is a no-op', () {
        const clock = ClockAccumulator();
        final after = clock.apply(ClockCommandType.completed, 5000);
        expect(after.completed, isFalse);
      });

      test('any command after completed is a no-op', () {
        var clock = const ClockAccumulator();
        clock = clock.apply(ClockCommandType.started, 0);
        clock = clock.apply(ClockCommandType.completed, 5000);
        final after = clock.apply(ClockCommandType.resumed, 6000);
        expect(after.elapsedAt(999999), 5000);
      });

      test('long durations accumulate without drift', () {
        const oneHourMs = 3600 * 1000;
        var clock = const ClockAccumulator();
        clock = clock.apply(ClockCommandType.started, 0);
        expect(clock.elapsedAt(oneHourMs), oneHourMs);
      });

      test('a fresh accumulator per period resets independently — proves the '
          'primitive is reusable for MatchEngine\'s per-period clock without '
          'carrying state across periods', () {
        var period1 = const ClockAccumulator();
        period1 = period1.apply(ClockCommandType.started, 0);
        period1 = period1.apply(ClockCommandType.completed, 600000);

        var period2 = const ClockAccumulator(); // fresh instance, not reused.
        period2 = period2.apply(ClockCommandType.started, 600000);
        expect(period2.elapsedAt(650000), 50000);
        expect(period1.elapsedAt(999999), 600000); // untouched by period2.
      });
    },
  );
}
