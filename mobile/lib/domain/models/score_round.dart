import 'package:meta/meta.dart';

/// One completed, not-undone `POINT_SCORED` event, in application order —
/// see `ScoreState.rounds`. For Pétanque a "mène" *is* one `POINT_SCORED`
/// event (exactly one side scores 1-6 points per round — see
/// `playtap-sports-rules`), so no separate ROUND_COMPLETED event type or
/// round-number metadata is needed: the round number is just this entry's
/// 1-based position in the list (see docs/CONFORMANCE.md decision note in
/// `ScoreEngine`).
@immutable
class ScoreRound {
  const ScoreRound({required this.sideId, required this.amount});

  final String sideId;
  final int amount;

  Map<String, dynamic> toJson() => {'side': sideId, 'amount': amount};

  @override
  bool operator ==(Object other) =>
      other is ScoreRound && sideId == other.sideId && amount == other.amount;

  @override
  int get hashCode => Object.hash(sideId, amount);
}
