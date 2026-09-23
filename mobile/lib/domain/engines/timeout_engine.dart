import '../events/timeout_engine_event.dart';
import '../models/timeout_rule.dart';
import '../models/timeout_state.dart';

/// Pure, deterministic timeout-quota derivation — generic across every
/// team-match sport that has timeouts (Basketball, Futsal in this phase;
/// see `TimeoutRule`). No sport identity anywhere: Basketball's per-half
/// grouping and Futsal's per-period grouping are both just different
/// [TimeoutRule.regulationGroups] data replayed through the exact same
/// logic.
abstract final class TimeoutEngine {
  static TimeoutState replay(List<TimeoutEngineEvent> events) {
    final undoneIds = <String>{};
    for (final event in events) {
      if (event.type != TimeoutEngineEventType.undo) continue;
      final target = event.payload['targetEventId'] as String?;
      if (target != null) undoneIds.add(target);
    }

    final records = <TimeoutRecord>[];
    final seenEventIds = <String>{};
    for (final event in events) {
      if (event.type == TimeoutEngineEventType.undo) continue; // instruction.
      if (undoneIds.contains(event.id)) continue; // this event was undone.
      if (!seenEventIds.add(event.id)) continue; // duplicate id: no-op.
      if (event.type != TimeoutEngineEventType.taken) continue;

      records.add(
        TimeoutRecord(
          eventId: event.id,
          sideId: event.payload['sideId'] as String,
          periodIndex: event.payload['periodIndex'] as int,
          isOvertimePeriod: event.payload['isOvertimePeriod'] as bool,
          overtimeCount: event.payload['overtimeCount'] as int,
          periodRemainingMsAtTime:
              event.payload['periodRemainingMsAtTime'] as int,
        ),
      );
    }

    return TimeoutState(records: records);
  }

  /// How many timeouts [sideId] has left *right now*, given the current
  /// match context — a separate query against [state], never baked into
  /// [replay] itself (mirrors `MatchEngine.decideNextPhase` taking current
  /// state as an explicit input). Returns 0 (never negative) when the
  /// late-game sub-cap further restricts what the group quota alone would
  /// allow — see `TimeoutLateGameSubCap`'s doc note.
  static int remainingForSide(
    TimeoutRule rule,
    TimeoutState state,
    String sideId, {
    required int periodIndex,
    required bool isOvertimePeriod,
    required int overtimeCount,
    required int periodRemainingMs,
  }) {
    final sideRecords = state.records.where((r) => r.sideId == sideId);

    if (isOvertimePeriod) {
      final usedThisOvertime = sideRecords
          .where((r) => r.isOvertimePeriod && r.overtimeCount == overtimeCount)
          .length;
      return (rule.quotaPerOvertimePeriod - usedThisOvertime).clamp(
        0,
        rule.quotaPerOvertimePeriod,
      );
    }

    final group = rule.regulationGroups.firstWhere(
      (g) => g.periodIndices.contains(periodIndex),
      orElse: () => const TimeoutQuotaGroup(periodIndices: [], quota: 0),
    );
    final usedInGroup = sideRecords
        .where(
          (r) =>
              !r.isOvertimePeriod &&
              group.periodIndices.contains(r.periodIndex),
        )
        .length;
    var remaining = (group.quota - usedInGroup).clamp(0, group.quota);

    final subCap = rule.lateGameSubCap;
    if (subCap != null &&
        periodIndex == subCap.periodIndex &&
        periodRemainingMs <= subCap.remainingMsThreshold) {
      final usedInWindow = sideRecords
          .where(
            (r) =>
                !r.isOvertimePeriod &&
                r.periodIndex == subCap.periodIndex &&
                r.periodRemainingMsAtTime <= subCap.remainingMsThreshold,
          )
          .length;
      final windowRemaining = (subCap.maxUsableWithinWindow - usedInWindow)
          .clamp(0, subCap.maxUsableWithinWindow);
      if (windowRemaining < remaining) remaining = windowRemaining;
    }

    return remaining;
  }
}
