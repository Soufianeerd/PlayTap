import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/theme.dart';
import '../../domain/models/scoring_side.dart';
import '../../domain/models/shootout_state.dart';
import '../../l10n/app_localizations.dart';

/// Shared shootout UI for Football and Futsal — never shows or affects
/// the match score (see `ShootoutEngine`'s composition note): this is a
/// fully separate mini-match, scored/miss buttons only, one per kicker.
class ShootoutPanel extends StatelessWidget {
  const ShootoutPanel({
    super.key,
    required this.sides,
    required this.shootoutState,
    required this.onAttempt,
  });

  final List<ScoringSide> sides;
  final ShootoutState shootoutState;
  final void Function(String sideId, {required bool scored}) onAttempt;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).playTapColors;
    final l10n = AppLocalizations.of(context)!;
    final nextKicker = shootoutState.nextKicker;
    final nextKickerName = nextKicker == null
        ? null
        : sides.firstWhere((s) => s.id == nextKicker).name;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: PlayTapSpacing.sm),
          child: Text(
            l10n.shootoutLabel,
            style: PlayTapTypography.title.copyWith(color: colors.foreground),
          ),
        ),
        Expanded(
          child: Row(
            children: [
              for (final side in sides)
                Expanded(
                  child: _ShootoutSideColumn(
                    name: side.name,
                    score: shootoutState.scores[side.id] ?? 0,
                    isNextKicker: side.id == nextKicker,
                  ),
                ),
            ],
          ),
        ),
        if (nextKickerName != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: PlayTapSpacing.sm),
            child: Text(
              l10n.shootoutNextKickerLabel(nextKickerName),
              style: PlayTapTypography.body.copyWith(color: colors.muted),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              PlayTapSpacing.lg,
              0,
              PlayTapSpacing.lg,
              PlayTapSpacing.lg,
            ),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: colors.danger,
                      ),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        onAttempt(nextKicker!, scored: false);
                      },
                      child: Text(l10n.shootoutMissButton),
                    ),
                  ),
                ),
                const SizedBox(width: PlayTapSpacing.md),
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: FilledButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        onAttempt(nextKicker!, scored: true);
                      },
                      child: Text(l10n.shootoutScoreButton),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _ShootoutSideColumn extends StatelessWidget {
  const _ShootoutSideColumn({
    required this.name,
    required this.score,
    required this.isNextKicker,
  });

  final String name;
  final int score;
  final bool isNextKicker;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).playTapColors;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          name,
          textAlign: TextAlign.center,
          style: PlayTapTypography.title.copyWith(
            color: isNextKicker ? colors.primary : colors.foreground,
          ),
        ),
        const SizedBox(height: PlayTapSpacing.sm),
        Text(
          '$score',
          style: PlayTapTypography.scoreDisplay.copyWith(
            color: colors.foreground,
            fontSize: 64,
          ),
        ),
      ],
    );
  }
}
