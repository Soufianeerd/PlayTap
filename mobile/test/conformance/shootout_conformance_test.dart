// Conformance runner for /contracts/shootout — see docs/CONFORMANCE.md.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:playtap/domain/engines/shootout_engine.dart';
import 'package:playtap/domain/events/shootout_engine_event.dart';
import 'package:playtap/domain/models/shootout_rule.dart';

void main() {
  final contractsDir = Directory('../contracts/shootout');

  test('contracts/shootout directory must exist', () {
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

  test('at least one shootout fixture exists', () {
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
    final rule = ShootoutRule.fromJson(
      (config['shootoutRule'] as Map).cast<String, dynamic>(),
    );
    final sideIds = (config['sideIds'] as List).cast<String>();

    test('shootout fixture: $id', () {
      final events = (fixture['events'] as List)
          .cast<Map<String, dynamic>>()
          .map((e) {
            final type = ShootoutEngineEventType.tryFromJson(
              e['type'] as String,
            );
            expect(
              type,
              isNotNull,
              reason: 'Unknown shootout event type: ${e['type']}',
            );
            return ShootoutEngineEvent(
              id: e['id'] as String,
              type: type!,
              payload: (e['payload'] as Map).cast<String, dynamic>(),
            );
          })
          .toList();

      final expected = fixture['expected'] as Map<String, dynamic>;
      final actual = ShootoutEngine.replay(rule, sideIds, events);

      expect(
        actual.scores,
        expected['scores'],
        reason: 'scores mismatch for $id',
      );
      expect(
        actual.decided,
        expected['decided'],
        reason: 'decided mismatch for $id',
      );
      expect(
        actual.winner,
        expected['winner'],
        reason: 'winner mismatch for $id',
      );
      if (expected.containsKey('attemptsCount')) {
        expect(
          actual.attempts.length,
          expected['attemptsCount'],
          reason: 'attemptsCount mismatch for $id',
        );
      }
    });
  }
}
