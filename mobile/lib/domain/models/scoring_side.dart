/// A named participant/team on one scoring side of a session. This is
/// presentation/config data — the engine itself only ever sees the abstract
/// side `id` (see ScoreRule), never a display name.
class ScoringSide {
  const ScoringSide({
    required this.id,
    required this.name,
    this.colorToken,
    this.players,
  });

  final String id;
  final String name;

  /// Optional semantic color token name (e.g. "accent"); resolved to an
  /// actual color by the theme layer, never a raw color here.
  final String? colorToken;

  /// Optional individual player names within this scoring side — a side is
  /// a `Team` of `Competitor`s (see `playtap-score-engine`: "un side de
  /// scoring peut contenir plusieurs joueurs", e.g. Pétanque doublette =
  /// 2 players in 1 side, triplette = 3, tête-à-tête = 1 — every Pétanque
  /// format persists its full roster here, even tête-à-tête's single
  /// player, so the player's name is never silently dropped). Null/omitted
  /// only for sides with no separate player roster at all (Score Libre).
  final List<String>? players;

  ScoringSide copyWith({String? name}) => ScoringSide(
    id: id,
    name: name ?? this.name,
    colorToken: colorToken,
    players: players,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (colorToken != null) 'colorToken': colorToken,
    if (players != null) 'players': players,
  };

  factory ScoringSide.fromJson(Map<String, dynamic> json) => ScoringSide(
    id: json['id'] as String,
    name: json['name'] as String,
    colorToken: json['colorToken'] as String?,
    players: (json['players'] as List?)?.cast<String>(),
  );
}
