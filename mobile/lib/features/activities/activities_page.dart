import 'package:flutter/material.dart';

import '../../app/theme/theme.dart';

/// No preset catalogue exists yet (see docs/ROADMAP.md — Phase 2). This is
/// an honest empty state, not a placeholder full of fake activities.
class ActivitiesPage extends StatelessWidget {
  const ActivitiesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Activités')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(PlayTapSpacing.xl),
          child: Text(
            'La bibliothèque d\'activités sera disponible ici.',
            style: PlayTapTypography.body.copyWith(
              color: Theme.of(context).playTapColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
