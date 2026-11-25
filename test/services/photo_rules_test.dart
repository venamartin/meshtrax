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

  group('on a MeshCore frequency', () {
    PhotoBlock? blocked({DateTime? lastSent}) =>
        photoSendBlocked(freqKhz: usa, lastSent: lastSent, now: now);

    test('every channel may take a photo, Public too', () {
      expect(blocked(), isNull);
    });

    test('one photo per radio every 10 minutes, zero hop', () {
      expect(blocked(lastSent: now.subtract(const Duration(minutes: 3))), (
        reason: PhotoBlockReason.wait,
        minutes: 7,
      ));
      expect(
        blocked(lastSent: now.subtract(const Duration(minutes: 10))),
        isNull,
      );
    });

    test('through repeaters, one every 20 minutes on top of that', () {
      final at = now.subtract(const Duration(minutes: 15));
      PhotoBlock? via({required bool viaRepeaters}) => photoSendBlocked(
        freqKhz: usa,
        lastSent: at,
        lastSentViaRepeaters: at,
        viaRepeaters: viaRepeaters,
        now: now,
      );
      expect(via(viaRepeaters: true), (
        reason: PhotoBlockReason.waitRepeaters,
        minutes: 5,
      ));
      expect(via(viaRepeaters: false), isNull);
      expect(
        photoSendBlocked(
          freqKhz: usa,
          lastSent: now.subtract(const Duration(minutes: 5)),
          lastSentViaRepeaters: null,
          viaRepeaters: true,
          now: now,
        ),
        (reason: PhotoBlockReason.wait, minutes: 5),
      );
    });
  });

  test('off a MeshCore frequency, nothing is held back', () {
    expect(photoSendBlocked(freqKhz: 920000, lastSent: now, now: now), isNull);
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
    expect(photoLastSent(a), now);
    expect(photoLastSent(b), isNull);
    expect(photoLastSent(''), isNull);
    expect(photoLastSentViaRepeaters(a), isNull);

    final later = now.add(const Duration(hours: 1));
    await notePhotoSent(a, later, viaRepeaters: true);
    expect(photoLastSent(a), later);
    expect(photoLastSentViaRepeaters(a), later);
  });

  test('a photo no repeater carried gives back its 20 minutes, not its 10, '
      'and leaves a later photo\'s alone', () async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    const a = 'aabbccddeeff00112233445566778899';
    await notePhotoSent(a, now, viaRepeaters: true);
    await notePhotoNotCarried(a, now);
    expect(photoLastSent(a), now);
    expect(photoLastSentViaRepeaters(a), isNull);
    expect(
      photoSendBlocked(
        freqKhz: meshCoreFrequenciesKhz.first,
        lastSent: photoLastSent(a),
        lastSentViaRepeaters: photoLastSentViaRepeaters(a),
        viaRepeaters: true,
        now: now.add(const Duration(minutes: 11)),
      ),
      isNull,
    );

    final later = now.add(const Duration(minutes: 40));
    await notePhotoSent(a, later, viaRepeaters: true);
    await notePhotoNotCarried(a, now);
    expect(photoLastSentViaRepeaters(a), later);
  });
}
