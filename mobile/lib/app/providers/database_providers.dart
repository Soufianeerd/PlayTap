import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/app_database.dart';
import '../../data/repositories/event_repository.dart';
import '../../data/repositories/session_repository.dart';
import '../../domain/models/session_category.dart';

/// One `AppDatabase` for the app's lifetime — see the Drift FAQ on why
/// multiple live instances over the same file are unsafe.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final sessionRepositoryProvider = Provider<SessionRepository>(
  (ref) => SessionRepository(ref.watch(databaseProvider)),
);

final eventRepositoryProvider = Provider<EventRepository>(
  (ref) => EventRepository(ref.watch(databaseProvider)),
);

/// Reactive active Score session, if any — drives the "Reprendre la
/// partie" CTA on Home (see docs/RELEASE_0_1.md, "une seule session
/// active").
final activeScoreSessionProvider = StreamProvider(
  (ref) => ref
      .watch(sessionRepositoryProvider)
      .watchActiveSession(SessionCategory.score),
);
