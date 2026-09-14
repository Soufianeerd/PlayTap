import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/time/app_clock.dart';
import '../../data/local/app_database.dart';
import '../../data/repositories/event_repository.dart';
import '../../data/repositories/session_repository.dart';

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

/// The app's clock — a [FakeClock] override in tests, [SystemAppClock] in
/// production (see `core/time/app_clock.dart`).
final clockProvider = Provider<AppClock>((ref) => SystemAppClock());

/// Reactive active session across *all* categories, if any — drives the
/// generic "REPRENDRE L'ACTIVITÉ" CTA on Home (see docs/RELEASE_0_1.md and
/// the Phase 1B.2 brief section 26 — one active session, Score or Timer).
final activeSessionProvider = StreamProvider(
  (ref) => ref.watch(sessionRepositoryProvider).watchActiveSession(),
);
