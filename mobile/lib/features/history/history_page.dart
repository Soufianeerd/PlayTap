import 'package:flutter/material.dart';

import '../../app/theme/theme.dart';

/// No persistence is wired up yet (see docs/ROADMAP.md — Phase 1). "No
/// sessions" here is literally true, not a fake empty state.
class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historique')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(PlayTapSpacing.xl),
          child: Text(
            'Aucune session enregistrée.',
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
