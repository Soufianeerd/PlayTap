import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/theme.dart';

class ActivityCategory {
  const ActivityCategory(this.label, this.icon, this.route);

  final String label;
  final IconData icon;

  /// Route pushed on tap. Categories without a real destination yet push
  /// `/coming-soon` (see `features/shared/coming_soon_page.dart`).
  final String route;
}

const List<ActivityCategory> activityCategories = [
  ActivityCategory('Score', Icons.sports_tennis_outlined, '/activities/score'),
  ActivityCategory('Timer', Icons.timer_outlined, '/activities/timer'),
  ActivityCategory('Training', Icons.fitness_center_outlined, '/coming-soon'),
  ActivityCategory('Custom', Icons.tune_outlined, '/coming-soon'),
];

/// The 4-category grid used by both Home (quick access) and the Activités
/// tab (see docs/RELEASE_0_1.md — "Activity library"). One widget, two
/// entry points, so they can never drift apart.
class ActivityCategoryGrid extends StatelessWidget {
  const ActivityCategoryGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: activityCategories.length,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        mainAxisSpacing: PlayTapSpacing.md,
        crossAxisSpacing: PlayTapSpacing.md,
        childAspectRatio: 1.1,
      ),
      itemBuilder: (context, index) =>
          _CategoryCard(category: activityCategories[index]),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category});

  final ActivityCategory category;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).playTapColors;

    return Material(
      color: colors.surface,
      borderRadius: PlayTapRadii.mdRadius,
      child: InkWell(
        borderRadius: PlayTapRadii.mdRadius,
        onTap: () => context.push(
          category.route,
          extra: category.route == '/coming-soon' ? category.label : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(PlayTapSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(category.icon, color: colors.accent, size: 28),
              Text(
                category.label,
                style: PlayTapTypography.title.copyWith(
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
