import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/theme.dart';

class _ScorePreset {
  const _ScorePreset(this.label, {this.implemented = false});

  final String label;
  final bool implemented;
}

const List<_ScorePreset> _presets = [
  _ScorePreset('Score libre', implemented: true),
  _ScorePreset('Tennis'),
  _ScorePreset('Padel'),
  _ScorePreset('Tennis de table'),
  _ScorePreset('Badminton'),
  _ScorePreset('Pétanque'),
  _ScorePreset('Basketball'),
  _ScorePreset('Football / Futsal'),
  _ScorePreset('Volleyball'),
];

/// See docs/SPORT_RULES.md. Only "Score libre" is implemented in Phase
/// 1B.1 — the rest are listed (so PlayTap's multi-sport identity stays
/// visible) but honestly point to `/coming-soon`, never a fake screen.
class ScorePresetsPage extends StatelessWidget {
  const ScorePresetsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).playTapColors;

    return Scaffold(
      appBar: AppBar(title: const Text('Score')),
      body: ListView.separated(
        padding: const EdgeInsets.all(PlayTapSpacing.lg),
        itemCount: _presets.length,
        separatorBuilder: (_, _) => const SizedBox(height: PlayTapSpacing.sm),
        itemBuilder: (context, index) {
          final preset = _presets[index];
          return Material(
            color: colors.surface,
            borderRadius: PlayTapRadii.mdRadius,
            child: InkWell(
              borderRadius: PlayTapRadii.mdRadius,
              onTap: () => preset.implemented
                  ? context.push('/score/free/config')
                  : context.push('/coming-soon', extra: preset.label),
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
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    if (!preset.implemented)
                      Text(
                        'Bientôt',
                        style: PlayTapTypography.caption.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    Icon(Icons.chevron_right, color: colors.textSecondary),
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
