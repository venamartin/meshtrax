import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Connector extends MeshCoreConnector {
  final sent = <Uint8List>[];

  @override
  bool get isConnected => true;

  @override
  Future<void> sendFrame(
    Uint8List data, {
    String? channelSendQueueId,
    bool expectsGenericAck = false,
  }) async {
    sent.add(data);
  }
}

const _routeTransportFlood = 0x00;
const _routeFlood = 0x01;
const _routeDirect = 0x02;
const _routeTransportDirect = 0x03;

final _key = Uint8List.fromList(List.generate(32, (i) => (0x40 + i) & 0xFF));
final _hex = pubKeyToHex(_key);

int _secondsAgo(Duration age) =>
    DateTime.now().subtract(age).millisecondsSinceEpoch ~/ 1000;

Uint8List _selfInfo() =>
    (BytesBuilder()
          ..add([respCodeSelfInfo, advTypeChat, 22, 22])
          ..add(Uint8List.fromList(List.filled(32, 0x77)))
          ..add(Uint8List(8))
          ..add(const [0, 0, 0, 1])
          ..add(
            (ByteData(8)
                  ..setUint32(0, 910525, Endian.little)
                  ..setUint32(4, 62500, Endian.little))
                .buffer
                .asUint8List(),
          )
          ..add(const [7, 5])
          ..add('GWQ'.codeUnits))
        .toBytes();

/// A contact record, as RESP_CODE_CONTACT or PUSH_CODE_NEW_ADVERT carries it.
Uint8List _record({
  int code = respCodeContact,
  int type = advTypeChat,
  double? lat,
  double? lon,
  int advertSecs = 1,
  int lastmod = 0,
}) {
  final position = ByteData(8);
  if (lat != null) {
    position.setInt32(0, (lat * 1e6).round(), Endian.little);
    position.setInt32(4, (lon! * 1e6).round(), Endian.little);
  }
  final name = Uint8List(maxNameSize)..setRange(0, 4, 'NODE'.codeUnits);
  return (BytesBuilder()
        ..addByte(code)
        ..add(_key)
        ..addByte(type)
        ..addByte(0)
        ..addByte(0xFF)
        ..add(Uint8List(maxPathSize))
        ..add(name)
        ..add(
          (ByteData(
            4,
          )..setUint32(0, advertSecs, Endian.little)).buffer.asUint8List(),
        )
        ..add(position.buffer.asUint8List())
        ..add(
          (ByteData(
            4,
          )..setUint32(0, lastmod, Endian.little)).buffer.asUint8List(),
        ))
      .toBytes();
}

