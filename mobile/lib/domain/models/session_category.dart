/// See CLAUDE.md — the four top-level activity categories.
enum SessionCategory {
  score,
  timer,
  training,
  custom;

  String toJson() => name.toUpperCase();

  static SessionCategory fromJson(String value) =>
      SessionCategory.values.firstWhere((c) => c.name.toUpperCase() == value);
}
