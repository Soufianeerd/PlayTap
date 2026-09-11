import 'package:flutter/material.dart';

/// Semantic color tokens. One accent, used sparingly, plus neutrals — no
/// gradients, no glass surfaces. PlayTap should read as sports hardware.
///
/// Extends [ThemeExtension] so screens can read it off [ThemeData] alongside
/// the standard [ColorScheme] (see the `playTapColors` getter in theme.dart).
class PlayTapColors extends ThemeExtension<PlayTapColors> {
  const PlayTapColors({
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.textPrimary,
    required this.textSecondary,
    required this.accent,
    required this.onAccent,
    required this.success,
    required this.danger,
    required this.border,
  });

  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color textPrimary;
  final Color textSecondary;
  final Color accent;
  final Color onAccent;
  final Color success;
  final Color danger;
  final Color border;

  @override
  PlayTapColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceVariant,
    Color? textPrimary,
    Color? textSecondary,
    Color? accent,
    Color? onAccent,
    Color? success,
    Color? danger,
    Color? border,
  }) {
    return PlayTapColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      success: success ?? this.success,
      danger: danger ?? this.danger,
      border: border ?? this.border,
    );
  }

  @override
  PlayTapColors lerp(ThemeExtension<PlayTapColors>? other, double t) {
    if (other is! PlayTapColors) return this;
    return PlayTapColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      success: Color.lerp(success, other.success, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      border: Color.lerp(border, other.border, t)!,
    );
  }

  static const PlayTapColors light = PlayTapColors(
    background: Color(0xFFF7F7F5),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFEDEDE9),
    textPrimary: Color(0xFF14150F),
    textSecondary: Color(0xFF5B5D54),
    accent: Color(0xFF2E7D32),
    onAccent: Color(0xFFFFFFFF),
    success: Color(0xFF2E7D32),
    danger: Color(0xFFC1121F),
    border: Color(0xFFDCDCD5),
  );

  static const PlayTapColors dark = PlayTapColors(
    background: Color(0xFF0B0C0A),
    surface: Color(0xFF16170F),
    surfaceVariant: Color(0xFF212317),
    textPrimary: Color(0xFFF5F6F0),
    textSecondary: Color(0xFFA8AA9E),
    accent: Color(0xFFC6FF3D),
    onAccent: Color(0xFF0B0C0A),
    success: Color(0xFFC6FF3D),
    danger: Color(0xFFFF5449),
    border: Color(0xFF2B2D20),
  );
}
