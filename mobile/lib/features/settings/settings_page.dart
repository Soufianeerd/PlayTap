import 'package:flutter/material.dart';

import '../../app/theme/theme.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Réglages')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(PlayTapSpacing.xl),
          child: Text(
            'Aucun réglage disponible pour le moment.',
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
