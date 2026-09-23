/// The one bit of config `MatchEngine.decideNextPhase` needs beyond
/// `overtime`/`shootout` presence to fully resolve "is the match over and
/// how" without ever branching on a sport's identity — see
/// `MatchRule`/`docs/DATA_MODEL.md`.
class MatchEndRule {
  const MatchEndRule({required this.drawAllowed});

  /// Whether the match may end level once overtime/shootout (if any) are
  /// exhausted or absent. False for Basketball (FIBA: always decided) and
  /// for knockout Football/Futsal (shootout always resolves it); true for
  /// a league Football/Futsal match with no shootout configured.
  final bool drawAllowed;

  Map<String, dynamic> toJson() => {'drawAllowed': drawAllowed};

  factory MatchEndRule.fromJson(Map<String, dynamic> json) =>
      MatchEndRule(drawAllowed: json['drawAllowed'] as bool);

  @override
  bool operator ==(Object other) =>
      other is MatchEndRule && drawAllowed == other.drawAllowed;

  @override
  int get hashCode => drawAllowed.hashCode;
}
