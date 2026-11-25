import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
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

    PhotoBlock? blocked(
      int packets, {
      DateTime? lastSentViaRepeaters,
      bool viaRepeaters = true,
    }) => photoSendBlocked(
      freqKhz: usa,
      lastSentViaRepeaters: lastSentViaRepeaters,
      viaRepeaters: viaRepeaters,
      packets: packets,
      now: now,
    );

    test('every channel may take a photo, Public too', () {
      expect(blocked(6), isNull);
    });

    test('a photo waits by its size after the last one', () {
      expect(photoGapRepeaters(1), Duration.zero);
      expect(photoGapRepeaters(2), const Duration(minutes: 5));
      expect(photoGapRepeaters(3), const Duration(minutes: 10));
      expect(photoGapRepeaters(4), const Duration(minutes: 20));
      expect(photoGapRepeaters(6), const Duration(minutes: 20));
      expect(blocked(1, lastSentViaRepeaters: threeMinutesAgo), isNull);
      expect(blocked(2, lastSentViaRepeaters: threeMinutesAgo), (
        gap: 5,
        minutes: 2,
      ));
      expect(blocked(3, lastSentViaRepeaters: threeMinutesAgo), (
        gap: 10,
        minutes: 7,
      ));
      expect(blocked(5, lastSentViaRepeaters: threeMinutesAgo), (
        gap: 20,
        minutes: 17,
      ));
      expect(
        blocked(
          5,
          lastSentViaRepeaters: now.subtract(const Duration(minutes: 20)),
        ),
        isNull,
      );
    });

    test('zero hop never waits', () {
      expect(
        blocked(6, lastSentViaRepeaters: now, viaRepeaters: false),
        isNull,
      );
    });
  });

  test('off a MeshCore frequency, nothing is held back', () {
    expect(
      photoSendBlocked(
        freqKhz: 920000,
        lastSentViaRepeaters: now,
        viaRepeaters: true,
        packets: 6,
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
      // 3.1 s packets (USA Arizona): 4 airtimes would miss the window, so a
      // 6-packet photo spreads 45 s over its 5 gaps.
      int slow(int bytes) => 3120;
      expect(
        gap(700, zeroHop: true, airtimeMs: slow, shared: true),
        const Duration(seconds: 9),
      );
      // Without the repair packet it is 5 packets, 45 s over 4 gaps.
      expect(
        gap(700, zeroHop: true, repairPacket: false, airtimeMs: slow,
            shared: true),
        const Duration(milliseconds: 11250),
      );
    });
  });

  test('the last photo is remembered per radio', () async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    const a = 'aabbccddeeff00112233445566778899';
    const b = '99887766554433221100ffeeddccbbaa';
    await notePhotoSent(a, now);
    expect(photoLastSentViaRepeaters(a), now);
    expect(photoLastSentViaRepeaters(b), isNull);
    expect(photoLastSentViaRepeaters(''), isNull);

    final later = now.add(const Duration(hours: 1));
    await notePhotoSent(a, later);
    expect(photoLastSentViaRepeaters(a), later);
  });

  test('a photo no repeater carried gives back its time, and leaves a later '
      'photo\'s alone', () async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    const a = 'aabbccddeeff00112233445566778899';
    await notePhotoSent(a, now);
    await notePhotoNotCarried(a, now);
    expect(photoLastSentViaRepeaters(a), isNull);
    expect(
      photoSendBlocked(
        freqKhz: meshCoreFrequenciesKhz.first,
        lastSentViaRepeaters: photoLastSentViaRepeaters(a),
        viaRepeaters: true,
        packets: 6,
        now: now.add(const Duration(minutes: 1)),
      ),
      isNull,
    );

    final later = now.add(const Duration(minutes: 40));
    await notePhotoSent(a, later);
    await notePhotoNotCarried(a, now);
    expect(photoLastSentViaRepeaters(a), later);
  });
}
