// Conformance runner for /contracts/match — see docs/CONFORMANCE.md.
//
// Loads every fixture directly from the shared `/contracts` directory (no
// copy under `mobile/`). A fixture's `expected` verifies the final
// `MatchState` after replaying every event (mirrors `score` fixtures);
// `expectedCheckpoints` verifies state at several `atMs` instants without
// depending on a real-time wait (mirrors `timer` fixtures) — match
// fixtures may use either style depending on what's being verified.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:playtap/domain/engines/match_engine.dart';
import 'package:playtap/domain/events/match_engine_event.dart';
import 'package:playtap/domain/models/match_rule.dart';
import 'package:playtap/domain/models/match_state.dart';

void main() {
  final contractsDir = Directory('../contracts/match');

  test('contracts/match directory must exist', () {
    expect(contractsDir.existsSync(), isTrue, reason: contractsDir.path);
  });
  if (!contractsDir.existsSync()) return;

  final fixtureFiles =
      contractsDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  test('at least one match fixture exists', () {
    expect(
      fixtureFiles,
      isNotEmpty,
      reason: 'No fixtures in ${contractsDir.path}',
    );
  });

  for (final file in fixtureFiles) {
    final fixture = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final id = fixture['id'] as String;
    final config = fixture['config'] as Map<String, dynamic>;
    final rule = MatchRule.fromJson(
      (config['matchRule'] as Map).cast<String, dynamic>(),
    );

    final events = (fixture['events'] as List)
        .cast<Map<String, dynamic>>()
        .map((e) {
          final type = MatchEngineEventType.tryFromJson(e['type'] as String);
          return type == null
              ? null
              : MatchEngineEvent(
                  id: e['id'] as String,
                  type: type,
                  atMs: e['tOffsetMs'] as int,
                  payload: (e['payload'] as Map).cast<String, dynamic>(),
                );
        })
        .whereType<MatchEngineEvent>()
        .toList();

    void checkAgainst(
      MatchState actual,
      Map<String, dynamic> expected,
      String label,
    ) {
      if (expected.containsKey('phase')) {
        expect(
          actual.phase.toJson(),
          expected['phase'],
          reason: '$label: phase',
        );
      }
      if (expected.containsKey('periodIndex')) {
        expect(
          actual.periodIndex,
          expected['periodIndex'],
          reason: '$label: periodIndex',
        );
      }
      if (expected.containsKey('isOvertimePeriod')) {
        expect(
          actual.isOvertimePeriod,
          expected['isOvertimePeriod'],
          reason: '$label: isOvertimePeriod',
        );
      }
      if (expected.containsKey('overtimeCount')) {
        expect(
          actual.overtimeCount,
          expected['overtimeCount'],
          reason: '$label: overtimeCount',
        );
      }
      if (expected.containsKey('matchEnded')) {
        expect(
          actual.matchEnded,
          expected['matchEnded'],
          reason: '$label: matchEnded',
        );
      }
      if (expected.containsKey('endReason')) {
        expect(
          actual.endReason?.toJson(),
          expected['endReason'],
          reason: '$label: endReason',
        );
      }
      final clock = expected['clock'] as Map<String, dynamic>?;
      if (clock != null) {
        if (clock.containsKey('status')) {
          expect(
            actual.clock.status.toJson(),
            clock['status'],
            reason: '$label: clock.status',
          );
        }
        if (clock.containsKey('elapsedMs')) {
          expect(
            actual.clock.elapsedMs,
            clock['elapsedMs'],
            reason: '$label: clock.elapsedMs',
          );
        }
        if (clock.containsKey('remainingMs')) {
          expect(
            actual.clock.remainingMs,
            clock['remainingMs'],
            reason: '$label: clock.remainingMs',
          );
        }
      }
    }

    if (fixture.containsKey('expected')) {
      test('match fixture: $id', () {
        final expected = fixture['expected'] as Map<String, dynamic>;
        final nowMs = events.isEmpty ? 0 : events.last.atMs;
        final actual = MatchEngine.replay(rule, events, nowMs: nowMs);
        checkAgainst(actual, expected, id);
      });
    }

    if (fixture.containsKey('expectedCheckpoints')) {
      final checkpoints = (fixture['expectedCheckpoints'] as List)
          .cast<Map<String, dynamic>>();
      for (final checkpoint in checkpoints) {
        final atMs = checkpoint['atMs'] as int;
        test('match fixture: $id @${atMs}ms', () {
          final eventsSoFar = events.where((e) => e.atMs <= atMs).toList();
          final actual = MatchEngine.replay(rule, eventsSoFar, nowMs: atMs);
          checkAgainst(actual, checkpoint, '$id@$atMs');
        });
      }
    }
  }
}
