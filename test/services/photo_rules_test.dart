import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/services/photo_reassembler.dart';
import 'package:meshtrax/services/photo_rules.dart';
import 'package:meshtrax/models/channel.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

Channel channel(String name, Uint8List psk) =>
    Channel(index: 1, name: name, psk: psk);

void main() {
  final private = channel('Trip', Uint8List.fromList(List.filled(16, 7)));
  final hashtag = channel('#hiking', Channel.derivePskFromHashtag('#hiking'));
  final public = channel(
    'Public',
    Channel.parsePskHex(Channel.publicChannelPsk),
  );
  final now = DateTime(2026, 11, 20, 12);
  const usa = 910525; // USA/Canada preset, kHz

  group('where the rules apply', () {
    test('on a MeshCore preset frequency, whatever the other settings', () {
      expect(photoRulesApply(usa), isTrue);
      expect(photoRulesApply(869525), isTrue); // EU/UK
    });

    test('not off-grid, not a custom frequency, not unknown', () {
      for (final khz in [433000, 869495, 918000]) {
        expect(photoRulesApply(khz), isFalse, reason: '$khz');
      }
      expect(photoRulesApply(920000), isFalse); // the test frequency
      expect(photoRulesApply(null), isFalse);
    });
  });

  group('what the sender is asked', () {
    test('on a MeshCore frequency: airtime, and more on open channels', () {
      expect(photoWarningFor(private, usa), PhotoWarning.airtime);
      expect(photoWarningFor(public, usa), PhotoWarning.openChannel);
      expect(photoWarningFor(hashtag, usa), PhotoWarning.openChannel);
    });

    test('a channel named with # but its own key is private', () {
      final named = channel('#trip', Uint8List.fromList(List.filled(16, 9)));
      expect(photoWarningFor(named, usa), PhotoWarning.airtime);
    });

    test('off a MeshCore frequency, nothing', () {
      expect(photoWarningFor(public, 920000), PhotoWarning.none);
      expect(photoWarningFor(private, 918000), PhotoWarning.none);
    });

    test('a photo measured in text messages', () {
      int airtime(int bytes) => bytes == photoTextMessageAirBytes ? 256 : 0;
      expect(photoTextMessages(const Duration(milliseconds: 2120), airtime), 8);
    });
  });

  group('on a MeshCore frequency, through repeaters', () {
    final threeMinutesAgo = now.subtract(const Duration(minutes: 3));

    /// What the next photo still waits after a photo of [packets] packets
    /// sent [at].
    PhotoBlock? blocked(int packets, DateTime at) => photoSendBlocked(
      freqKhz: usa,
      last: (at: at, packets: packets),
      now: now,
    );

    test('with no photo before, nothing waits', () {
      expect(photoSendBlocked(freqKhz: usa, last: null, now: now), isNull);
    });

    test('the next photo waits by the size of the last one', () {
      expect(photoGapRepeaters(1), Duration.zero);
      expect(photoGapRepeaters(2), const Duration(minutes: 5));
      expect(photoGapRepeaters(3), const Duration(minutes: 10));
      expect(photoGapRepeaters(4), const Duration(minutes: 20));
      expect(photoGapRepeaters(6), const Duration(minutes: 20));
      expect(blocked(1, threeMinutesAgo), isNull, reason: 'one packet');
      expect(blocked(2, threeMinutesAgo), (packets: 2, gap: 5, minutes: 2));
      expect(blocked(3, threeMinutesAgo), (packets: 3, gap: 10, minutes: 7));
      expect(blocked(5, threeMinutesAgo), (packets: 5, gap: 20, minutes: 17));
      expect(blocked(5, now.subtract(const Duration(minutes: 20))), isNull);
    });
  });

  test('off a MeshCore frequency, nothing is held back', () {
    expect(
      photoSendBlocked(
        freqKhz: 920000,
        last: (at: now, packets: 6),
        now: now,
      ),
      isNull,
    );
  });

  group('the gap between packets', () {
    int airtime(int bytes) => 650;

    Duration gap(
      int bytes, {
      required bool zeroHop,
      bool repairPacket = true,
      int Function(int bytes)? airtimeMs,
      bool shared = false,
    }) =>
        photoGapFor(
          bytes,
          zeroHop: zeroHop,
          repairPacket: repairPacket,
          airtimeMs: airtimeMs ?? airtime,
          shared: shared,
        );

    test('zero hop: the airtime and half a second', () {
      expect(gap(500, zeroHop: true), const Duration(milliseconds: 1150));
    });

    test('a flood: until the packet has cleared two hops of repeaters', () {
      expect(gap(500, zeroHop: false), const Duration(milliseconds: 5700));
    });

    test('on a shared frequency, at least 4 airtimes, within the window', () {
      expect(
        gap(500, zeroHop: true, shared: true),
        const Duration(milliseconds: 2600),
      );
      expect(
        gap(500, zeroHop: false, shared: true),
        const Duration(milliseconds: 5700),
      );
      // 3.1 s packets (USA Arizona): 4 airtimes fit the receivers' window.
      int slow(int bytes) => 3120;
      expect(
        gap(700, zeroHop: true, airtimeMs: slow, shared: true),
        const Duration(milliseconds: 12480),
      );
      // 60 s packets would miss it: a 6-packet photo spreads three quarters
      // of the receivers' 20 minutes over its 5 gaps.
      int crawl(int bytes) => 60000;
      expect(
        gap(700, zeroHop: true, airtimeMs: crawl, shared: true),
        const Duration(seconds: 180),
      );
      // Without the repair packet it is 5 packets, over 4 gaps.
      expect(
        gap(700, zeroHop: true, repairPacket: false, airtimeMs: crawl,
            shared: true),
        const Duration(seconds: 225),
      );
    });
  });

  group('the least gap after a photo packet', () {
    const airtime = Duration(milliseconds: 650);
    const slow = Duration(seconds: 2);
    const crawl = Duration(seconds: 30);

    test('zero hop: its airtime and half a second', () {
      expect(photoPacketGap(airtime), const Duration(milliseconds: 1150));
    });

    test('a flood: until it has cleared two hops of repeaters', () {
      // 650 ms on air, then two hops of up to 1625 ms wait and 650 ms on
      // air, then half a second.
      expect(
        photoPacketGapFlood(airtime, packets: 6),
        const Duration(milliseconds: 5700),
      );
      expect(
        photoPacketGapFlood(slow, packets: 6),
        const Duration(milliseconds: 16500),
      );
      expect(
        photoPacketGapFlood(airtime, packets: 1),
        const Duration(milliseconds: 5700),
        reason: 'a photo of one packet waits as long',
      );
    });

    test('capped so the photo goes out within the receivers\' window, never '
        'below the zero-hop gap', () {
      final gap = photoPacketGapFlood(crawl, packets: 6);
      expect(gap, const Duration(seconds: 180));
      expect(gap * 5, lessThanOrEqualTo(photoReceiveWindow * 0.75));
      expect(photoPacketGapFlood(crawl, packets: 40), photoPacketGap(crawl));
    });
  });

  test('the last photo is remembered per radio', () async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    const a = 'aabbccddeeff00112233445566778899';
    const b = '99887766554433221100ffeeddccbbaa';
    await notePhotoSent(a, now, packets: 3);
    expect(photoLastSentViaRepeaters(a), (at: now, packets: 3));
    expect(photoLastSentViaRepeaters(b), isNull);
    expect(photoLastSentViaRepeaters(''), isNull);

    final later = now.add(const Duration(hours: 1));
    await notePhotoSent(a, later, packets: 2);
    expect(photoLastSentViaRepeaters(a), (at: later, packets: 2));
  });

  test('a photo noted by MeshTrax 1.12.0, its time only, waits the longest',
      () async {
    const a = 'aabbccddeeff00112233445566778899';
    SharedPreferences.setMockInitialValues({
      'photo_last_sent_via_aabbccddeeff0011': now.millisecondsSinceEpoch,
    });
    PrefsManager.reset();
    await PrefsManager.initialize();
    expect(photoLastSentViaRepeaters(a), (at: now, packets: 4));
  });

  test('a photo no repeater carried gives back its time, and leaves a later '
      'photo\'s alone', () async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    const a = 'aabbccddeeff00112233445566778899';
    await notePhotoSent(a, now, packets: 6);
    await notePhotoNotCarried(a, now);
    expect(photoLastSentViaRepeaters(a), isNull);
    expect(
      photoSendBlocked(
        freqKhz: meshCoreFrequenciesKhz.first,
        last: photoLastSentViaRepeaters(a),
        now: now.add(const Duration(minutes: 1)),
      ),
      isNull,
    );

    final later = now.add(const Duration(minutes: 40));
    await notePhotoSent(a, later, packets: 6);
    await notePhotoNotCarried(a, now);
    expect(photoLastSentViaRepeaters(a), (at: later, packets: 6));
  });
}
