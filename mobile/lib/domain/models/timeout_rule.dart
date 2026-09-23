/// A set of regulation periods that share one timeout quota — e.g.
/// Basketball's halves (periods 0-1 share 2, periods 2-3 share 3) or
/// Futsal's individual periods (period 0 alone gets 1, period 1 alone
/// gets 1). See `TimeoutRule`.
class TimeoutQuotaGroup {
  const TimeoutQuotaGroup({required this.periodIndices, required this.quota});

  final List<int> periodIndices;
  final int quota;

  Map<String, dynamic> toJson() => {
    'periodIndices': periodIndices,
    'quota': quota,
  };

  factory TimeoutQuotaGroup.fromJson(Map<String, dynamic> json) =>
      TimeoutQuotaGroup(
        periodIndices: (json['periodIndices'] as List).cast<int>(),
        quota: json['quota'] as int,
      );

  @override
  bool operator ==(Object other) =>
      other is TimeoutQuotaGroup &&
      quota == other.quota &&
      periodIndices.length == other.periodIndices.length &&
      periodIndices.every((p) => other.periodIndices.contains(p));

  @override
  int get hashCode =>
      Object.hash(quota, Object.hashAllUnordered(periodIndices));
}

/// FIBA Article 18's "not more than 2 of the second half's 3 timeouts may
/// be used in the last 2 minutes of the fourth period": once the named
/// period's clock is at or below [remainingMsThreshold], no more than
/// [maxUsableWithinWindow] timeouts already taken *within that same
/// window* count toward what's still allowed there — a separate cap
/// layered on top of the group's overall quota, not a replacement for it.
/// See `TimeoutEngine.remainingForSide`.
class TimeoutLateGameSubCap {
  const TimeoutLateGameSubCap({
    required this.periodIndex,
    required this.remainingMsThreshold,
    required this.maxUsableWithinWindow,
  });

  final int periodIndex;
  final int remainingMsThreshold;
  final int maxUsableWithinWindow;

  Map<String, dynamic> toJson() => {
    'periodIndex': periodIndex,
    'remainingMsThreshold': remainingMsThreshold,
    'maxUsableWithinWindow': maxUsableWithinWindow,
  };

  factory TimeoutLateGameSubCap.fromJson(Map<String, dynamic> json) =>
      TimeoutLateGameSubCap(
        periodIndex: json['periodIndex'] as int,
        remainingMsThreshold: json['remainingMsThreshold'] as int,
        maxUsableWithinWindow: json['maxUsableWithinWindow'] as int,
      );

  @override
  bool operator ==(Object other) =>
      other is TimeoutLateGameSubCap &&
      periodIndex == other.periodIndex &&
      remainingMsThreshold == other.remainingMsThreshold &&
      maxUsableWithinWindow == other.maxUsableWithinWindow;

  @override
  int get hashCode =>
      Object.hash(periodIndex, remainingMsThreshold, maxUsableWithinWindow);
}

/// Timeout quota configuration — generic across every team-match sport
/// that has them (Basketball, Futsal; absent/`null` on `MatchRule.
/// timeoutRule` for Football in this phase). No sport identity anywhere:
/// Basketball's per-half grouping and Futsal's per-period grouping are
/// both just different [regulationGroups] data over the same shape.
class TimeoutRule {
  const TimeoutRule({
    required this.schemaVersion,
    required this.regulationGroups,
    required this.quotaPerOvertimePeriod,
    this.lateGameSubCap,
  });

  final int schemaVersion;

  /// Every regulation period index must appear in exactly one group.
  final List<TimeoutQuotaGroup> regulationGroups;

  /// Fresh quota granted for *each* overtime period (0 = no overtime
  /// timeouts at all — Futsal; 1 = Basketball's "1 per extra period").
  final int quotaPerOvertimePeriod;

  final TimeoutLateGameSubCap? lateGameSubCap;

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'regulationGroups': regulationGroups.map((g) => g.toJson()).toList(),
    'quotaPerOvertimePeriod': quotaPerOvertimePeriod,
    if (lateGameSubCap != null) 'lateGameSubCap': lateGameSubCap!.toJson(),
  };

  factory TimeoutRule.fromJson(Map<String, dynamic> json) => TimeoutRule(
    schemaVersion: json['schemaVersion'] as int,
    regulationGroups: (json['regulationGroups'] as List)
        .cast<Map<String, dynamic>>()
        .map(TimeoutQuotaGroup.fromJson)
        .toList(),
    quotaPerOvertimePeriod: json['quotaPerOvertimePeriod'] as int,
    lateGameSubCap: json['lateGameSubCap'] != null
        ? TimeoutLateGameSubCap.fromJson(
            (json['lateGameSubCap'] as Map).cast<String, dynamic>(),
          )
        : null,
  );
}