/// A received advert, as PUSH_CODE_LOG_RX_DATA carries it.
Uint8List _heard({
  required int route,
  List<int> path = const [],
  required int timestamp,
  int type = advTypeChat,
  double? lat,
  double? lon,
}) {
  final payload = BytesBuilder()
    ..add(_key)
    ..add(
      (ByteData(4)..setInt32(0, timestamp, Endian.little)).buffer.asUint8List(),
    )
    ..add(Uint8List(64))
    ..addByte(type | 0x80 | (lat != null ? 0x10 : 0));
  if (lat != null) {
    payload.add(
      (ByteData(8)
            ..setInt32(0, (lat * 1e6).round(), Endian.little)
            ..setInt32(4, (lon! * 1e6).round(), Endian.little))
          .buffer
          .asUint8List(),
    );
  }
  payload.add('NODE'.codeUnits);
  final hasTransport =
      route == _routeTransportFlood || route == _routeTransportDirect;
  return (BytesBuilder()
        ..add([pushCodeLogRxData, 40, 0, route | (payloadTypeADVERT << 2)])
        ..add(hasTransport ? const [0, 0, 0, 0] : const <int>[])
        ..addByte(path.length)
        ..add(path)
        ..add(payload.toBytes()))
      .toBytes();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Connector c;
  Contact? saved() =>
      c.contacts.where((x) => x.publicKeyHex == _hex).firstOrNull;
  Contact? row() =>
      c.discoveredContacts.where((x) => x.publicKeyHex == _hex).firstOrNull;
  Iterable<Contact> listed() =>
      c.allContacts.where((x) => x.publicKeyHex == _hex);

  void autoAdd({bool chat = false}) =>
      c.handleFrameForTest([respCodeAutoAddConfig, chat ? autoAddChatFlag : 0]);

  Future<void> fullDownload(Uint8List record) async {
    await c.getContacts();
    c.handleFrameForTest([respCodeContactsStart, 1, 0, 0, 0]);
    c.handleFrameForTest(record);
    c.handleFrameForTest([respCodeEndOfContacts, 0, 0, 0, 0]);
  }

  /// Saved, with a discovered row from when the contact was first heard: the
  /// row stops updating from here on.
  Future<void> savedWithFrozenRow({double? lat, double? lon}) async {
    autoAdd();
    c.handleFrameForTest(
      _heard(
        route: _routeFlood,
        path: const [0xAA, 0xBB],
        timestamp: _secondsAgo(const Duration(days: 3)),
        lat: lat,
        lon: lon,
      ),
    );
    await fullDownload(_record(lat: lat, lon: lon));
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
    c = _Connector();
  });

  group('a full contact download', () {
    test(
      'keeps the latest advert path, not the path from first hearing',
      () async {
        await savedWithFrozenRow();
        expect(saved()!.inboundPath, [0xAA, 0xBB]);

        c.handleFrameForTest(
          _heard(
            route: _routeFlood,
            path: const [0xCC],
            timestamp: _secondsAgo(const Duration(minutes: 5)),
          ),
        );
        expect(saved()!.inboundPath, [0xCC]);
        expect(row()!.inboundPath, [0xAA, 0xBB]);

        await fullDownload(_record());

        expect(saved()!.inboundPath, [0xCC]);
        expect(saved()!.inboundHopCount, 1);
      },
    );

    test('with no live path uses the path from first hearing', () async {
      await savedWithFrozenRow();
      expect(saved()!.inboundHopCount, 2);
      expect(saved()!.inboundPathHashSize, 1);
    });

    test(
      "uses the radio's coordinates, not those from first hearing",
      () async {
        await savedWithFrozenRow(lat: 37.0, lon: -122.0);

        await fullDownload(_record(lat: 45.5, lon: -122.7));

        expect(saved()!.latitude, 45.5);
        expect(saved()!.longitude, -122.7);
      },
    );

    test('a record with no coordinates keeps the newest known ones', () async {
      await savedWithFrozenRow(lat: 37.0, lon: -122.0);
      c.handleFrameForTest(
        _heard(
          route: _routeFlood,
          timestamp: _secondsAgo(const Duration(minutes: 5)),
          lat: 45.5,
          lon: -122.7,
        ),
      );

      await fullDownload(_record());

      expect(saved()!.latitude, 45.5);
      expect(saved()!.longitude, -122.7);
    });

    test(
      'a record with no coordinates and no live ones uses the row',
      () async {
        autoAdd();
        c.handleFrameForTest(
          _heard(
            route: _routeFlood,
            timestamp: _secondsAgo(const Duration(days: 3)),
            lat: 37.0,
            lon: -122.0,
          ),
        );

        await fullDownload(_record());

        expect(saved()!.latitude, 37.0);
      },
    );

    test('leaves nothing behind for a later sync to bring back', () async {
      await savedWithFrozenRow();
      c.handleFrameForTest(
        _heard(
          route: _routeFlood,
          path: const [0xCC],
          timestamp: _secondsAgo(const Duration(minutes: 5)),
        ),
      );
      await fullDownload(_record());
      await c.removeContact(saved()!);

      await c.refreshContacts();
      c.handleFrameForTest([respCodeContactsStart, 1, 0, 0, 0]);
      c.handleFrameForTest(_record());
      c.handleFrameForTest([respCodeEndOfContacts, 0, 0, 0, 0]);

      expect(saved()!.inboundHopCount, isNull);
    });
  });

  test('a partial sync keeps the latest advert path', () async {
    await savedWithFrozenRow();
    c.handleFrameForTest(
      _heard(
        route: _routeFlood,
        path: const [0xCC],
        timestamp: _secondsAgo(const Duration(minutes: 5)),
      ),
    );

    await c.refreshContacts();
    c.handleFrameForTest([respCodeContactsStart, 1, 0, 0, 0]);
    c.handleFrameForTest(_record());
    c.handleFrameForTest([respCodeEndOfContacts, 0, 0, 0, 0]);

    expect(saved()!.inboundPath, [0xCC]);
    expect(saved()!.inboundHopCount, 1);
  });

  test(
    'after a restart, with no live path, the row gives the whole path',
    () async {
      c.handleFrameForTest(_selfInfo());
      await pumpEventQueue();
      await savedWithFrozenRow();
      await pumpEventQueue();

      c = _Connector();
      c.handleFrameForTest(_selfInfo());
      await pumpEventQueue(times: 200);
      expect(row()!.inboundHopCount, 2);

      c.handleFrameForTest([respCodeContactsStart, 1, 0, 0, 0]);
      c.handleFrameForTest(_record());
      c.handleFrameForTest([respCodeEndOfContacts, 0, 0, 0, 0]);

      expect(saved()!.inboundPath, [0xAA, 0xBB]);
      expect(saved()!.inboundHopCount, 2);
    },
  );

  group('PUSH_CODE_NEW_ADVERT', () {
    test('auto-add off: the contact stays listed, unsaved', () {
      autoAdd();
      c.handleFrameForTest(_record(code: pushCodeNewAdvert));

      expect(saved(), isNull);
      expect(row()!.isActive, isFalse);
      expect(listed().length, 1);
    });

    test('auto-add on: saved and listed once', () {
      autoAdd(chat: true);
      c.handleFrameForTest(_record(code: pushCodeNewAdvert));

      expect(saved(), isNotNull);
      expect(row()!.isActive, isTrue);
      expect(listed().length, 1);
    });

    test('for a contact already saved: listed once', () async {
      autoAdd();
      await fullDownload(_record());
      c.handleFrameForTest(_record(code: pushCodeNewAdvert));

      expect(row()!.isActive, isTrue);
      expect(listed().length, 1);
    });
  });

  group('a contact shared by a neighbour', () {
    test('changes nothing about a saved contact', () async {
      await savedWithFrozenRow(lat: 37.0, lon: -122.0);
      final before = saved()!;
      final nearbyBefore = c.directRepeaters.length;

      c.handleFrameForTest(
        _heard(
          route: _routeTransportDirect,
          timestamp: _secondsAgo(const Duration(days: 30)),
          lat: 10.0,
          lon: 10.0,
        ),
      );

      final after = saved()!;
      expect(after.inboundPath, before.inboundPath);
      expect(after.inboundHopCount, before.inboundHopCount);
      expect(after.lastSeen, before.lastSeen);
      expect(after.latitude, before.latitude);
      expect(c.directRepeaters.length, nearbyBefore);
    });

    test('changes nothing about an unsaved contact already heard', () {
      autoAdd();
      final heardAt = _secondsAgo(const Duration(hours: 1));
      c.handleFrameForTest(
        _heard(route: _routeFlood, path: const [0xAA], timestamp: heardAt),
      );
      final before = row()!;

      c.handleFrameForTest(
        _heard(
          route: _routeTransportDirect,
          timestamp: _secondsAgo(const Duration(days: 30)),
        ),
      );

      expect(row()!.inboundPath, before.inboundPath);
      expect(row()!.inboundHopCount, 1);
      expect(row()!.lastSeen, before.lastSeen);
    });

    test('introduces an unknown contact as not heard, at its own old time', () {
      autoAdd();
      final age = _secondsAgo(const Duration(days: 30));

      c.handleFrameForTest(
        _heard(route: _routeTransportDirect, timestamp: age),
      );

      expect(row()!.inboundHopCount, isNull);
      expect(row()!.inboundPathHashSize, isNull);
      expect(row()!.lastSeen.millisecondsSinceEpoch ~/ 1000, age);
      expect(row()!.clockCorrected, isFalse);
      expect(listed().length, 1);
    });

    test('a shared repeater is not a nearby repeater', () {
      autoAdd();
      c.handleFrameForTest(
        _heard(
          route: _routeTransportDirect,
          timestamp: _secondsAgo(const Duration(days: 1)),
          type: advTypeRepeater,
        ),
      );

      expect(row(), isNotNull);
      expect(c.directRepeaters, isEmpty);
    });

    test('telling listeners about a contact it introduced', () {
      autoAdd();
      var notified = 0;
      c.addListener(() => notified++);

      c.handleFrameForTest(
        _heard(
          route: _routeTransportDirect,
          timestamp: _secondsAgo(const Duration(days: 1)),
        ),
      );

      expect(notified, greaterThan(0));
    });

    test('a path on the frame means it was relayed, not shared', () {
      autoAdd();
      c.handleFrameForTest(
        _heard(
          route: _routeTransportDirect,
          path: const [0xAA],
          timestamp: _secondsAgo(const Duration(hours: 1)),
        ),
      );

      expect(row()!.inboundHopCount, 1);
    });

    test('a transport flood is a real hearing', () {
      autoAdd();
      c.handleFrameForTest(
        _heard(
          route: _routeTransportFlood,
          timestamp: _secondsAgo(const Duration(hours: 1)),
        ),
      );

      expect(row()!.inboundHopCount, 0);
    });
  });

  // The radio logs a packet, then handles it: for a key not in its table it
  // pushes the copy's own position and advert time, with its clock as lastmod.
  group('the radio frame that follows a share', () {
    final now = _secondsAgo(Duration.zero);
    Uint8List followUp(int advertSecs, {double? lat, double? lon}) => _record(
      code: pushCodeNewAdvert,
      advertSecs: advertSecs,
      lastmod: now,
      lat: lat,
      lon: lon,
    );

    test('changes nothing about an unsaved contact already heard', () {
      autoAdd();
      c.handleFrameForTest(
        _heard(
          route: _routeFlood,
          path: const [0xAA],
          timestamp: _secondsAgo(const Duration(hours: 1)),
          lat: 37.0,
          lon: -122.0,
        ),
      );
      final before = row()!;
      final old = _secondsAgo(const Duration(days: 30));

      c.handleFrameForTest(
        _heard(
          route: _routeTransportDirect,
          timestamp: old,
          lat: 10.0,
          lon: 10.0,
        ),
      );
      c.handleFrameForTest(followUp(old, lat: 10.0, lon: 10.0));

      expect(row()!.lastSeen, before.lastSeen);
      expect(row()!.latitude, 37.0);
      expect(row()!.longitude, -122.0);
      expect(row()!.inboundPath, [0xAA]);
    });

    test('leaves a contact it introduced at its own old time', () {
      autoAdd();
      final old = _secondsAgo(const Duration(days: 30));

      c.handleFrameForTest(
        _heard(route: _routeTransportDirect, timestamp: old),
      );
      c.handleFrameForTest(followUp(old));

      expect(row()!.lastSeen.millisecondsSinceEpoch ~/ 1000, old);
      expect(row()!.inboundHopCount, isNull);
    });

    test('a real hearing of the same advert is not mistaken for it', () {
      autoAdd();
      final at = _secondsAgo(const Duration(hours: 1));
      c.handleFrameForTest(_heard(route: _routeTransportDirect, timestamp: at));

      c.handleFrameForTest(
        _heard(route: _routeFlood, path: const [0xAA], timestamp: at),
      );
      c.handleFrameForTest(followUp(at));

      expect(row()!.lastSeen.millisecondsSinceEpoch ~/ 1000, now);
    });

    test('a different advert from the same contact is not mistaken for it', () {
      autoAdd();
      final old = _secondsAgo(const Duration(days: 30));
      c.handleFrameForTest(
        _heard(route: _routeTransportDirect, timestamp: old),
      );

      c.handleFrameForTest(followUp(old + 1));

      expect(row()!.lastSeen.millisecondsSinceEpoch ~/ 1000, now);
    });
  });

  group('the local discovered time', () {
    Uint8List pushAdvert() => Uint8List.fromList([pushCodeAdvert, ..._key]);

    test('a share of an unknown contact does not set it', () {
      autoAdd();
      c.handleFrameForTest(
        _heard(
          route: _routeTransportDirect,
          timestamp: _secondsAgo(const Duration(days: 30)),
        ),
      );
      expect(c.getLocalDiscoveredTime(_hex), isNull);
    });

    test('the key-only push after a share does not set it', () async {
      autoAdd();
      await fullDownload(_record());
      c.handleFrameForTest(
        _heard(
          route: _routeTransportDirect,
          timestamp: _secondsAgo(const Duration(days: 30)),
        ),
      );
      c.handleFrameForTest(pushAdvert());
      expect(c.getLocalDiscoveredTime(_hex), isNull);
    });

    test('a real hearing sets it, and so does the push after one', () async {
      autoAdd();
      await fullDownload(_record());
      c.handleFrameForTest(pushAdvert());
      expect(c.getLocalDiscoveredTime(_hex), isNotNull);

      await c.removeContact(saved()!);
      c.handleFrameForTest(
        _heard(
          route: _routeFlood,
          timestamp: _secondsAgo(const Duration(minutes: 1)),
        ),
      );
      expect(c.getLocalDiscoveredTime(_hex), isNotNull);
    });
  });

  group('a contact deleted during a full download', () {
    final deletes = <String, Future<void> Function()>{
      'removeContact': () => c.removeContact(saved()!),
      'purgeContacts': () => c.purgeContacts(includesFavorites: true),
      'removeRepeaters': () => c.removeRepeaters(),
    };
    for (final MapEntry(key: name, value: delete) in deletes.entries) {
      test('by $name leaves nothing to bring back', () async {
        autoAdd();
        c.handleFrameForTest(
          _heard(
            route: _routeFlood,
            path: const [0xAA, 0xBB],
            timestamp: _secondsAgo(const Duration(days: 3)),
            type: advTypeRepeater,
            lat: 37.0,
            lon: -122.0,
          ),
        );
        final record = _record(type: advTypeRepeater, lat: 37.0, lon: -122.0);
        await fullDownload(record);

        await c.getContacts();
        c.handleFrameForTest([respCodeContactsStart, 1, 0, 0, 0]);
        c.handleFrameForTest(record);
        await delete();
        c.handleFrameForTest(
          _heard(
            route: _routeFlood,
            path: const [0xCC],
            timestamp: _secondsAgo(const Duration(minutes: 1)),
            type: advTypeRepeater,
          ),
        );
        c.handleFrameForTest(
          _record(code: pushCodeNewAdvert, type: advTypeRepeater),
        );

        expect(row()!.inboundPath, [0xCC]);
        expect(row()!.latitude, isNull);
      });
    }
  });

  test(
    'a route the app wrote stays marked once the choice is cleared',
    () async {
      autoAdd();
      await fullDownload(_record());
      await c.setPathOverride(
        saved()!,
        pathLen: 1,
        pathBytes: Uint8List.fromList(const [0xA1]),
      );
      expect(c.wroteContactPath(saved()!), isTrue);

      await c.setPathOverride(saved()!, pathLen: null);

      expect(saved()!.pathOverride, isNull);
      expect(saved()!.path, [0xA1]);
      expect(c.wroteContactPath(saved()!), isTrue);
    },
  );

  test('adding a contact heard long ago dates it now on the radio', () async {
    autoAdd();
    c.handleFrameForTest(
      _heard(
        route: _routeFlood,
        timestamp: _secondsAgo(const Duration(days: 30)),
      ),
    );

    await c.importDiscoveredContact(row()!);

    final write = c.sent.lastWhere((f) => f[0] == cmdAddUpdateContact);
    final lastmod = ByteData.sublistView(
      write,
      write.length - 4,
    ).getUint32(0, Endian.little);
    expect(lastmod, closeTo(_secondsAgo(Duration.zero), 5));
  });

  test('a zero-hop advert sent to us is a real hearing', () async {
    await savedWithFrozenRow();
    final at = _secondsAgo(const Duration(minutes: 1));

    c.handleFrameForTest(_heard(route: _routeDirect, timestamp: at));

    expect(saved()!.inboundHopCount, 0);
    expect(saved()!.inboundPath, isEmpty);
    expect(saved()!.lastSeen.millisecondsSinceEpoch ~/ 1000, at);
  });
}
