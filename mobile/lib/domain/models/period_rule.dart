/// One regulation period's duration — see `playtap-score-engine` /
/// `MatchRule` composition (docs/DATA_MODEL.md). Deliberately carries no
/// label ("Quarter", "Half"): what a period is called is presentation,
/// resolved by the UI from `periods.length` + the persisted `rulesetId` —
/// the same separation `ScoreRule` keeps from `ScoringSide`'s display name.
/// A list (not a single scalar) keeps the shape ready for a sport with
/// asymmetric periods, even though every sport in this phase is uniform.
class PeriodRule {
  const PeriodRule({required this.index, required this.durationMs});

  /// Zero-based ordinal among regulation periods (0 = first quarter/half).
  final int index;

  final int durationMs;

  Map<String, dynamic> toJson() => {'index': index, 'durationMs': durationMs};

  factory PeriodRule.fromJson(Map<String, dynamic> json) => PeriodRule(
    index: json['index'] as int,
    durationMs: json['durationMs'] as int,
  );

  @override
  bool operator ==(Object other) =>
      other is PeriodRule &&
      index == other.index &&
      durationMs == other.durationMs;

  @override
  int get hashCode => Object.hash(index, durationMs);
}
