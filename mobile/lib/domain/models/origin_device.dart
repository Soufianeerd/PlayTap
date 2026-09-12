/// Device that produced an event. See docs/WATCH_SYNC.md — event ordering
/// relies on (originDevice, originSequence), never on timestamp alone.
enum OriginDevice {
  phone,
  watchApple,
  watchWearOs;

  String toJson() => switch (this) {
    OriginDevice.phone => 'phone',
    OriginDevice.watchApple => 'watch_apple',
    OriginDevice.watchWearOs => 'watch_wear_os',
  };

  static OriginDevice fromJson(String value) => switch (value) {
    'phone' => OriginDevice.phone,
    'watch_apple' => OriginDevice.watchApple,
    'watch_wear_os' => OriginDevice.watchWearOs,
    _ => throw ArgumentError.value(value, 'value', 'Unknown OriginDevice'),
  };
}
