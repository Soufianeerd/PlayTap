import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/theme.dart';
import '../../l10n/app_localizations.dart';
import 'big_action_tile.dart';

class ActivityCategory {
  const ActivityCategory(this.label, this.icon, this.route);

  final String label;
  final IconData icon;
  final String route;
}

/// PlayTap 1.0.0 scope is Score Libre + Timer only (see
/// docs/ROADMAP.md — Training/Custom return with the Interval/Workout
/// Engines in a later release, not before). "Score" skips straight to the
/// Score Libre config — with a single implemented preset, a middle list
/// screen would only add a tap for nothing (see ScorePresetsPage, kept as
/// unlinked infrastructure for when more sports return).
///
/// `Icons.exposure_plus_1` (not a racket/ball) for Score: Score Libre
/// scores anything, and Score Libre is the only rule PlayTap 1.0.0's
/// ScoreEngine actually implements — a sport-specific icon would promise a
/// preset that doesn't exist yet (see the release brand brief section 9).
List<ActivityCategory> activityCategoriesOf(AppLocalizations l10n) => [
  ActivityCategory(
    l10n.categoryScore,
    Icons.exposure_plus_1,
    '/score/free/config',
  ),
  ActivityCategory(
    l10n.categoryTimer,
    Icons.timer_outlined,
    '/activities/timer',
  ),
];

/// The 2-category picker used by both Home (quick access) and the Activités
/// tab (see docs/RELEASE_0_1.md — "Activity library"). One widget, two
/// entry points, so they can never drift apart. Full-bleed editorial tiles
/// in the two brand accent colors — violet for Score, lime for Timer (see
/// the release brand brief section 8) — not a grid of small Material cards.
class ActivityCategoryGrid extends StatelessWidget {
  const ActivityCategoryGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).playTapColors;
    final categories = activityCategoriesOf(AppLocalizations.of(context)!);
    final brandPairs = [
      (background: colors.primary, foreground: colors.onPrimary),
      (background: colors.accent, foreground: colors.onAccent),
    ];

    return Column(
      children: [
        for (final (index, category) in categories.indexed) ...[
          if (index > 0) const SizedBox(height: PlayTapSpacing.md),
          Expanded(
            child: BigActionTile(
              icon: category.icon,
              label: category.label,
              backgroundColor: brandPairs[index].background,
              foregroundColor: brandPairs[index].foreground,
              onTap: () => context.push(category.route),
            ),
          ),
        ],
      ],
    );
  }
}
