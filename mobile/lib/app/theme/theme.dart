import 'package:flutter/material.dart';

import 'colors.dart';
import 'radii.dart';
import 'typography.dart';

export 'colors.dart';
export 'radii.dart';
export 'spacing.dart';
export 'typography.dart';

/// Builds [ThemeData] from the PlayTap design tokens. Screens should read
/// tokens (spacing/typography/radii/colors) rather than hardcoding values,
/// so a future Figma-driven pass only has to change this file.
abstract final class PlayTapTheme {
  static ThemeData light() => _build(PlayTapColors.light, Brightness.light);

  static ThemeData dark() => _build(PlayTapColors.dark, Brightness.dark);

  static ThemeData _build(PlayTapColors colors, Brightness brightness) {
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: colors.accent,
      onPrimary: colors.onAccent,
      secondary: colors.accent,
      onSecondary: colors.onAccent,
      error: colors.danger,
      onError: colors.onAccent,
      surface: colors.surface,
      onSurface: colors.textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colors.background,
      canvasColor: colors.background,
      dividerColor: colors.border,
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: PlayTapTypography.title.copyWith(
          color: colors.textPrimary,
        ),
      ),
      textTheme: TextTheme(
        displayLarge: PlayTapTypography.scoreDisplay.copyWith(
          color: colors.textPrimary,
        ),
        headlineMedium: PlayTapTypography.headline.copyWith(
          color: colors.textPrimary,
        ),
        titleMedium: PlayTapTypography.title.copyWith(
          color: colors.textPrimary,
        ),
        bodyMedium: PlayTapTypography.body.copyWith(color: colors.textPrimary),
        labelLarge: PlayTapTypography.label.copyWith(color: colors.textPrimary),
        bodySmall: PlayTapTypography.caption.copyWith(
          color: colors.textSecondary,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.surface,
        indicatorColor: colors.accent.withValues(alpha: 0.18),
        labelTextStyle: WidgetStatePropertyAll(
          PlayTapTypography.caption.copyWith(color: colors.textPrimary),
        ),
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: PlayTapRadii.mdRadius,
          side: BorderSide(color: colors.border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colors.accent,
          foregroundColor: colors.onAccent,
          shape: RoundedRectangleBorder(borderRadius: PlayTapRadii.smRadius),
        ),
      ),
      extensions: [colors],
    );
  }
}

extension PlayTapColorsExtension on ThemeData {
  PlayTapColors get playTapColors =>
      extension<PlayTapColors>() ?? PlayTapColors.dark;
}
