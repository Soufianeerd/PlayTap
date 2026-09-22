import 'package:flutter/material.dart';

import '../../app/theme/theme.dart';
import '../../l10n/app_localizations.dart';
import '../shared/activity_category_grid.dart';

class ActivitiesPage extends StatelessWidget {
  const ActivitiesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.navActivities)),
      body: const Padding(
        padding: EdgeInsets.all(PlayTapSpacing.lg),
        child: ActivityCategoryGrid(),
      ),
    );
  }
}
