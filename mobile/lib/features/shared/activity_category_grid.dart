import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/theme.dart';
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
const List<ActivityCategory> activityCategories = [
  ActivityCategory(
    'Compter un score',
    Icons.sports_tennis_outlined,
    '/score/free/config',
  ),
  ActivityCategory('Chronométrer', Icons.timer_outlined, '/activities/timer'),
];

/// The 2-category picker used by both Home (quick access) and the Activités
/// tab (see docs/RELEASE_0_1.md — "Activity library"). One widget, two
/// entry points, so they can never drift apart. Full-bleed tiles, not a
/// grid of small cards — PlayTap 1.0.0 only ever has a couple of choices
/// here, so each one gets real tap area instead of leaving dead space.
class ActivityCategoryGrid extends StatelessWidget {
  const ActivityCategoryGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final (index, category) in activityCategories.indexed) ...[
          if (index > 0) const SizedBox(height: PlayTapSpacing.md),
          Expanded(
            child: BigActionTile(
              icon: category.icon,
              label: category.label,
              alternate: index.isOdd,
              onTap: () => context.push(category.route),
            ),
          ),
        ],
      ],
    );
  }
}
