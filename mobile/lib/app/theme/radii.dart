import 'package:flutter/widgets.dart';

/// Corner radius scale. Deliberately small and squared-off — PlayTap should
/// read as sporty hardware, not a soft consumer SaaS dashboard.
abstract final class PlayTapRadii {
  static const double sm = 6;
  static const double md = 10;
  static const double lg = 16;

  static const BorderRadius smRadius = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdRadius = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgRadius = BorderRadius.all(Radius.circular(lg));
}
