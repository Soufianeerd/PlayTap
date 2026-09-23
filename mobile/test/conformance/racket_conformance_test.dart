// Conformance runner for /contracts/racket — see docs/CONFORMANCE.md.
//
// Loads every fixture directly from the shared `/contracts` directory (no
// copy under `mobile/`, so the fixtures can never drift from what Swift/
// Kotlin will eventually run against the same files). Racket fixtures use
// either `expected` (final-state check, like `score`) or
// `expectedCheckpoints` (a list of `{afterPointNumber, ...fields}` —
// racket's own checkpoint shape, verifying `RacketEngine.replay` against a
// *prefix* of the point log at several points, e.g. to check the
// tie-break service rotation point by point without depending on the
// final state alone — mirrors `match`/`timer`'s `expectedCheckpoints`
// flexibility, see CONFORMANCE.md).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:playtap/domain/engines/racket_engine.dart';
import 'package:playtap/domain/events/racket_engine_event.dart';
import 'package:playtap/domain/models/racket_rule.dart';
import 'package:playtap/domain/models/racket_state.dart';

void main() {
  final contractsDir = Directory('../contracts/racket');

  if (!contractsDir.existsSync()) {
    test('contracts/racket directory must exist', () {
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

  test('at least one racket fixture exists', () {
    expect(
      fixtureFiles,
      isNotEmpty,
      reason: 'No fixtures found in ${contractsDir.path}',
    );
  });

  for (final file in fixtureFiles) {
    final fixture = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final id = fixture['id'] as String;

    test('racket fixture: $id', () {
      final rule = RacketMatchRule.fromJson(
        (fixture['config'] as Map).cast<String, dynamic>(),
      );

      final events = (fixture['events'] as List)
          .cast<Map<String, dynamic>>()
          .map((e) {
            final type = RacketEngineEventType.tryFromJson(e['type'] as String);
            expect(
              type,
              isNotNull,
              reason: 'Unknown racket engine event type: ${e['type']}',
            );
            return RacketEngineEvent(
              id: e['id'] as String,
              type: type!,
              payload: (e['payload'] as Map).cast<String, dynamic>(),
            );
          })
          .toList();

      if (fixture.containsKey('expectedCheckpoints')) {
        final checkpoints = (fixture['expectedCheckpoints'] as List)
            .cast<Map<String, dynamic>>();
        for (final checkpoint in checkpoints) {
          final n = checkpoint['afterPointNumber'] as int;
          final state = RacketEngine.replay(rule, events.take(n).toList());
          _checkState(
            state,
            checkpoint,
            id: '$id (afterPointNumber $n${checkpoint['label'] != null ? ", ${checkpoint['label']}" : ""})',
          );
        }
        return;
      }

      final expected = fixture['expected'] as Map<String, dynamic>;
      final state = RacketEngine.replay(rule, events);
      _checkState(state, expected, id: id);
    });
  }
}

void _checkState(
  RacketMatchState state,
  Map<String, dynamic> expected, {
  required String id,
}) {
  if (expected.containsKey('currentGamePoints')) {
    expect(
      state.currentGamePoints,
      expected['currentGamePoints'],
      reason: '$id: currentGamePoints',
    );
  }
  if (expected.containsKey('gamesWonInCurrentSet')) {
    expect(
      state.gamesWonInCurrentSet,
      expected['gamesWonInCurrentSet'],
      reason: '$id: gamesWonInCurrentSet',
    );
  }
  if (expected.containsKey('setsWon')) {
    expect(state.setsWon, expected['setsWon'], reason: '$id: setsWon');
  }
  if (expected.containsKey('currentSetIndex')) {
    expect(
      state.currentSetIndex,
      expected['currentSetIndex'],
      reason: '$id: currentSetIndex',
    );
  }
  if (expected.containsKey('isTieBreak')) {
    expect(state.isTieBreak, expected['isTieBreak'], reason: '$id: isTieBreak');
  }
  if (expected.containsKey('isMatchTieBreak')) {
    expect(
      state.isMatchTieBreak,
      expected['isMatchTieBreak'],
      reason: '$id: isMatchTieBreak',
    );
  }
  if (expected.containsKey('tieBreakPoints')) {
    expect(
      state.tieBreakPoints,
      expected['tieBreakPoints'],
      reason: '$id: tieBreakPoints',
    );
  }
  if (expected.containsKey('matchComplete')) {
    expect(
      state.matchComplete,
      expected['matchComplete'],
      reason: '$id: matchComplete',
    );
  }
  if (expected.containsKey('winner')) {
    expect(state.winner, expected['winner'], reason: '$id: winner');
  }
  if (expected.containsKey('appliedEventCount')) {
    expect(
      state.appliedEventCount,
      expected['appliedEventCount'],
      reason: '$id: appliedEventCount',
    );
  }
  if (expected.containsKey('currentServerSlotId')) {
    expect(
      state.currentServerSlotId,
      expected['currentServerSlotId'],
      reason: '$id: currentServerSlotId',
    );
  }
  if (expected.containsKey('changeEndsDue')) {
    expect(
      state.changeEndsDue,
      expected['changeEndsDue'],
      reason: '$id: changeEndsDue',
    );
  }
  if (expected.containsKey('completedSets')) {
    final actual = state.completedSets.map((s) => s.toJson()).toList();
    expect(actual, expected['completedSets'], reason: '$id: completedSets');
  }
}
