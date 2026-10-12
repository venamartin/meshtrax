import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/services/message_retry_service.dart';
import 'package:meshtrax/services/storage_service.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// A room server answers a posted message with a plain ACK, never a PATH, so
// a post delivered by flood teaches the radio no route. The connector then
// sends one login (by flood, since there is no route), which the room does
// answer with a PATH return. The login only goes out when nothing else is
// in flight, since its RESP_CODE_SENT would otherwise be taken for a
// message's.
class _Connector extends MeshCoreConnector {
  final frames = <Uint8List>[];
  // Reply to CMD_GET_CONTACT_BY_KEY with this frame, when set.
  Uint8List? contactSnapshot;

  @override
  bool get isConnected => true;

  @override
  Future<void> sendFrame(
    Uint8List data, {
    String? channelSendQueueId,
    bool expectsGenericAck = false,
  }) async {
    frames.add(data);
    switch (data[0]) {
      case cmdRemoveContact:
      case cmdAddUpdateContact:
        scheduleMicrotask(
          () => handleFrameForTest(Uint8List.fromList([respCodeOk])),
        );
      case cmdGetContactByKey:
        final snapshot = contactSnapshot;
        if (snapshot != null) {
          scheduleMicrotask(() => handleFrameForTest(snapshot));
        }
    }
  }

  List<Uint8List> ofKind(int code) =>
      frames.where((f) => f[0] == code).toList();
}

Uint8List _contactFrame(
  Uint8List pubKey,
  String name, {
  int type = advTypeRoom,
  int pathLen = 0xFF,
  List<int> path = const [],
}) {
  final w = BytesBuilder();
  w.addByte(respCodeContact);
  w.add(pubKey);
  w.addByte(type);
  w.addByte(0);
  w.addByte(pathLen);
  final pathBytes = Uint8List(maxPathSize);
  pathBytes.setRange(0, path.length, path);
  w.add(pathBytes);
  final nameBytes = Uint8List(maxNameSize);
  nameBytes.setRange(0, name.length, name.codeUnits);
  w.add(nameBytes);
  w.add(Uint8List.fromList([1, 0, 0, 0]));
  w.add(Uint8List(8));
  return w.toBytes();
}

Uint8List _u32(int v) =>
    Uint8List.fromList([v & 0xFF, (v >> 8) & 0xFF, (v >> 16) & 0xFF, (v >> 24) & 0xFF]);

Uint8List _sent(int ackHash) =>
    Uint8List.fromList([respCodeSent, 1, ..._u32(ackHash), ..._u32(0)]);

Uint8List _confirmed(int ackHash) =>
    Uint8List.fromList([pushCodeSendConfirmed, ..._u32(ackHash), ..._u32(2500)]);

Future<void> settle() async {
  for (var i = 0; i < 40; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final roomKey = Uint8List.fromList(List.generate(32, (i) => 0xA3 + i));
  final chatKey = Uint8List.fromList(List.generate(32, (i) => 0x5B + i));

  late _Connector c;
  var nextHash = 0x1000;

  Contact byName(String n) => c.allContacts.firstWhere((x) => x.name == n);

  /// Sends [text] and plays the radio's part: SENT, then the ACK.
  Future<void> deliverByFlood(Contact contact, String text) async {
    final before = c.ofKind(cmdSendTxtMsg).length;
    await c.sendMessage(contact, text);
    await settle();
    expect(c.ofKind(cmdSendTxtMsg).length, equals(before + 1));
    final hash = nextHash++;
    c.handleFrameForTest(_sent(hash));
    await settle();
    c.handleFrameForTest(_confirmed(hash));
    await settle();
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
    c = _Connector();
    c.initialize(retryService: MessageRetryService());
    await c.getContacts();
    c.handleFrameForTest(
      Uint8List.fromList([respCodeContactsStart, 2, 0, 0, 0]),
    );
    c.handleFrameForTest(_contactFrame(roomKey, 'ROOM'));
    c.handleFrameForTest(_contactFrame(chatKey, 'ALICE', type: advTypeChat));
    c.handleFrameForTest(
      Uint8List.fromList([respCodeEndOfContacts, 0, 0, 0, 0]),
    );
    c.frames.clear();
  });

  test('a flooded post to a room is followed by one login, by flood', () async {
    final room = byName('ROOM');
    expect(room.pathLength, equals(-1));

    await deliverByFlood(room, 'hi room');

    final logins = c.ofKind(cmdSendLogin);
    expect(logins.length, equals(1));
    expect(logins.single.sublist(1, 33), equals(roomKey));
    expect(logins.single.sublist(33), equals([0]),
        reason: 'no remembered password: a blank login, the room knows us');

    // Within the cooldown a second flooded post does not log in again.
    await deliverByFlood(room, 'hi again');
    expect(c.ofKind(cmdSendLogin).length, equals(1));
  });

  test('the remembered password is used when there is one', () async {
    await StorageService().saveRepeaterPassword(
      byName('ROOM').publicKeyHex,
      'hello',
    );
    await deliverByFlood(byName('ROOM'), 'hi');
    final login = c.ofKind(cmdSendLogin).single;
    expect(String.fromCharCodes(login.sublist(33, 38)), equals('hello'));
  });

  test('a chat contact gets no login', () async {
    await deliverByFlood(byName('ALICE'), 'hi alice');
    expect(c.ofKind(cmdSendLogin), isEmpty);
  });

  test('a room on Always flood gets no login', () async {
    await c.setPathOverride(byName('ROOM'), pathLen: -1);
    c.frames.clear();
    await deliverByFlood(byName('ROOM'), 'hi');
    expect(c.ofKind(cmdSendLogin), isEmpty);
  });

  test('nothing is sent while another message is in flight', () async {
    final room = byName('ROOM');
    await c.sendMessage(room, 'first');
    await c.sendMessage(room, 'second');
    await settle();
    expect(c.ofKind(cmdSendTxtMsg).length, equals(1),
        reason: 'one message per contact on the air at a time');

    final first = nextHash++;
    c.handleFrameForTest(_sent(first));
    await settle();
    c.handleFrameForTest(_confirmed(first));
    await settle();
    expect(c.ofKind(cmdSendLogin), isEmpty,
        reason: 'the second message has started');
    expect(c.ofKind(cmdSendTxtMsg).length, equals(2));

    final second = nextHash++;
    c.handleFrameForTest(_sent(second));
    await settle();
    c.handleFrameForTest(_confirmed(second));
    await settle();
    expect(c.ofKind(cmdSendLogin).length, equals(1),
        reason: 'the skipped relearn did not use up the cooldown');
  });

  test('history reload re-adds the room with the radio\'s route', () async {
    final room = byName('ROOM');
    c.contactSnapshot = _contactFrame(
      roomKey,
      'ROOM',
      pathLen: 0x42,
      path: const [0x10, 0x20, 0x30, 0x40],
    );

    expect(await c.resetRoomSyncCursor(room), isTrue);

    final readd = c.ofKind(cmdAddUpdateContact).single;
    expect(readd[35], equals(0x42), reason: 'the radio\'s route, not the cache');
    expect(readd.sublist(36, 40), equals([0x10, 0x20, 0x30, 0x40]));
  });
}
