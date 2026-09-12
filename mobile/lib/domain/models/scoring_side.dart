/// A named participant/team on one scoring side of a session. This is
/// presentation/config data — the engine itself only ever sees the abstract
/// side `id` (see ScoreRule), never a display name.
class ScoringSide {
  const ScoringSide({required this.id, required this.name, this.colorToken});

  final String id;
  final String name;

  /// Optional semantic color token name (e.g. "accent"); resolved to an
  /// actual color by the theme layer, never a raw color here.
  final String? colorToken;

  ScoringSide copyWith({String? name}) =>
      ScoringSide(id: id, name: name ?? this.name, colorToken: colorToken);

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (colorToken != null) 'colorToken': colorToken,
  };

  factory ScoringSide.fromJson(Map<String, dynamic> json) => ScoringSide(
    id: json['id'] as String,
    name: json['name'] as String,
    colorToken: json['colorToken'] as String?,
  );
}
