// Conformance runner for /contracts/timer — see docs/CONFORMANCE.md.
//
// Loads every fixture directly from the shared `/contracts` directory (no
// copy under `mobile/`). Each fixture defines `expectedCheckpoints`: the
// engine is asked for its state "as if now = atMs" for each one — never a
// real-time wait (see the Phase 1B.2 brief, section 31).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:playtap/domain/engines/timer_engine.dart';
import 'package:playtap/domain/events/timer_engine_event.dart';
import 'package:playtap/domain/models/timer_spec.dart';

void main() {
  final contractsDir = Directory('../contracts/timer');

  test('contracts/timer directory must exist', () {
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

  test('at least one timer fixture exists', () {
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
    final spec = TimerSpec.fromJson(config);

    final events = (fixture['events'] as List)
        .cast<Map<String, dynamic>>()
        .map((e) {
          final type = TimerEngineEventType.tryFromJson(e['type'] as String);
          return type == null
              ? null
              : TimerEngineEvent(
                  id: e['id'] as String,
                  type: type,
                  atMs: e['tOffsetMs'] as int,
                );
        })
        .whereType<TimerEngineEvent>()
        .toList();

    final checkpoints = (fixture['expectedCheckpoints'] as List)
        .cast<Map<String, dynamic>>();

    for (final checkpoint in checkpoints) {
      final atMs = checkpoint['atMs'] as int;
      test('timer fixture: $id @${atMs}ms', () {
        // Only events that have actually happened "by" this checkpoint are
        // fed to the engine — see docs/CONFORMANCE.md: a checkpoint asks
        // for the state "as if now = atMs", not after the full log.
        final eventsSoFar = events.where((e) => e.atMs <= atMs).toList();
        final actual = TimerEngine.replay(spec, eventsSoFar, nowMs: atMs);

        if (checkpoint.containsKey('status')) {
          expect(actual.status.toJson(), checkpoint['status']);
        }
        if (checkpoint.containsKey('elapsedMs')) {
          expect(actual.elapsedMs, checkpoint['elapsedMs']);
        }
        if (checkpoint.containsKey('remainingMs')) {
          expect(actual.remainingMs, checkpoint['remainingMs']);
        }
        if (checkpoint.containsKey('laps')) {
          final expectedLaps = (checkpoint['laps'] as List)
              .cast<Map<String, dynamic>>();
          expect(actual.laps, hasLength(expectedLaps.length));
          for (var i = 0; i < expectedLaps.length; i++) {
            expect(actual.laps[i].lapNumber, expectedLaps[i]['lapNumber']);
            expect(
              actual.laps[i].cumulativeElapsedMs,
              expectedLaps[i]['cumulativeElapsedMs'],
            );
            expect(actual.laps[i].splitMs, expectedLaps[i]['splitMs']);
          }
        }
      });
    }
  }
}
