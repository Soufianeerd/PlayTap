/// Simple/Double — a purely presentational/config concept (see
/// `playtap-sports-rules`: "joueurs != sides de scoring"). A Tennis
/// session is always 2 scoring sides (`side_a`/`side_b`, see
/// `tennis_actions.dart`); [playersPerSide] only decides how many
/// player-name fields the config page shows per side and how the service
/// order is built (2 slots singles, 4 slots doubles — see
/// `domain/models/racket_rule.dart`'s `ServiceRule`).
enum TennisMatchType {
  singles,
  doubles;

  int get playersPerSide => switch (this) {
    TennisMatchType.singles => 1,
    TennisMatchType.doubles => 2,
  };

  /// Reconstructs the match type from what's actually persisted (a side's
  /// player roster length) — never from transient config-screen state,
  /// mirroring `PetanqueFormat.fromPersisted`.
  static TennisMatchType fromPlayersPerSide(int playersPerSide) =>
      switch (playersPerSide) {
        1 => TennisMatchType.singles,
        2 => TennisMatchType.doubles,
        _ => throw ArgumentError.value(
          playersPerSide,
          'playersPerSide',
          'Tennis sides always have 1 or 2 players',
        ),
      };
}

/// What the deciding (last possible) set is played as — the config-screen
/// facing choice that resolves to a `DecidingSetFormat` (see
/// `domain/models/racket_rule.dart`). "Advantage set" (no tie-break at
/// all) is deliberately not offered here — CLAUDE.md brief section 6/10:
/// the tie-break set is the ITF standard method, and the engine already
/// supports advantage sets structurally (`SetRule.tieBreak == null`) for a
/// future ruleset/config without needing a third V1 UI option.
enum TennisDecidingSetChoice { tieBreakSet, matchTieBreak10 }
