// Conformance runner for /contracts/score — see docs/CONFORMANCE.md.
//
// Loads every fixture directly from the shared `/contracts` directory (no
// copy under `mobile/`, so the fixtures can never drift from what Swift/
// Kotlin will eventually run against the same files). Fixtures whose
// `config.mode` isn't implemented yet are reported as explicitly skipped
// (Phase 1B.1 only implements FREE_SCORE) — never silently passed.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:playtap/domain/engines/score_engine.dart';
import 'package:playtap/domain/events/score_engine_event.dart';
import 'package:playtap/domain/models/score_rule.dart';

void main() {
  final contractsDir = Directory('../contracts/score');

  if (!contractsDir.existsSync()) {
    test('contracts/score directory must exist', () {
      fail('Expected ${contractsDir.path} to exist relative to mobile/.');
    });
    return;
  }

  final fixtureFiles =
      contractsDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  test('at least one score fixture exists', () {
    expect(
      fixtureFiles,
      isNotEmpty,
      reason: 'No fixtures found in ${contractsDir.path}',
    );
  });

  for (final file in fixtureFiles) {
    final fixture = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final id = fixture['id'] as String;
    final config = fixture['config'] as Map<String, dynamic>;
    final mode = config['mode'] as String;

    test('score fixture: $id ($mode)', () {
      late final ScoreRule rule;
      try {
        rule = ScoreRule.fromJson(config);
      } on UnsupportedScoreModeException {
        markTestSkipped(
          'Mode $mode is not implemented yet (Phase 1B.1 only covers '
          'FREE_SCORE) — see docs/ROADMAP.md.',
        );
        return;
      }

      final events = (fixture['events'] as List)
          .cast<Map<String, dynamic>>()
          .map((e) {
            final type = ScoreEngineEventType.tryFromJson(e['type'] as String);
            expect(
              type,
              isNotNull,
              reason: 'Unknown score engine event type: ${e['type']}',
            );
            return ScoreEngineEvent(
              id: e['id'] as String,
              type: type!,
              payload: (e['payload'] as Map).cast<String, dynamic>(),
            );
          })
          .toList();

      final expected = fixture['expected'] as Map<String, dynamic>;
      final actual = ScoreEngine.replay(rule, events);

      expect(
        actual.scores,
        expected['scores'],
        reason: 'scores mismatch for fixture $id',
      );
      expect(actual.matchComplete, expected['matchComplete']);
      expect(actual.winner, expected['winner']);
      expect(actual.appliedEventCount, expected['appliedEventCount']);
    });
  }
}
