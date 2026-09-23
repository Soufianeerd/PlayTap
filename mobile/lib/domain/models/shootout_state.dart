/// One recorded kick — see `ShootoutEngine`/`ShootoutState`.
class ShootoutAttempt {
  const ShootoutAttempt({
    required this.eventId,
    required this.side,
    required this.scored,
  });

  final String eventId;
  final String side;
  final bool scored;

  @override
  bool operator ==(Object other) =>
      other is ShootoutAttempt &&
      eventId == other.eventId &&
      side == other.side &&
      scored == other.scored;

  @override
  int get hashCode => Object.hash(eventId, side, scored);
}

/// Output of `ShootoutEngine.replay` — deliberately separate from
/// `ScoreState`: a shootout's score is never added to the match score (see
/// `playtap-score-engine`'s composition note); the summary shows both,
/// e.g. "1–1, TAB 4–3".
class ShootoutState {
  const ShootoutState({
    required this.attempts,
    required this.scores,
    required this.nextKicker,
    required this.decided,
    this.winner,
  });

  /// Not-yet-undone attempts, in application order.
  final List<ShootoutAttempt> attempts;

  /// Goals scored per side — counts `scored: true` attempts only.
  final Map<String, int> scores;

  /// Side id to kick next, or null once [decided] is true.
  final String? nextKicker;

  final bool decided;

  final String? winner;

  @override
  bool operator ==(Object other) =>
      other is ShootoutState &&
      decided == other.decided &&
      winner == other.winner &&
      nextKicker == other.nextKicker &&
      _listEquals(attempts, other.attempts) &&
      _mapEquals(scores, other.scores);

  @override
  int get hashCode => Object.hash(
    decided,
    winner,
    nextKicker,
    Object.hashAll(attempts),
    Object.hashAllUnordered(
      scores.entries.map((e) => Object.hash(e.key, e.value)),
    ),
  );

  static bool _mapEquals(Map<String, int> a, Map<String, int> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }

  static bool _listEquals(List<ShootoutAttempt> a, List<ShootoutAttempt> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
