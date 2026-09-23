import '../models/racket_rule.dart';

/// How to display one side's current-game point count — CLAUDE.md brief
/// section 4/21: the engine/state never stores `"15"/"30"/"40"` strings
/// (see `RacketMatchState.currentGamePoints`, always raw integers); this is
/// the one place that derives a label from them, and deliberately doesn't
/// bake in a String so the UI layer can localize [deuce]/[advantage]
/// (only those two need translation — 0/15/30/40 are numerals, locale-
/// invariant, see docs/LOCALIZATION.md).
enum RacketPointLabelKind { numeric, deuce, advantage }

class RacketPointLabel {
  const RacketPointLabel.numeric(this.value)
    : kind = RacketPointLabelKind.numeric;
  const RacketPointLabel.deuce()
    : kind = RacketPointLabelKind.deuce,
      value = null;
  const RacketPointLabel.advantage()
    : kind = RacketPointLabelKind.advantage,
      value = null;

  final RacketPointLabelKind kind;

  /// "0"/"15"/"30"/"40" when [kind] is [RacketPointLabelKind.numeric], null
  /// otherwise.
  final String? value;
}

/// Pure label derivation for `RacketMatchState.currentGamePoints` — see
/// [RacketPointLabel]. Not part of `RacketEngine` itself: this is a
/// presentation-facing projection over the engine's raw state, not a
/// replay concern.
abstract final class RacketLabels {
  static const _numerals = ['0', '15', '30', '40'];

  /// Both sides' current point labels at once — deuce/advantage are
  /// inherently relative (one side's advantage is the other's "40"), so
  /// computing them independently per side would risk drifting out of
  /// sync; this is the single source for both.
  static Map<String, RacketPointLabel> gamePointLabels({
    required Map<String, int> points,
    required List<String> sideIds,
    required AdvantageMode mode,
  }) {
    final sideA = sideIds[0];
    final sideB = sideIds[1];
    final pointsA = points[sideA] ?? 0;
    final pointsB = points[sideB] ?? 0;

    RacketPointLabel labelFor(int mine, int theirs) {
      if (mine < 3 || theirs < 3) {
        return RacketPointLabel.numeric(_numerals[mine.clamp(0, 3)]);
      }
      if (mode == AdvantageMode.noAd) {
        // No-Ad never shows an advantage state — 40-40 is the "deciding
        // point", the very next point wins outright (CLAUDE.md section 5).
        return const RacketPointLabel.deuce();
      }
      final diff = mine - theirs;
      if (diff == 0) return const RacketPointLabel.deuce();
      return diff > 0
          ? const RacketPointLabel.advantage()
          : const RacketPointLabel.numeric('40');
    }

    return {
      sideA: labelFor(pointsA, pointsB),
      sideB: labelFor(pointsB, pointsA),
    };
  }
}
