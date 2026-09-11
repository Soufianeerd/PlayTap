import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/theme.dart';

class _HomeSection {
  const _HomeSection(this.label, this.icon);

  final String label;
  final IconData icon;
}

const List<_HomeSection> _sections = [
  _HomeSection('Score', Icons.sports_tennis_outlined),
  _HomeSection('Timer', Icons.timer_outlined),
  _HomeSection('Training', Icons.fitness_center_outlined),
  _HomeSection('Custom', Icons.tune_outlined),
];

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).playTapColors;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: PlayTapSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: PlayTapSpacing.xxl),
              Text(
                'PlayTap',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: PlayTapSpacing.xs),
              Text(
                'Tout votre sport, au poignet.',
                style: PlayTapTypography.body.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: PlayTapSpacing.xxl),
              Expanded(
                child: GridView.builder(
                  itemCount: _sections.length,
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 220,
                    mainAxisSpacing: PlayTapSpacing.md,
                    crossAxisSpacing: PlayTapSpacing.md,
                    childAspectRatio: 1.1,
                  ),
                  itemBuilder: (context, index) {
                    final section = _sections[index];
                    return _SectionCard(section: section);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.section});

  final _HomeSection section;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).playTapColors;

    return Material(
      color: colors.surface,
      borderRadius: PlayTapRadii.mdRadius,
      child: InkWell(
        borderRadius: PlayTapRadii.mdRadius,
        onTap: () => context.push('/coming-soon', extra: section.label),
        child: Padding(
          padding: const EdgeInsets.all(PlayTapSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(section.icon, color: colors.accent, size: 28),
              Text(
                section.label,
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
