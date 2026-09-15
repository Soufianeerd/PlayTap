import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  /// The status bar / Android nav bar style for the current theme — see the
  /// release brand brief section 7: system chrome must always follow
  /// light/dark, never leave illegible icons on a bright or dark bar.
  /// Screens with an [AppBar] get this for free via [AppBarTheme]; screens
  /// without one (Home, the root tab shell) should wrap their [Scaffold] in
  /// `AnnotatedRegion<SystemUiOverlayStyle>(value: PlayTapTheme.overlayStyleOf(context), ...)`.
  static SystemUiOverlayStyle overlayStyleOf(BuildContext context) {
    final theme = Theme.of(context);
    return _overlayStyleFor(theme.playTapColors, theme.brightness);
  }

  static SystemUiOverlayStyle _overlayStyleFor(
    PlayTapColors colors,
    Brightness brightness,
  ) {
    final iconBrightness = brightness == Brightness.light
        ? Brightness.dark
        : Brightness.light;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: iconBrightness,
      statusBarBrightness: brightness,
      systemNavigationBarColor: colors.background,
      systemNavigationBarIconBrightness: iconBrightness,
      systemNavigationBarDividerColor: Colors.transparent,
    );
  }

  static ThemeData _build(PlayTapColors colors, Brightness brightness) {
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: colors.primary,
      onPrimary: colors.onPrimary,
      secondary: colors.accent,
      onSecondary: colors.onAccent,
      error: colors.danger,
      onError: colors.background,
      surface: colors.surface,
      onSurface: colors.foreground,
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
        foregroundColor: colors.foreground,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: _overlayStyleFor(colors, brightness),
        titleTextStyle: PlayTapTypography.title.copyWith(
          color: colors.foreground,
        ),
      ),
      textTheme: TextTheme(
        displayLarge: PlayTapTypography.scoreDisplay.copyWith(
          color: colors.foreground,
        ),
        headlineMedium: PlayTapTypography.headline.copyWith(
          color: colors.foreground,
        ),
        titleMedium: PlayTapTypography.title.copyWith(color: colors.foreground),
        bodyMedium: PlayTapTypography.body.copyWith(color: colors.foreground),
        labelLarge: PlayTapTypography.label.copyWith(color: colors.foreground),
        bodySmall: PlayTapTypography.caption.copyWith(color: colors.muted),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.background,
        indicatorColor: Colors.transparent,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? colors.primary
                : colors.muted,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => PlayTapTypography.caption.copyWith(
            color: states.contains(WidgetState.selected)
                ? colors.primary
                : colors.muted,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w400,
          ),
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
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
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
