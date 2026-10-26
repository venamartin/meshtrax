import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Nearby-repeaters dialog (owner, 2026-10-14): with traffic on the mesh, a
// row turned green for any advert heard during a Discover, so the owner
// could not tell which repeaters answered. Only a tagged answer marks a row
// answered, with the level the repeater heard me at.
class _Connector extends MeshCoreConnector {
  @override
  bool get isConnected => true;

  @override
  Future<void> sendFrame(
    Uint8List data, {
    String? channelSendQueueId,
    bool expectsGenericAck = false,
  }) async {}
}

Uint8List _key(int seed) =>
    Uint8List.fromList(List.generate(32, (i) => seed + i));

/// A repeater's answer as the companion pushes it: how I heard it, then
/// the repeater's payload — type, how it heard me, my tag, its key.
Uint8List _answer(
  Uint8List key,
  int tag, {
  int heardMeQ = 26,
  int iHeardQ = 35,
}) {
  final w = BytesBuilder();
  w.add([pushCodeControlData, iHeardQ, 0xA0, 0]);
  w.add([ctlTypeNodeDiscoverResp | advTypeRepeater, heardMeQ]);
  w.add((ByteData(4)..setUint32(0, tag, Endian.little)).buffer.asUint8List());
  w.add(key);
  return w.toBytes();
}

/// A repeater's own advert, overheard zero-hop.
Uint8List _advert(Uint8List key, String name, {int snrQ = 40}) {
  final w = BytesBuilder();
  w.add([pushCodeLogRxData, snrQ, 0xA0]);
  w.add([(payloadTypeADVERT << 2) | 0x01, 0]);
  w.add(key);
  w.add(
    (ByteData(4)..setUint32(0, 1752854400, Endian.little)).buffer.asUint8List(),
  );
  w.add(Uint8List(64));
  w.addByte(advTypeRepeater | 0x80);
  w.add(utf8.encode(name));
  return w.toBytes();
}

Uint8List _selfInfo(Uint8List pubKey) {
  final w = BytesBuilder();
  w.add([respCodeSelfInfo, advTypeChat, 20, 22]);
  w.add(pubKey);
  w.add(Uint8List(8)); // lat, lon
  w.add([0, 0, 0, 1]);
  w.add(
    (ByteData(8)
          ..setUint32(0, 910525000, Endian.little)
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

  late _Connector c;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
    c = _Connector();
  });

  tearDown(() => c.dispose());

  DirectRepeater row(Uint8List key) => c.directRepeaters.singleWhere(
    (r) => r.publicKey != null && listEquals(r.publicKey, key),
  );

  test(
    'an answer records how the repeater heard me and which Discover',
    () async {
      await c.sendRepeaterDiscovery();
      c.handleFrameForTest(
        _answer(_key(0x10), c.pendingDiscoverTag!, heardMeQ: 26, iHeardQ: 35),
      );

      final r = row(_key(0x10));
      expect(r.uplinkSnr, 6.5);
      expect(r.snr, 8.75);
      expect(r.answeredScan, c.discoverScan);
      expect(r.answeredAt, isNotNull);
    },
  );

  test('an advert heard during the scan is not an answer', () async {
    await c.sendRepeaterDiscovery();
    c.handleFrameForTest(_advert(_key(0x20), 'Overheard'));

    final r = row(_key(0x20));
    expect(r.answeredScan, isNull);
    expect(r.uplinkSnr, isNull);
  });

  test('an answer carrying someone else\'s tag is ignored', () async {
    await c.sendRepeaterDiscovery();
    c.handleFrameForTest(_answer(_key(0x30), c.pendingDiscoverTag! ^ 1));

    expect(c.directRepeaters, isEmpty);
  });

  // Keys with distinct first bytes for up to 22 repeaters.
  int seed(int i) => 0x10 + i * 0x0B;
  const max = DirectRepeater.maxTracked;

  test('the list holds more than five overheard repeaters', () async {
    for (var i = 0; i < 8; i++) {
      c.handleFrameForTest(_advert(_key(seed(i)), 'R$i'));
    }
    expect(c.directRepeaters, hasLength(8));
  });

  test('overheard adverts never push out a repeater that answered', () async {
    await c.sendRepeaterDiscovery();
    for (var i = 0; i < max; i++) {
      c.handleFrameForTest(
        _answer(_key(seed(i)), c.pendingDiscoverTag!, iHeardQ: -40),
      );
    }
    // A louder overheard advert: before, it evicted the weakest answer.
    c.handleFrameForTest(_advert(_key(0x05), 'Loud', snrQ: 60));

    expect(c.directRepeaters, hasLength(max));
    expect(
      c.directRepeaters.every((r) => r.answeredScan == c.discoverScan),
      isTrue,
    );
  });

  test('every answer is kept, even past the cap', () async {
    await c.sendRepeaterDiscovery();
    for (var i = 0; i < max + 2; i++) {
      c.handleFrameForTest(_answer(_key(seed(i)), c.pendingDiscoverTag!));
    }
    expect(c.directRepeaters, hasLength(max + 2));
  });

  test('an answer replaces an overheard row when the list is full', () async {
    for (var i = 0; i < max; i++) {
      c.handleFrameForTest(_advert(_key(seed(i)), 'R$i'));
    }
    await c.sendRepeaterDiscovery();
    c.handleFrameForTest(_answer(_key(0x07), c.pendingDiscoverTag!));

    expect(c.directRepeaters, hasLength(max));
    expect(row(_key(0x07)).answeredScan, c.discoverScan);
  });

  test('a new Discover leaves earlier answers as history', () async {
    await c.sendRepeaterDiscovery();
    c.handleFrameForTest(_answer(_key(0x10), c.pendingDiscoverTag!));
    final first = c.discoverScan;
    await c.sendRepeaterDiscovery();

    final r = row(_key(0x10));
    expect(r.answeredScan, first);
    expect(c.discoverScan, first + 1);
    expect(r.uplinkSnr, isNotNull);
  });

  test('a long list from a busy Discover shrinks back to the cap', () async {
    await c.sendRepeaterDiscovery();
    for (var i = 0; i < max + 2; i++) {
      c.handleFrameForTest(_answer(_key(seed(i)), c.pendingDiscoverTag!));
    }
    await c.sendRepeaterDiscovery(); // the earlier answers are history now
    c.handleFrameForTest(_advert(_key(0x05), 'Loud', snrQ: 60));

    expect(c.directRepeaters, hasLength(max));
    expect(row(_key(0x05)), isNotNull);
  });

  test(
    'another radio starts with an empty list; the same radio keeps it',
    () async {
      c.handleFrameForTest(_selfInfo(_key(0xA0)));
      await c.sendRepeaterDiscovery();
      c.handleFrameForTest(_answer(_key(0x10), c.pendingDiscoverTag!));

      c.handleFrameForTest(_selfInfo(_key(0xA0)));
      expect(c.directRepeaters, hasLength(1), reason: 'same radio');

      c.handleFrameForTest(_selfInfo(_key(0xB0)));
      expect(c.directRepeaters, isEmpty);
      expect(c.discoverStartedAt, isNull);
    },
  );
}
