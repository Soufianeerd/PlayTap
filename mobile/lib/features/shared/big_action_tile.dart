import 'package:flutter/material.dart';

import '../../app/theme/theme.dart';

/// A full-bleed, large tappable action row — the whole surface is the tap
/// target, not a small button inside a card. Used for the handful of
/// primary choices on Home, the Activités tab, and the Timer landing page:
/// PlayTap 1.0.0 never shows more than a few of these at once, so each one
/// gets real screen space instead of competing in a dense grid.
///
/// Defaults to a neutral surface; pass [backgroundColor]/[foregroundColor]
/// (always one of the 4 brand colors — see the release brand brief) to make
/// a tile a strong editorial block instead. Brand contrast is fixed:
/// violet always takes white content, lime always takes black content —
/// callers should pass one of those two pairs, never mix them.
class BigActionTile extends StatelessWidget {
  const BigActionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.alternate = false,
    this.backgroundColor,
    this.foregroundColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// Alternates surface tint between stacked neutral tiles so adjacent ones
  /// read as distinct tap zones without a border. Ignored when
  /// [backgroundColor] is set.
  final bool alternate;

  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).playTapColors;
    final background =
        backgroundColor ?? (alternate ? colors.surfaceVariant : colors.surface);
    final foreground = foregroundColor ?? colors.foreground;
    final onBrand = backgroundColor != null;

    return Material(
      color: background,
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
              Icon(icon, size: 36, color: foreground),
              const SizedBox(width: PlayTapSpacing.lg),
              Expanded(
                child: Text(
                  label,
                  style: PlayTapTypography.headline.copyWith(
                    color: foreground,
                    fontSize: 22,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: onBrand ? foreground : colors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
