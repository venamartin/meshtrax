import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/models/channel_message.dart';

// The two halves of what a queue-drained (offline-collected) message must
// look like: it keeps the sender's claimed send time unless the sender's
// clock is BROKEN, and it keeps the hop count the frame carried even though
// the queue frame ships no path bytes.
void main() {
  group('sanitizeSenderTimestamp — backlog drain (radio heard it earlier)',
      () {
    // The causality floor: the channel's newest stored message before sync.
    // Everything in the radio's queue was heard AFTER it — claims from
    // before it are broken clocks, however plausible the date looks.
    final now = DateTime(2026, 8, 9, 18, 0);
    final floor = DateTime(2026, 8, 2, 9, 30); // left home a week ago
    DateTime sane(DateTime ts, {DateTime? channelFloor}) =>
        MeshCoreConnector.sanitizeSenderTimestamp(ts, now,
            fromBacklog: true, channelFloor: channelFloor);

    test('a week away keeps its real spread of days', () {
      final midweek = DateTime(2026, 8, 5, 14, 20);
      expect(sane(midweek, channelFloor: floor), midweek);
    });

    test('an overnight backlog keeps its real send times', () {
      final lastNight = now.subtract(const Duration(hours: 11));
      expect(sane(lastNight, channelFloor: floor), lastNight);
    });

    test('a claim from BEFORE the floor is a broken clock', () {
      // Sync on Aug 9, floor Aug 2 — a "July 13" claim cannot have been
      // heard by the radio and is rewritten to now.
      expect(sane(DateTime(2026, 7, 13, 15, 41), channelFloor: floor), now);
    });

    test('a dead RTC (1970) is rewritten to now', () {
      expect(
        sane(DateTime.fromMillisecondsSinceEpoch(0), channelFloor: floor),
        now,
      );
    });

    test('cross-sender skew just past the floor is tolerated', () {
      final slightlyBeforeFloor =
          floor.subtract(const Duration(minutes: 5));
      expect(
        sane(slightlyBeforeFloor, channelFloor: floor),
        slightlyBeforeFloor,
      );
    });

    test('an empty channel falls back to the 30-day cap', () {
      final lastWeek = now.subtract(const Duration(days: 6));
      expect(sane(lastWeek), lastWeek);
      expect(sane(now.subtract(const Duration(days: 31))), now);
    });

    test('a floor older than 30 days still governs (six weeks away)', () {
      // The floor IS the rule when history exists — the 30-day cap only
      // bounds channels with nothing to compare against.
      final sixWeekFloor = now.subtract(const Duration(days: 45));
      final claim = now.subtract(const Duration(days: 40));
      expect(sane(claim, channelFloor: sixWeekFloor), claim);
      expect(
        sane(now.subtract(const Duration(days: 46)),
            channelFloor: sixWeekFloor),
        now,
      );
    });

    test('a fast clock more than a minute ahead is rewritten to now', () {
      expect(sane(now.add(const Duration(minutes: 5)), channelFloor: floor),
          now);
    });
  });

  group('sanitizeSenderTimestamp — live (heard over RF seconds ago)', () {
    // Radio waves do not age in flight and mesh propagation is bounded by
    // ~1 minute (not enough hops for more). Field case: a message claiming
    // 13 July arrived live on 3 August and built a "Mon, 13 July" section
    // into the chat.
    final now = DateTime(2026, 8, 3, 20, 16);
    DateTime sane(DateTime ts) =>
        MeshCoreConnector.sanitizeSenderTimestamp(ts, now, fromBacklog: false);

    test('the July-13 live message files under today', () {
      expect(sane(DateTime(2026, 7, 13, 15, 41)), now);
    });

    test('propagation plus a little skew is tolerated', () {
      final ninetySecondsAgo = now.subtract(const Duration(seconds: 90));
      expect(sane(ninetySecondsAgo), ninetySecondsAgo);
    });

    test('minutes in the past is a broken clock, rewritten to now', () {
      expect(sane(now.subtract(const Duration(minutes: 5))), now);
    });

    test('a recent message is untouched', () {
      final justNow = now.subtract(const Duration(seconds: 40));
      expect(sane(justNow), justNow);
    });

    test('slightly ahead (propagation slack) is kept', () {
      final slightlyAhead = now.add(const Duration(seconds: 30));
      expect(sane(slightlyAhead), slightlyAhead);
    });

    test('a fast clock more than a minute ahead is rewritten to now', () {
      expect(sane(now.add(const Duration(minutes: 5))), now);
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

    test('a repeated message keeps the frame hop count, not 0/Direct', () {
      // Firmware sends pkt->path_len with no path bytes attached;
      // recomputing hops from the empty path made every queue-delivered
      // message claim it arrived "Direct".
      final msg = ChannelMessage.fromFrame(frame(7))!;
      expect(msg.pathLength, 7);
      expect(msg.pathBytes, isEmpty);
    });

    test('the wire byte low bits are HOPS at any hash width — never rescale',
        () {
      // path_len = (hashSize-1)<<6 | hopCount (firmware Packet.h). At
      // 2-byte hashes, 7 hops arrive as 0x47 — dividing by the width again
      // showed "4 hops" for a 7-hop message on 2-byte-hash networks.
      final msg = ChannelMessage.fromFrame(frame((1 << 6) | 7))!;
      expect(msg.pathLength, 7);
      expect(msg.pathHashSize, 2);
    });

    test('path_len 0 (flood heard directly) is Direct', () {
      expect(ChannelMessage.fromFrame(frame(0))!.pathLength, 0);
    });

    test('path_len 0xFF (non-flood) stays -1', () {
      expect(ChannelMessage.fromFrame(frame(0xFF))!.pathLength, -1);
    });
  });
}
