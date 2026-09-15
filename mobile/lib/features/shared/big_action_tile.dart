import 'package:flutter/material.dart';

import '../../app/theme/theme.dart';

/// A full-bleed, large tappable action row — the whole surface is the tap
/// target, not a small button inside a card. Used for the handful of
/// primary choices on Home, the Activités tab, and the Timer landing page:
/// PlayTap 1.0.0 never shows more than a few of these at once, so each one
/// gets real screen space instead of competing in a dense grid.
class BigActionTile extends StatelessWidget {
  const BigActionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.alternate = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// Alternates surface tint between stacked tiles so adjacent ones read as
  /// distinct tap zones without a border.
  final bool alternate;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).playTapColors;

    return Material(
      color: alternate ? colors.surfaceVariant : colors.surface,
      borderRadius: PlayTapRadii.lgRadius,
      child: InkWell(
        borderRadius: PlayTapRadii.lgRadius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: PlayTapSpacing.xl,
            vertical: PlayTapSpacing.lg,
          ),
          child: Row(
            children: [
              Icon(icon, size: 36, color: colors.accent),
              const SizedBox(width: PlayTapSpacing.lg),
              Expanded(
                child: Text(
                  label,
                  style: PlayTapTypography.headline.copyWith(
                    color: colors.textPrimary,
                    fontSize: 22,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: colors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
