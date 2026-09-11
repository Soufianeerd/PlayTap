/// Base type for expected, recoverable failures (e.g. a local read/write
/// that failed). Unexpected bugs should still throw normally — this is not
/// a catch-all replacement for exceptions.
class AppFailure {
  const AppFailure(this.message);

  final String message;

  @override
  String toString() => 'AppFailure: $message';
}
