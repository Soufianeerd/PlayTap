/// Output of `TeamFoulEngine.replay` — the current bracket's foul count
/// per side (reset at each regulation `PERIOD_STARTED`, carried forward
/// into overtime — see `TeamFoulRule`).
class TeamFoulState {
  const TeamFoulState({
    required this.countsBySide,
    required this.bonusThreshold,
  });

  final Map<String, int> countsBySide;

  /// Carried alongside the counts so the UI never needs the rule object
  /// separately just to know when to show the bonus indicator.
  final int bonusThreshold;

  bool isInBonus(String sideId) =>
      (countsBySide[sideId] ?? 0) >= bonusThreshold;

  @override
  bool operator ==(Object other) =>
      other is TeamFoulState &&
      bonusThreshold == other.bonusThreshold &&
      _mapEquals(countsBySide, other.countsBySide);

  @override
  int get hashCode => Object.hash(
    bonusThreshold,
    Object.hashAllUnordered(
      countsBySide.entries.map((e) => Object.hash(e.key, e.value)),
    ),
  );

  static bool _mapEquals(Map<String, int> a, Map<String, int> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }
}
