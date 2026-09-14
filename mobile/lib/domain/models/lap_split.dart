import 'package:meta/meta.dart';

/// One recorded lap. [cumulativeElapsedMs] is the total elapsed time at the
/// moment the lap was recorded — derived by the engine from the
/// `LAP_RECORDED` event's own timestamp during replay, never duplicated
/// into the event's payload (see `playtap-offline-first` — no second
/// source of truth). [splitMs] (this lap's own duration) is derived from
/// consecutive [cumulativeElapsedMs] values, not stored anywhere.
@immutable
class LapSplit {
  const LapSplit({
    required this.eventId,
    required this.lapNumber,
    required this.cumulativeElapsedMs,
    required this.splitMs,
  });

  final String eventId;
  final int lapNumber;
  final int cumulativeElapsedMs;
  final int splitMs;

  @override
  bool operator ==(Object other) =>
      other is LapSplit &&
      eventId == other.eventId &&
      lapNumber == other.lapNumber &&
      cumulativeElapsedMs == other.cumulativeElapsedMs &&
      splitMs == other.splitMs;

  @override
  int get hashCode =>
      Object.hash(eventId, lapNumber, cumulativeElapsedMs, splitMs);
}
