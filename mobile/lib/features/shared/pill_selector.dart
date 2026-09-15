import 'package:flutter/material.dart';

import '../../app/theme/theme.dart';

/// A row of large, legible choice pills — replaces Material's
/// `SegmentedButton`/`ChoiceChip` wherever they read as generic template UI
/// (see the release brand brief sections 11 and 18). Selected = violet
/// fill + white text; unselected = neutral surface + foreground text.
class PillSelector<T> extends StatelessWidget {
  const PillSelector({
    super.key,
    required this.options,
    required this.labelBuilder,
    required this.value,
    required this.onChanged,
  });

  final List<T> options;
  final String Function(T) labelBuilder;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).playTapColors;

    return Row(
      children: [
        for (final option in options) ...[
          if (option != options.first) const SizedBox(width: PlayTapSpacing.sm),
          Expanded(
            child: _Pill(
              label: labelBuilder(option),
              selected: option == value,
              onTap: () => onChanged(option),
              colors: colors,
            ),
          ),
        ],
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.colors,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final PlayTapColors colors;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? colors.primary : colors.surfaceVariant,
      borderRadius: PlayTapRadii.mdRadius,
      child: InkWell(
        borderRadius: PlayTapRadii.mdRadius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: PlayTapSpacing.md),
          child: Center(
            child: Text(
              label,
              style: PlayTapTypography.title.copyWith(
                color: selected ? colors.onPrimary : colors.foreground,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
