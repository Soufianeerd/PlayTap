/// Penalty-shootout configuration — identical shape reused by Football and
/// Futsal (IFAB Law 10 / FIFA Futsal Law 10 §3: both describe the same
/// alternating-kicks + sudden-death procedure). Absent (`null` on
/// `MatchRule.shootout`) means the sport never resolves a tie this way.
class ShootoutRule {
  const ShootoutRule({required this.kicksPerRound, required this.suddenDeath});

  /// Kicks each side takes in the initial round before sudden death — 5 for
  /// both Football and Futsal per the verified rules.
  final int kicksPerRound;

  /// Whether the shootout continues with one-kick-each sudden-death rounds
  /// if still level after [kicksPerRound] each.
  final bool suddenDeath;

  Map<String, dynamic> toJson() => {
    'kicksPerRound': kicksPerRound,
    'suddenDeath': suddenDeath,
  };

  factory ShootoutRule.fromJson(Map<String, dynamic> json) => ShootoutRule(
    kicksPerRound: json['kicksPerRound'] as int,
    suddenDeath: json['suddenDeath'] as bool,
  );

  @override
  bool operator ==(Object other) =>
      other is ShootoutRule &&
      kicksPerRound == other.kicksPerRound &&
      suddenDeath == other.suddenDeath;

  @override
  int get hashCode => Object.hash(kicksPerRound, suddenDeath);
}
