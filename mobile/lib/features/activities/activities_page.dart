import 'package:flutter/material.dart';

import '../../app/theme/theme.dart';
import '../shared/activity_category_grid.dart';

class ActivitiesPage extends StatelessWidget {
  const ActivitiesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Activités')),
      body: const Padding(
        padding: EdgeInsets.all(PlayTapSpacing.lg),
        child: ActivityCategoryGrid(),
      ),
    );
  }
}
