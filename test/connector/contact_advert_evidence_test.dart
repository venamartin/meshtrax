import 'dart:typed_data';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/contact_store.dart';
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

  test('a saved copy with no path takes the whole path from the row', () async {
    c.handleFrameForTest(_selfInfo());
    await pumpEventQueue(times: 200);
    c.handleFrameForTest([respCodeContactsStart, 0, 0, 0, 0]);
    c.handleFrameForTest([respCodeEndOfContacts, 0, 0, 0, 0]);
    autoAdd();
    c.handleFrameForTest(
      _heard(
        route: _routeFlood,
        path: const [0xAA, 0xBB],
        timestamp: _secondsAgo(const Duration(hours: 1)),
      ),
    );
    final store = ContactStore()
      ..setPublicKeyHex = pubKeyToHex(
        Uint8List.fromList(List.filled(32, 0x77)),
      );
    await store.saveContacts([
      Contact(
        publicKey: _key,
        name: 'NODE',
        type: advTypeChat,
        pathLength: -1,
        path: Uint8List(0),
        pathHashSize: 1,
        lastSeen: DateTime.now(),
      ),
    ]);
    await c.loadContactCache();
    expect(saved()!.inboundHopCount, isNull);

    await c.refreshContacts();
    c.handleFrameForTest([respCodeContactsStart, 1, 0, 0, 0]);
    c.handleFrameForTest(_record());
    c.handleFrameForTest([respCodeEndOfContacts, 0, 0, 0, 0]);

    expect(saved()!.inboundPath, [0xAA, 0xBB]);
    expect(saved()!.inboundHopCount, 2);
  });

  test(
    'a finished download forgets a contact the radio no longer has',
    () async {
      await savedWithFrozenRow();
      c.handleFrameForTest(
        _heard(
          route: _routeFlood,
          path: const [0xCC],
          timestamp: _secondsAgo(const Duration(minutes: 5)),
        ),
      );

      await c.getContacts();
      c.handleFrameForTest([respCodeContactsStart, 0, 0, 0, 0]);
      c.handleFrameForTest([respCodeEndOfContacts, 0, 0, 0, 0]);
      expect(saved(), isNull);

      await c.refreshContacts();
      c.handleFrameForTest([respCodeContactsStart, 1, 0, 0, 0]);
      c.handleFrameForTest(_record());
      c.handleFrameForTest([respCodeEndOfContacts, 0, 0, 0, 0]);

      expect(saved()!.inboundPath, [0xAA, 0xBB]);
    },
  );

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

    test('auto-add on: the radio refused it, so it stays unsaved', () {
      autoAdd(chat: true);
      c.handleFrameForTest(_record(code: pushCodeNewAdvert));

      expect(saved(), isNull);
      expect(row()!.isActive, isFalse);
      expect(listed().length, 1);
    });

    test('for a contact the list has: the radio no longer holds it', () async {
      autoAdd();
      await fullDownload(_record());
      c.handleFrameForTest(_record(code: pushCodeNewAdvert));

      expect(saved(), isNull);
      expect(row()!.isActive, isFalse);
      expect(listed().length, 1);
    });
  });

  group('a new node with auto-add on', () {
    Uint8List heard() => _heard(
          route: _routeFlood,
          path: const [0xAA],
          timestamp: _secondsAgo(const Duration(minutes: 1)),
        );
    bool asked() => c.sent.any((f) => f[0] == cmdGetContactByKey);

    setUp(() => autoAdd(chat: true));

    test('is only a heard row until the radio decides', () {
      c.handleFrameForTest(heard());
      expect(saved(), isNull);
      expect(row()!.isActive, isFalse);
      expect(listed().length, 1);
    });

    test('that the radio refuses stays a heard row, and is not looked up', () {
      c.handleFrameForTest(heard());
      c.handleFrameForTest(_record(code: pushCodeNewAdvert));
      expect(saved(), isNull);
      expect(row()!.isActive, isFalse);
      expect(asked(), isFalse);
    });

    test('that the radio saves is fetched and keeps its advert path', () {
      c.handleFrameForTest(heard());
      c.handleFrameForTest([pushCodeAdvert, ..._key]);
      expect(asked(), isTrue);

      c.handleFrameForTest(_record(lastmod: _secondsAgo(Duration.zero)));
      expect(saved()!.inboundPath, [0xAA]);
      expect(row()!.isActive, isTrue);
      expect(listed().length, 1);
    });

    test('first met through a share is dated by its advert', () {
      final node = _secondsAgo(const Duration(days: 2));
      c.handleFrameForTest(_heard(route: _routeTransportDirect, timestamp: node));
      c.handleFrameForTest([pushCodeAdvert, ..._key]);
      c.handleFrameForTest(
        _record(advertSecs: node, lastmod: _secondsAgo(Duration.zero)),
      );
      expect(saved()!.lastSeen.millisecondsSinceEpoch ~/ 1000, node);
      expect(saved()!.lastMessageAt.millisecondsSinceEpoch ~/ 1000, node);
    });

    test('saved during a download is fetched when it ends', () async {
      c.handleFrameForTest(heard());
      await c.getContacts();
      c.handleFrameForTest([respCodeContactsStart, 0, 0, 0, 0]);
      c.handleFrameForTest([pushCodeAdvert, ..._key]);
      expect(asked(), isFalse, reason: 'the radio refuses a second stream');

      c.handleFrameForTest([respCodeEndOfContacts, 0, 0, 0, 0]);
      expect(asked(), isTrue);
    });

    test('a saved node adding a row later is announced once by its row', () {
      c.handleFrameForTest(heard());
      c.handleFrameForTest([pushCodeAdvert, ..._key]);
      c.handleFrameForTest(_record());
      expect(listed().length, 1);
    });

    test('saved during a download and streamed anyway is not fetched', () async {
      c.handleFrameForTest(heard());
      await c.getContacts();
      c.handleFrameForTest([respCodeContactsStart, 1, 0, 0, 0]);
      c.handleFrameForTest([pushCodeAdvert, ..._key]);
      c.handleFrameForTest(_record());
      c.handleFrameForTest([respCodeEndOfContacts, 0, 0, 0, 0]);
      expect(asked(), isFalse);
    });
  });

  group('during a full download', () {
    Future<void> downloading() async {
      autoAdd();
      await fullDownload(_record());
      await c.getContacts();
      c.handleFrameForTest([respCodeContactsStart, 0, 0, 0, 0]);
      c.sent.clear();
    }

    test('one overwritten and added back stays listed', () async {
      await downloading();
      c.handleFrameForTest([pushCodeContactDeleted, ..._key]);
      expect(saved(), isNull);

      final added = c.importDiscoveredContact(row()!);
      await pumpEventQueue();
      c.handleFrameForTest([respCodeOk]);
      expect(await added, isTrue);

      c.handleFrameForTest([respCodeEndOfContacts, 0, 0, 0, 0]);
      expect(saved(), isNotNull);
    });

    test('one still on trial that the radio just re-saved is fetched', () async {
      await downloading();
      c.handleFrameForTest([pushCodeAdvert, ..._key]);
      expect(c.sent, isEmpty);

      c.handleFrameForTest([respCodeEndOfContacts, 0, 0, 0, 0]);

      expect(c.sent.map((f) => f[0]), contains(cmdGetContactByKey));
      expect(saved(), isNotNull, reason: 'its record is on the way');
    });

    test('the trial starts with the stream, not the request', () async {
      autoAdd();
      await fullDownload(_record());
      await c.getContacts();
      // A cache landing between the two is what the radio then checks.
      c.handleFrameForTest([respCodeContactsStart, 0, 0, 0, 0]);
      c.handleFrameForTest([respCodeEndOfContacts, 0, 0, 0, 0]);
      expect(saved(), isNull);
    });
  });

  group('wasDroppedByRadio', () {
    Contact asSaved() => Contact(
          publicKey: _key,
          name: 'NODE',
          type: advTypeChat,
          pathLength: -1,
          path: Uint8List(0),
          pathHashSize: 1,
          lastSeen: DateTime.now(),
        );

    test('not while the list is empty, with no row to go by', () {
      expect(c.contacts, isEmpty);
      expect(c.wasDroppedByRadio(asSaved()), isFalse);
    });

    test('not for a saved contact', () async {
      autoAdd();
      await fullDownload(_record());
      expect(c.wasDroppedByRadio(saved()!), isFalse);
    });

    test('once the radio overwrote it', () async {
      autoAdd();
      await fullDownload(_record());
      c.handleFrameForTest([pushCodeContactDeleted, ..._key]);
      expect(c.wasDroppedByRadio(asSaved()), isTrue);
    });
  });

  test('a stored row of a saved contact does not list it twice on connect',
      () async {
    c.handleFrameForTest(_selfInfo());
    await pumpEventQueue(times: 200);
    c.handleFrameForTest([respCodeContactsStart, 0, 0, 0, 0]);
    c.handleFrameForTest([respCodeEndOfContacts, 0, 0, 0, 0]);
    await savedWithFrozenRow();
    await pumpEventQueue(times: 200);

    final next = _Connector();
    next.handleFrameForTest(_selfInfo());
    await pumpEventQueue(times: 400);

    expect(next.isLoadingContacts, isTrue);
    expect(next.allContacts.where((x) => x.publicKeyHex == _hex), hasLength(1));
    expect(
      next.discoveredContacts.where((x) => x.publicKeyHex == _hex).single.isActive,
      isTrue,
    );
  });

  group('the lastmod on a contact', () {
    final heardAt = _secondsAgo(const Duration(hours: 5));

    int sentLastmod() {
      final write = c.sent.lastWhere((f) => f[0] == cmdAddUpdateContact);
      return ByteData.sublistView(
        write,
        write.length - 4,
      ).getUint32(0, Endian.little);
    }

    int seen() => saved()!.lastSeen.millisecondsSinceEpoch ~/ 1000;

    setUp(() async {
      autoAdd();
      await fullDownload(_record(lastmod: heardAt));
      expect(seen(), heardAt);
    });

    test('a route write dates the contact now on the radio', () async {
      await c.setContactPath(saved()!, Uint8List.fromList([0xAA]), 1, hashSize: 1);
      expect(sentLastmod(), closeTo(_secondsAgo(Duration.zero), 5));
    });

    test('the next sync does not read that write as hearing it', () async {
      await c.setContactPath(saved()!, Uint8List.fromList([0xAA]), 1, hashSize: 1);

      await fullDownload(_record(lastmod: sentLastmod()));

      expect(seen(), heardAt);
      expect(saved()!.appLastmodSecs, sentLastmod());
    });

    test('a restart still knows the write was not a hearing', () async {
      c.handleFrameForTest(_selfInfo());
      await pumpEventQueue(times: 200);
      c.handleFrameForTest([respCodeContactsStart, 1, 0, 0, 0]);
      c.handleFrameForTest(_record(lastmod: heardAt));
      c.handleFrameForTest([respCodeEndOfContacts, 0, 0, 0, 0]);
      await c.setContactPath(saved()!, Uint8List.fromList([0xAA]), 1, hashSize: 1);
      await pumpEventQueue(times: 200);
      final stamp = sentLastmod();

      await c.loadContactCache();
      expect(saved()!.appLastmodSecs, stamp);
    });

    test('the write does not move the time last heard from either', () async {
      final before = saved()!.lastMessageAt;
      await c.setContactPath(saved()!, Uint8List.fromList([0xAA]), 1, hashSize: 1);

      await fullDownload(_record(lastmod: sentLastmod()));

      expect(saved()!.lastMessageAt, before);
    });

    test('a frame sent before the write is not a hearing either', () async {
      await c.setContactPath(saved()!, Uint8List.fromList([0xAA]), 1, hashSize: 1);

      c.handleFrameForTest(_record(lastmod: sentLastmod() - 3600));

      expect(seen(), heardAt);
    });

    test('a later lastmod is the radio hearing it', () async {
      await c.setContactPath(saved()!, Uint8List.fromList([0xAA]), 1, hashSize: 1);
      final later = sentLastmod() + 60;

      await fullDownload(_record(lastmod: later));

      expect(saved()!.radioLastmodSecs, later);
      expect(
        saved()!.lastSeen.isAfter(
          DateTime.fromMillisecondsSinceEpoch(heardAt * 1000),
        ),
        isTrue,
      );
    });

    group('after the radio accepts a shared copy', () {
      final radioNow = _secondsAgo(Duration.zero);
      final advert = _secondsAgo(const Duration(hours: 2));

      void radioTakesShare() {
        c.handleFrameForTest(_heard(route: _routeTransportDirect, timestamp: advert));
        c.handleFrameForTest([pushCodeAdvert, ..._key]);
      }

      test('the record is fetched', () {
        c.sent.clear();
        radioTakesShare();
        expect(c.sent.map((f) => f[0]), contains(cmdGetContactByKey));
      });

      test('it does not look just heard, then or at the next sync', () async {
        radioTakesShare();
        final before = saved()!.lastMessageAt;
        c.handleFrameForTest(_record(advertSecs: advert, lastmod: radioNow));
        expect(seen(), heardAt);
        expect(saved()!.lastMessageAt, before);
        expect(saved()!.lastAdvertSecs, advert);

        await fullDownload(_record(advertSecs: advert, lastmod: radioNow));
        expect(seen(), heardAt);
      });

      test('a real advert afterwards counts as usual', () {
        radioTakesShare();
        c.handleFrameForTest(_record(advertSecs: advert, lastmod: radioNow));
        final at = _secondsAgo(const Duration(minutes: 1));
        c.handleFrameForTest(_heard(route: _routeFlood, timestamp: at));
        expect(seen(), at);
      });
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

    test('changes nothing about a saved contact that has no row', () async {
      autoAdd();
      await fullDownload(_record());
      expect(row(), isNull);
      c.handleFrameForTest(
        _heard(
          route: _routeFlood,
          path: const [0xCC],
          timestamp: _secondsAgo(const Duration(minutes: 5)),
        ),
      );
      final before = saved()!;

      c.handleFrameForTest(
        _heard(
          route: _routeTransportDirect,
          timestamp: _secondsAgo(const Duration(days: 30)),
        ),
      );

      expect(saved()!.inboundPath, [0xCC]);
      expect(saved()!.lastSeen, before.lastSeen);
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

    test('telling listeners about a contact it introduced', () async {
      autoAdd();
      var notified = 0;
      c.addListener(() => notified++);

      c.handleFrameForTest(
        _heard(
          route: _routeTransportDirect,
          timestamp: _secondsAgo(const Duration(days: 1)),
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 300));
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

    test('the radio\'s own contact record is not mistaken for it', () async {
      autoAdd();
      final old = _secondsAgo(const Duration(days: 30));
      c.handleFrameForTest(
        _heard(route: _routeTransportDirect, timestamp: old),
      );

      await fullDownload(_record(advertSecs: old));

      expect(saved(), isNotNull);
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
    final old = _secondsAgo(const Duration(days: 30));
    c.handleFrameForTest(_heard(route: _routeTransportDirect, timestamp: old));
    expect(row()!.lastSeen.millisecondsSinceEpoch ~/ 1000, old);

    await c.importDiscoveredContact(row()!);

    final write = c.sent.lastWhere((f) => f[0] == cmdAddUpdateContact);
    final lastmod = ByteData.sublistView(
      write,
      write.length - 4,
    ).getUint32(0, Endian.little);
    expect(lastmod, closeTo(_secondsAgo(Duration.zero), 5));
  });

  group('a shared copy of my own advert', () {
    Uint8List selfAdvert({required int route, required double lat}) {
      final frame = _heard(
        route: route,
        timestamp: _secondsAgo(const Duration(days: 30)),
        lat: lat,
        lon: 2,
      );
      final keyAt = frame.length - 4 - 8 - 1 - 64 - 4 - 32;
      frame.fillRange(keyAt, keyAt + 32, 0x77);
      return frame;
    }

    setUp(() => c.handleFrameForTest(_selfInfo()));

    test('leaves my position alone', () {
      c.handleFrameForTest(selfAdvert(route: _routeTransportDirect, lat: 40));
      expect(c.selfLatitude, 0);
    });

    test('while a real copy still updates it', () {
      c.handleFrameForTest(selfAdvert(route: _routeFlood, lat: 40));
      expect(c.selfLatitude, 40);
    });
  });

  group('an advert on a saved contact', () {
    Future<Contact?> cached() async {
      final store = ContactStore()
        ..setPublicKeyHex = pubKeyToHex(
          Uint8List.fromList(List.filled(32, 0x77)),
        );
      final rows = await store.loadContacts();
      return rows.where((x) => x.publicKeyHex == _hex).firstOrNull;
    }

    setUp(() async {
      c.handleFrameForTest(_selfInfo());
      await pumpEventQueue(times: 200);
      c.handleFrameForTest([respCodeContactsStart, 0, 0, 0, 0]);
      c.handleFrameForTest([respCodeEndOfContacts, 0, 0, 0, 0]);
      await savedWithFrozenRow();
      await pumpEventQueue(times: 200);
    });

    test('reaches the cache within ten seconds', () {
      fakeAsync((clock) {
        c.handleFrameForTest(
          _heard(
            route: _routeFlood,
            path: const [0xCC],
            timestamp: _secondsAgo(const Duration(minutes: 5)),
          ),
        );
        clock.elapse(const Duration(seconds: 11));
      });
      return pumpEventQueue(times: 200).then((_) async {
        expect((await cached())!.inboundPath, [0xCC]);
      });
    });

    test('a disconnect saves it, and does not empty the cache', () async {
      c.handleFrameForTest(
        _heard(
          route: _routeFlood,
          path: const [0xCC],
          timestamp: _secondsAgo(const Duration(minutes: 5)),
        ),
      );
      await c.disconnect();
      await pumpEventQueue(times: 200);
      expect((await cached())!.inboundPath, [0xCC]);
    });

    test('keeps the advert time the radio needs for a route write', () async {
      await fullDownload(_record(advertSecs: 1234));
      await pumpEventQueue(times: 200);
      expect((await cached())!.lastAdvertSecs, 1234);
    });
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
