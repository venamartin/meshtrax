/// Strictly increasing arrival stamps, in microseconds.
///
/// Conversations are ordered by when THIS app first saw a message, because
/// that is the one thing we actually know: the radio hands its offline queue
/// over in receive order, while the sender's clock may be hours out and
/// cannot always be corrected.
///
/// Wall-clock time alone is not enough — a phone's clock can step backwards
/// (NTP correction, timezone database update, the user setting it), which
/// would insert new messages above older ones. Each stamp is therefore forced
/// past the previous one.
class ArrivalClock {
  ArrivalClock._();

  static int _last = 0;

  /// The next stamp: now, or one microsecond past the last one issued if the
  /// system clock has not moved forward.
  static int next() {
    final now = DateTime.now().microsecondsSinceEpoch;
    _last = now > _last ? now : _last + 1;
    return _last;
  }

  /// Historical rows are seeded from the sender's timestamp so that existing
  /// conversations keep exactly the order they already display — the same
  /// conversion the v6 migration applies.
  static int fromSenderTimestamp(DateTime timestamp) =>
      timestamp.millisecondsSinceEpoch * 1000;

  /// Test hook: forget the last stamp issued.
  static void resetForTesting() => _last = 0;
}
