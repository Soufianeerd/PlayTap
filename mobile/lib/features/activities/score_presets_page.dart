import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/theme.dart';
import '../../l10n/app_localizations.dart';

class _ScorePreset {
  const _ScorePreset(this.label, this.route);

  final String label;
  final String route;
}

/// PlayTap 1.0.0 scope was Score Libre only; Pétanque was the first full
/// Sport Pack built on the generic Score Engine (TARGET_SCORE + TEAM_
/// SCORE). Basketball/Football/Futsal (Phase Sports 2) are the first Sport
/// Packs built on the generic Match Engine (periods/clock/overtime/
/// shootout, composed with the same TEAM_SCORE — see `MatchRule`). Tennis
/// (Racket Core Phase 1) is the first Sport Pack built on the generic
/// Racket Engine (point/game/set/match, tie-break, service rotation — see
/// `RacketMatchRule`) — Padel/Table Tennis/Badminton return once their own
/// V1 config screens ship, not before (CLAUDE.md scope note).
List<_ScorePreset> _presetsOf(AppLocalizations l10n) => [
  _ScorePreset(l10n.presetFreeScore, '/score/free/config'),
  _ScorePreset(l10n.presetTennis, '/score/tennis/config'),
  _ScorePreset(l10n.presetPetanque, '/score/petanque/config'),
  _ScorePreset(l10n.presetBasketball, '/score/basketball/config'),
  _ScorePreset(l10n.presetFootball, '/score/football/config'),
  _ScorePreset(l10n.presetFutsal, '/score/futsal/config'),
];

class ScorePresetsPage extends StatelessWidget {
  const ScorePresetsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).playTapColors;
    final l10n = AppLocalizations.of(context)!;
    final presets = _presetsOf(l10n);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.scoreSectionTitle)),
      body: ListView.separated(
        padding: const EdgeInsets.all(PlayTapSpacing.lg),
        itemCount: presets.length,
        separatorBuilder: (_, _) => const SizedBox(height: PlayTapSpacing.sm),
        itemBuilder: (context, index) {
          final preset = presets[index];
          return Material(
            color: colors.surface,
            borderRadius: PlayTapRadii.mdRadius,
            child: InkWell(
              borderRadius: PlayTapRadii.mdRadius,
              onTap: () => context.push(preset.route),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: PlayTapSpacing.lg,
                  vertical: PlayTapSpacing.md,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        preset.label,
                        style: PlayTapTypography.body.copyWith(
                          color: colors.foreground,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right, color: colors.muted),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
