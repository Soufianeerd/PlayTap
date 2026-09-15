import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/theme.dart';

class _ScorePreset {
  const _ScorePreset(this.label);

  final String label;
}

/// PlayTap 1.0.0 scope is Score Libre only — the other sports in
/// docs/SPORT_RULES.md return once the rest of the generic Score Engine
/// (TARGET_SCORE, SETS, BEST_OF, WIN_BY) ships, not before.
const List<_ScorePreset> _presets = [_ScorePreset('Score libre')];

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
              onTap: () => context.push('/score/free/config'),
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
