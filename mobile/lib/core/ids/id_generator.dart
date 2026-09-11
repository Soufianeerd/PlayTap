import 'package:uuid/uuid.dart';

/// Central UUID source. Sessions, events and presets all need a unique id
/// (see docs/DATA_MODEL.md) — going through one generator means the id
/// format only has to be decided once.
abstract final class IdGenerator {
  static const Uuid _uuid = Uuid();

  static String v4() => _uuid.v4();
}
