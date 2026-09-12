import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

/// Manual native connection (Drift's other first-class setup path — see
/// mobile/pubspec.yaml for why `drift_flutter` isn't used here). One file
/// in the app's documents directory; offline-first, no server involved.
LazyDatabase openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'playtap.sqlite'));

    // sqlite3 needs a writable temp dir; the OS default may be sandboxed
    // away on Android — see drift's "existing_databases" guide.
    final cacheBase = (await getTemporaryDirectory()).path;
    sqlite3.tempDirectory = cacheBase;

    return NativeDatabase.createInBackground(file);
  });
}
