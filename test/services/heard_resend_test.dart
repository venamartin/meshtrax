import 'dart:convert';
import 'dart:typed_data';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/services/heard_service.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:traxheard/traxheard.dart';

// The owner, 2026-11-19: a message only one repeater carried goes out once
// more only while observers really hear this radio (an ear in the last 2
// hours), and these resends stop after 3 misses in a row until an ear.
final _self = Uint8List.fromList(List.filled(32, 0x77));
final _other = Uint8List.fromList(List.filled(32, 0x55));

Uint8List _selfInfo() {
  final w = BytesBuilder();
  w.add([respCodeSelfInfo, advTypeChat, 20, 22]);
  w.add(_self);
  w.add(Uint8List(8));
  w.add([0, 0, 0, 1]);
  w.add(
    (ByteData(8)
          ..setUint32(0, 910525, Endian.little)
          ..setUint32(4, 62500, Endian.little))
        .buffer
        .asUint8List(),
  );
  w.add([7, 5]);
  w.add(utf8.encode('GWQ'));
  return w.toBytes();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MeshCoreConnector radio;

  /// [lastEar]: when an observer last heard each radio, saved earlier.
  Future<void> attach({
    bool enabled = true,
    Map<Uint8List, Duration> lastEar = const {},
  }) async {
    final now = DateTime.now();
    SharedPreferences.setMockInitialValues({
      'heard_check_enabled': enabled,
      'heard_check_server': 'https://corescope.stonekitty.net',
      'heard_check_last_ear': jsonEncode({
        for (final MapEntry(:key, :value) in lastEar.entries)
          pubKeyToHex(key): now.subtract(value).millisecondsSinceEpoch,
      }),
    });
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
    radio = MeshCoreConnector();
    addTearDown(radio.dispose);
    radio.handleFrameForTest(_selfInfo());
    await pumpEventQueue(times: 200);
    HeardService.resetForTesting();
    HeardService.instance.attach(radio);
  }

  bool allowed() => radio.mayResendAfterOneRepeater!();

  void ear(String messageId) => HeardService.instance
      .heardForTest(messageId, const [Sighting(observer: 'Ridge')]);

  test('no ear yet: one repeat is enough', () async {
    await attach();
    expect(allowed(), isFalse);
  });

  test('an ear allows it, and a restart keeps it', () async {
    await attach();
    ear('m1');
    expect(allowed(), isTrue);

    await pumpEventQueue();
    HeardService.resetForTesting();
    HeardService.instance.attach(radio);
    expect(allowed(), isTrue);
  });

  test('an ear counts for 2 hours', () async {
    await attach(lastEar: {_self: const Duration(minutes: 119)});
    expect(allowed(), isTrue);
    await attach(lastEar: {_self: const Duration(minutes: 121)});
    expect(allowed(), isFalse);
  });

  test("another radio's ear does not count", () async {
    await attach(lastEar: {_other: const Duration(minutes: 1)});
    expect(allowed(), isFalse);
  });

  test('switched off: one repeat is enough', () async {
    await attach(
      enabled: false,
      lastEar: {_self: const Duration(minutes: 1)},
    );
    expect(allowed(), isFalse);
  });

  test('a new server needs an ear of its own', () async {
    await attach(lastEar: {_self: const Duration(minutes: 1)});
    await HeardService.instance.setServer('https://live.chattamesh.com');
    expect(allowed(), isFalse);
  });

  test('3 unheard resends in a row stop them until an ear', () async {
    await attach(lastEar: {_self: const Duration(minutes: 1)});
    fakeAsync((async) {
      for (final (i, id) in ['m1', 'm2', 'm3'].indexed) {
        expect(allowed(), isTrue, reason: '$i misses');
        radio.onResentAfterOneRepeater!(id);
        async.elapse(const Duration(seconds: 91));
      }
      expect(allowed(), isFalse);

      ear('m4');
      expect(allowed(), isTrue);
    });
  });

  test('an ear on another message starts the row again', () async {
    await attach(lastEar: {_self: const Duration(minutes: 1)});
    fakeAsync((async) {
      radio.onResentAfterOneRepeater!('m1');
      async.elapse(const Duration(seconds: 30));
      ear('m2');
      async.elapse(const Duration(seconds: 61));
      for (final id in ['m3', 'm4']) {
        radio.onResentAfterOneRepeater!(id);
        async.elapse(const Duration(seconds: 91));
      }
      expect(allowed(), isTrue, reason: 'm1 went unheard before the ear');
    });
  });

  test('a resend an observer heard is not a miss', () async {
    await attach(lastEar: {_self: const Duration(minutes: 1)});
    fakeAsync((async) {
      for (final id in ['m1', 'm2']) {
        radio.onResentAfterOneRepeater!(id);
        async.elapse(const Duration(seconds: 91));
      }
      radio.onResentAfterOneRepeater!('m3');
      async.elapse(const Duration(seconds: 50));
      ear('m3');
      async.elapse(const Duration(seconds: 41));
      for (final id in ['m5', 'm6']) {
        radio.onResentAfterOneRepeater!(id);
        async.elapse(const Duration(seconds: 91));
      }
      expect(allowed(), isTrue, reason: 'the count started again');
    });
  });
}
