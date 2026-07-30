import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/models/channel_message.dart';

// Repeat dedup must compare WIRE timestamps, never stored ones.
//
// The ingest clamp rewrites any timestamp older than ten minutes to "now",
// but messageId is derived from the wire timestamp at construction and
// copyWith preserves it — so the wire time is always recoverable. Comparing
// stored (clamped) times was the duplicate mechanism from the field: a
// message arrives live in the morning; its retransmitted copy sits in the
// home companion's offline queue all day; the evening drain clamps the copy
// to "now", the 5-minute repeat window sees the two copies hours apart, and
// the same message files twice.
void main() {
  final morning = DateTime.now().subtract(const Duration(hours: 9));

  ChannelMessage wire(String text, DateTime ts) => ChannelMessage(
        senderName: 'CWI4',
        text: text,
        timestamp: ts,
        isOutgoing: false,
        channelIndex: 2,
      );

  group('wireTimestampMs', () {
    test('recovers the wire time from messageId', () {
      final msg = wire('Shorts again', morning);
      expect(
        MeshCoreConnector.wireTimestampMs(msg),
        morning.millisecondsSinceEpoch,
      );
    });

    test('survives the ingest clamp rewriting the stored timestamp', () {
      final clamped = wire('Shorts again', morning)
          .copyWith(timestamp: DateTime.now()); // what the clamp does
      expect(
        MeshCoreConnector.wireTimestampMs(clamped),
        morning.millisecondsSinceEpoch,
        reason: 'copyWith preserves messageId, so the wire time survives',
      );
    });

    test('falls back to the stored timestamp for a foreign messageId', () {
      final custom = wire('hello', morning)
          .copyWith(timestamp: DateTime.now());
      final foreign = ChannelMessage(
        senderName: custom.senderName,
        text: custom.text,
        timestamp: custom.timestamp,
        isOutgoing: false,
        channelIndex: 2,
        messageId: 'not-a-wire-id',
      );
      expect(
        MeshCoreConnector.wireTimestampMs(foreign),
        custom.timestamp.millisecondsSinceEpoch,
      );
    });
  });

  group('the field scenario', () {
    test('original and day-old retry copy sit inside the repeat window', () {
      // Original: arrived live at 9am, stored with its true time.
      final original = wire('Shorts again', morning);

      // Retry: retransmitted 30s later, queued by the home companion all
      // day, clamped to "now" when the evening drain ingests it.
      final retry = wire(
        'Shorts again',
        morning.add(const Duration(seconds: 30)),
      ).copyWith(timestamp: DateTime.now());

      // Stored times are ~9h apart — the old comparison rejected this pair.
      final storedDiff = original.timestamp
          .difference(retry.timestamp)
          .inMilliseconds
          .abs();
      expect(storedDiff, greaterThan(300000),
          reason: 'precondition: the clamp really did separate the copies');

      // Wire times are 30s apart — inside the window, so dedup can see them
      // as the same message.
      final wireDiff = (MeshCoreConnector.wireTimestampMs(original) -
              MeshCoreConnector.wireTimestampMs(retry))
          .abs();
      expect(wireDiff, lessThanOrEqualTo(300000));
    });
  });
}
