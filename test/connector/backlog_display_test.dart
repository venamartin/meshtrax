import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/models/channel_message.dart';

// The two halves of what a queue-drained (offline-collected) message must
// look like: it keeps the sender's claimed send time unless the sender's
// clock is BROKEN, and it keeps the hop count the frame carried even though
// the queue frame ships no path bytes.
void main() {
  group('sanitizeSenderTimestamp', () {
    final now = DateTime(2026, 7, 31, 8, 45);

    test('an overnight backlog keeps its real send times', () {
      final lastNight = now.subtract(const Duration(hours: 11));
      expect(
        MeshCoreConnector.sanitizeSenderTimestamp(lastNight, now),
        lastNight,
      );
    });

    test('a day away on another companion keeps its send times', () {
      final yesterday = now.subtract(const Duration(days: 1, hours: 3));
      expect(
        MeshCoreConnector.sanitizeSenderTimestamp(yesterday, now),
        yesterday,
      );
    });

    test('a recent message is untouched', () {
      final justNow = now.subtract(const Duration(seconds: 40));
      expect(MeshCoreConnector.sanitizeSenderTimestamp(justNow, now), justNow);
    });

    test('a dead RTC (1970) is rewritten to now', () {
      expect(
        MeshCoreConnector.sanitizeSenderTimestamp(
          DateTime.fromMillisecondsSinceEpoch(0),
          now,
        ),
        now,
      );
    });

    test('older than 30 days is a broken clock, rewritten to now', () {
      final stale = now.subtract(const Duration(days: 31));
      expect(MeshCoreConnector.sanitizeSenderTimestamp(stale, now), now);
    });

    test('a fast clock more than a minute ahead is rewritten to now', () {
      final future = now.add(const Duration(minutes: 5));
      expect(MeshCoreConnector.sanitizeSenderTimestamp(future, now), now);
    });

    test('slightly ahead (propagation slack) is kept', () {
      final slightlyAhead = now.add(const Duration(seconds: 30));
      expect(
        MeshCoreConnector.sanitizeSenderTimestamp(slightlyAhead, now),
        slightlyAhead,
      );
    });
  });

  group('ChannelMessage.fromFrame hop count', () {
    // V3 queue frame:
    // [code][snr][rsv][rsv][channel_idx][path_len][txt_type][ts x4][text]
    Uint8List frame(int pathLen) {
      const respCodeChannelMsgRecvV3 = 17;
      const txtTypePlain = 0;
      final ts = DateTime(2026, 7, 30, 21, 0).millisecondsSinceEpoch ~/ 1000;
      final text = 'armooo: yubikey'.codeUnits;
      return Uint8List.fromList([
        respCodeChannelMsgRecvV3,
        0, 0, 0, // snr + reserved
        2, // channel_idx
        pathLen,
        txtTypePlain,
        ts & 0xFF, (ts >> 8) & 0xFF, (ts >> 16) & 0xFF, (ts >> 24) & 0xFF,
        ...text,
      ]);
    }

    test('a repeated message keeps the frame hop-byte count, not 0/Direct',
        () {
      // Firmware sends pkt->path_len (path BYTES) with no path bytes
      // attached; recomputing hops from the empty path made every
      // queue-delivered message claim it arrived "Direct".
      final msg = ChannelMessage.fromFrame(frame(7))!;
      expect(msg.pathLength, 7);
      expect(msg.pathBytes, isEmpty);
    });

    test('path_len 0 (flood heard directly) is Direct', () {
      expect(ChannelMessage.fromFrame(frame(0))!.pathLength, 0);
    });

    test('path_len 0xFF (non-flood) stays -1', () {
      expect(ChannelMessage.fromFrame(frame(0xFF))!.pathLength, -1);
    });
  });
}
