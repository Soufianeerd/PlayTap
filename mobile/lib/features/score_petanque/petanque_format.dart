/// How many players sit on each scoring side — a purely presentational/
/// config concept (see `playtap-sports-rules`: "joueurs != sides de
/// scoring"). The Score Engine never sees this: whatever the format, a
/// Pétanque session is always 2 scoring sides (`team_a`/`team_b`); this
/// only decides how many player-name fields the config page shows per side.
enum PetanqueFormat {
  headToHead,
  doublette,
  triplette;

  int get playersPerSide => switch (this) {
    PetanqueFormat.headToHead => 1,
    PetanqueFormat.doublette => 2,
    PetanqueFormat.triplette => 3,
  };
}
