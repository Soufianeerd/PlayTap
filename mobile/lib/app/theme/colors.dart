import 'package:flutter/material.dart';

/// PlayTap's brand palette and semantic color roles. Exactly 4 brand
/// colors (black/white/violet/lime, see the release brand brief) —
/// everything else (background/surface/border/muted) is a low-alpha
/// blend of black or white, never a separate hand-picked gray.
///
/// Extends [ThemeExtension] so screens can read it off [ThemeData] alongside
/// the standard [ColorScheme] (see the `playTapColors` getter in theme.dart).
class PlayTapColors extends ThemeExtension<PlayTapColors> {
  const PlayTapColors({
    required this.black,
    required this.white,
    required this.violet,
    required this.lime,
    required this.background,
    required this.foreground,
    required this.surface,
    required this.surfaceVariant,
    required this.primary,
    required this.onPrimary,
    required this.accent,
    required this.onAccent,
    required this.border,
    required this.muted,
    required this.danger,
  });

  // Raw brand colors — reach for these only when a semantic role below
  // doesn't fit; prefer the semantic roles everywhere else.
  final Color black;
  final Color white;
  final Color violet;
  final Color lime;

  // Semantic roles. `primary`/`onPrimary`/`accent`/`onAccent` are brand
  // colors fixed in both light and dark (violet always takes white text,
  // lime always takes black text — see the release brand brief's contrast
  // rules); only background/surface/border/muted flip with brightness.
  final Color background;
  final Color foreground;
  final Color surface;
  final Color surfaceVariant;
  final Color primary;
  final Color onPrimary;
  final Color accent;
  final Color onAccent;
  final Color border;
  final Color muted;

  /// Error/destructive state. Deliberately NOT a brand color (see the
  /// release brand brief) — a plain system red, used only where something
  /// has actually gone wrong.
  final Color danger;

  @override
  PlayTapColors copyWith({
    Color? black,
    Color? white,
    Color? violet,
    Color? lime,
    Color? background,
    Color? foreground,
    Color? surface,
    Color? surfaceVariant,
    Color? primary,
    Color? onPrimary,
    Color? accent,
    Color? onAccent,
    Color? border,
    Color? muted,
    Color? danger,
  }) {
    return PlayTapColors(
      black: black ?? this.black,
      white: white ?? this.white,
      violet: violet ?? this.violet,
      lime: lime ?? this.lime,
      background: background ?? this.background,
      foreground: foreground ?? this.foreground,
      surface: surface ?? this.surface,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      border: border ?? this.border,
      muted: muted ?? this.muted,
      danger: danger ?? this.danger,
    );
  }

  @override
  PlayTapColors lerp(ThemeExtension<PlayTapColors>? other, double t) {
    if (other is! PlayTapColors) return this;
    return PlayTapColors(
      black: Color.lerp(black, other.black, t)!,
      white: Color.lerp(white, other.white, t)!,
      violet: Color.lerp(violet, other.violet, t)!,
      lime: Color.lerp(lime, other.lime, t)!,
      background: Color.lerp(background, other.background, t)!,
      foreground: Color.lerp(foreground, other.foreground, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      border: Color.lerp(border, other.border, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
    );
  }

  static const Color _black = Color(0xFF000000);
  static const Color _white = Color(0xFFFFFFFF);
  static const Color _violet = Color(0xFF7D39EB);
  static const Color _lime = Color(0xFFC6FF33);

  static const PlayTapColors light = PlayTapColors(
    black: _black,
    white: _white,
    violet: _violet,
    lime: _lime,
    background: _white,
    foreground: _black,
    surface: _white,
    surfaceVariant: Color(0x0A000000), // black @ 4%
    primary: _violet,
    onPrimary: _white,
    accent: _lime,
    onAccent: _black,
    border: Color(0x1F000000), // black @ 12%
    muted: Color(0x99000000), // black @ 60%
    danger: Color(0xFFC1121F),
  );

  static const PlayTapColors dark = PlayTapColors(
    black: _black,
    white: _white,
    violet: _violet,
    lime: _lime,
    background: _black,
    foreground: _white,
    surface: _black,
    surfaceVariant: Color(0x0FFFFFFF), // white @ 6%
    primary: _violet,
    onPrimary: _white,
    accent: _lime,
    onAccent: _black,
    border: Color(0x24FFFFFF), // white @ 14%
    muted: Color(0x99FFFFFF), // white @ 60%
    danger: Color(0xFFFF6B60),
  );
}
