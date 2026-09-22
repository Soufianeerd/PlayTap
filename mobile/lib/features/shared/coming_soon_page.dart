import 'package:flutter/material.dart';

import '../../app/theme/theme.dart';
import '../../l10n/app_localizations.dart';

/// Placeholder destination for sections that don't have a real engine yet
/// (see `docs/ROADMAP.md`). Never shows fake data or a fake result — it
/// only states plainly that the feature isn't built yet.
class ComingSoonPage extends StatelessWidget {
  const ComingSoonPage({super.key, required this.sectionLabel});

  final String sectionLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(sectionLabel)),
      body: Padding(
        padding: const EdgeInsets.all(PlayTapSpacing.xl),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.build_outlined,
                size: 40,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              const SizedBox(height: PlayTapSpacing.lg),
              Text(
                l10n.comingSoonTitle,
                style: PlayTapTypography.title.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: PlayTapSpacing.sm),
              Text(
                l10n.comingSoonBody(sectionLabel),
                style: PlayTapTypography.body.copyWith(
                  color: Theme.of(context).playTapColors.muted,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
