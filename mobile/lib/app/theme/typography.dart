import 'package:flutter/widgets.dart';

/// Type scale for PlayTap. `scoreDisplay` is tabular so digits never shift
/// width mid-match — the same requirement the watch UI has, kept consistent
/// here so phone and watch never need two different type systems.
abstract final class PlayTapTypography {
  static const TextStyle scoreDisplay = TextStyle(
    fontSize: 64,
    height: 1.0,
    fontWeight: FontWeight.w800,
    letterSpacing: -1,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle headline = TextStyle(
    fontSize: 28,
    height: 1.15,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );

  static const TextStyle title = TextStyle(
    fontSize: 20,
    height: 1.2,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle body = TextStyle(
    fontSize: 15,
    height: 1.4,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle label = TextStyle(
    fontSize: 13,
    height: 1.3,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    height: 1.3,
    fontWeight: FontWeight.w400,
  );
}
