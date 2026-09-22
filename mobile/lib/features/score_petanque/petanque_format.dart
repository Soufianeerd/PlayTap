/// How many players sit on each scoring side, and how many points a mène
/// may legally award — a purely presentational/config concept (see
/// `playtap-sports-rules`: "joueurs != sides de scoring"). The Score
/// Engine never sees this enum directly: whatever the format, a Pétanque
/// session is always 2 scoring sides (`team_a`/`team_b`); [playersPerSide]
/// only decides how many player-name fields the config page shows per
/// side, and [allowedIncrements] is what actually gets persisted into the
/// session's `TeamScoreRule` (see `petanque_actions.dart`).
///
/// FIPJP Official Rules for the Sport of Pétanque, Article 1 — boules per
/// player: triplette 2, doublette 3, tête-à-tête (individuel) 3. A side's
/// maximum boules per mène is players × boules-per-player: tête-à-tête
/// 1×3=3, doublette 2×3=6, triplette 3×2=6 — so tête-à-tête can never
/// legally score more than 3 points in one mène, unlike doublette/
/// triplette (see docs/SPORT_RULES.md for the full source citation).
enum PetanqueFormat {
  headToHead,
  doublette,
  triplette;

  int get playersPerSide => switch (this) {
    PetanqueFormat.headToHead => 1,
    PetanqueFormat.doublette => 2,
    PetanqueFormat.triplette => 3,
  };

  List<int> get allowedIncrements => switch (this) {
    PetanqueFormat.headToHead => const [1, 2, 3],
    PetanqueFormat.doublette => const [1, 2, 3, 4, 5, 6],
    PetanqueFormat.triplette => const [1, 2, 3, 4, 5, 6],
  };

  /// Reconstructs the format from what's actually persisted (a side's
  /// player roster length + the session's `TeamScoreRule.allowedIncrements`)
  /// — never from transient config-screen state, which doesn't survive
  /// recovery. `playersPerSide` alone already disambiguates doublette from
  /// triplette; `allowedIncrements` is only needed to tell tête-à-tête
  /// (max +3) apart from a 1-player side under some other, hypothetical
  /// rule — see the composition note on `ScoreRule` in
  /// `domain/models/score_rule.dart`. Returns null for a roster/increment
  /// combination that doesn't match any known format (should never happen
  /// for a session this app created, but recovery must never guess).
  static PetanqueFormat? fromPersisted({
    required int playersPerSide,
    required List<int> allowedIncrements,
  }) {
    for (final format in PetanqueFormat.values) {
      if (format.playersPerSide == playersPerSide &&
          _sameIncrements(format.allowedIncrements, allowedIncrements)) {
        return format;
      }
    }
    return null;
  }

  static bool _sameIncrements(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
