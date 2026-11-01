import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/models/message.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// The radio takes a DM off its queue when it hands it over. A DM from a sender
// missing from the list was re-parsed before any contact frame could arrive,
// then lost for good, with no message and no notification.
class _Connector extends MeshCoreConnector {
  final sent = <Uint8List>[];
  bool failGetContacts = false;
  List<int> get commands => [for (final f in sent) f[0]];

  @override
  bool get isConnected => true;

  @override
  Future<void> sendFrame(
    Uint8List data, {
    String? channelSendQueueId,
    bool expectsGenericAck = false,
  }) async {
    if (failGetContacts && data[0] == cmdGetContacts) throw Exception('down');
    sent.add(data);
  }
}

final _self = Uint8List.fromList(List.filled(32, 0x77));
final _sender = Uint8List.fromList(List.generate(32, (i) => 0x20 + i));
final _other = Uint8List.fromList(List.generate(32, (i) => 0x60 + i));

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

Uint8List _contact(Uint8List key, String name) {
  final w = BytesBuilder();
  w.addByte(respCodeContact);
  w.add(key);
  w.addByte(advTypeChat);
  w.addByte(0);
  w.addByte(0xFF);
  w.add(Uint8List(maxPathSize));
  final nameBytes = Uint8List(maxNameSize);
  nameBytes.setRange(0, name.length, name.codeUnits);
  w.add(nameBytes);
  w.add(Uint8List.fromList([1, 0, 0, 0]));
  w.add(Uint8List(8));
  return w.toBytes();
}

Uint8List _dm(Uint8List sender, String text, {int secs = 1752854400}) {
  final w = BytesBuilder();
  w.add([respCodeContactMsgRecvV3, 0x14, 0, 0]);
  w.add(sender.sublist(0, 6));
  w.addByte(0xFF);
  w.addByte(txtTypePlain);
  w.add((ByteData(4)..setUint32(0, secs, Endian.little)).buffer.asUint8List());
  w.add(utf8.encode(text));
  return w.toBytes();
}

final _start = [respCodeContactsStart, 1, 0, 0, 0];
final _end = [respCodeEndOfContacts, 0, 0, 0, 0];

Contact _asContact(Uint8List key) => Contact(
      publicKey: key,
      name: 'x',
      type: advTypeChat,
      pathLength: -1,
      path: Uint8List(0),
      pathHashSize: 1,
      lastSeen: DateTime.now(),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Connector c;

  Future<List<Message>> stored(Uint8List key) async {
    await pumpEventQueue(times: 200);
    return c.watchConversation(_asContact(key)).first;
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
    c = _Connector();
    c.handleFrameForTest(_selfInfo());
    await pumpEventQueue(times: 200);
    c.handleFrameForTest([respCodeContactsStart, 0, 0, 0, 0]);
    c.handleFrameForTest(_end);
    await pumpEventQueue(times: 200);
    c.sent.clear();
  });

  test('is stored once the sender arrives in the download it asks for',
      () async {
    c.handleFrameForTest(_dm(_sender, 'hello'));
    expect(c.commands, contains(cmdGetContacts));
    expect(
      c.sent.lastWhere((f) => f[0] == cmdGetContacts).length,
      1,
      reason: 'with a since, a sender with an older lastmod would not come',
    );
    expect(await stored(_sender), isEmpty);

    c.handleFrameForTest(_start);
    c.handleFrameForTest(_contact(_sender, 'Ann'));
    c.handleFrameForTest(_end);

    expect((await stored(_sender)).single.text, 'hello');
  });

  test('during a download waits for its end and asks for nothing', () async {
    await c.getContacts();
    c.handleFrameForTest(_start);
    c.sent.clear();

    c.handleFrameForTest(_dm(_sender, 'hello'));
    expect(c.commands, isNot(contains(cmdGetContacts)));

    c.handleFrameForTest(_contact(_sender, 'Ann'));
    c.handleFrameForTest(_end);

    expect((await stored(_sender)).single.text, 'hello');
  });

  test('keeps the order the radio handed them over', () async {
    c.handleFrameForTest(_dm(_sender, 'first', secs: 1752854400));
    c.handleFrameForTest(_dm(_sender, 'second', secs: 1752854460));
    c.handleFrameForTest(_start);
    c.handleFrameForTest(_contact(_sender, 'Ann'));
    c.handleFrameForTest(_end);

    expect(
      (await stored(_sender)).map((m) => m.text),
      ['first', 'second'],
    );
  });

  test('a second copy of the same message makes no second row', () async {
    c.handleFrameForTest(_dm(_sender, 'hello'));
    c.handleFrameForTest(_dm(_sender, 'hello'));
    c.handleFrameForTest(_start);
    c.handleFrameForTest(_contact(_sender, 'Ann'));
    c.handleFrameForTest(_end);

    expect(await stored(_sender), hasLength(1));
  });

  test('a since pass that misses the sender asks for the whole list', () async {
    await c.getContacts(since: 100, preserveExisting: true);
    c.handleFrameForTest(_start);
    c.handleFrameForTest(_dm(_sender, 'hello'));
    c.sent.clear();

    c.handleFrameForTest(_end);
    expect(c.sent.single.length, 1, reason: 'no since in the request');
    expect(c.commands, [cmdGetContacts]);

    c.handleFrameForTest(_start);
    c.handleFrameForTest(_contact(_sender, 'Ann'));
    c.handleFrameForTest(_end);
    expect((await stored(_sender)).single.text, 'hello');
  });

  test('a whole list without the sender drops it and carries on', () async {
    c.handleFrameForTest(_dm(_sender, 'lost'));
    c.handleFrameForTest(_start);
    c.handleFrameForTest(_end);
    c.sent.clear();

    c.handleFrameForTest(_contact(_sender, 'Ann'));
    expect(await stored(_sender), isEmpty);
    expect(c.commands, isNot(contains(cmdGetContacts)));
  });

  group('a sender the radio no longer holds', () {
    Future<void> lostOnce() async {
      c.handleFrameForTest(_dm(_sender, 'first'));
      c.handleFrameForTest(_start);
      c.handleFrameForTest(_end);
      c.sent.clear();
    }

    test('costs one download, not one per queued message', () async {
      await lostOnce();
      c.handleFrameForTest(_dm(_sender, 'second'));
      expect(c.commands, isNot(contains(cmdGetContacts)));
    });

    test('with no heard row is logged and gone', () async {
      await lostOnce();
      expect(await stored(_sender), isEmpty);
    });

    test('with a heard row is filed under it', () async {
      c.handleFrameForTest(_contact(_sender, 'Ann'));
      c.handleFrameForTest([pushCodeContactDeleted, ..._sender]);
      expect(c.contacts, isEmpty);
      c.sent.clear();

      c.handleFrameForTest(_dm(_sender, 'first'));
      c.handleFrameForTest(_start);
      c.handleFrameForTest(_end);
      c.handleFrameForTest(_dm(_sender, 'second'));

      expect(
        (await stored(_sender)).map((m) => m.text),
        ['first', 'second'],
      );
    });

    test('comes back if the radio saves it again', () async {
      await lostOnce();
      c.handleFrameForTest(_contact(_sender, 'Ann'));
      c.handleFrameForTest(_dm(_sender, 'back'));
      expect((await stored(_sender)).single.text, 'back');
    });
  });

  test('a record still on its way keeps the message for it', () async {
    await c.getContacts();
    c.handleFrameForTest(_start);
    c.handleFrameForTest([pushCodeAdvert, ..._sender]);
    c.handleFrameForTest(_dm(_sender, 'hello'));
    c.handleFrameForTest(_end);
    expect(c.commands, contains(cmdGetContactByKey));

    c.handleFrameForTest(_contact(_sender, 'Ann'));
    expect((await stored(_sender)).single.text, 'hello');
  });

  test('holds only so many', () async {
    await c.getContacts();
    c.handleFrameForTest(_start);
    for (var i = 0; i < 40; i++) {
      c.handleFrameForTest(_dm(_sender, 'm$i', secs: 1752854400 + i));
    }
    c.handleFrameForTest(_contact(_sender, 'Ann'));
    c.handleFrameForTest(_end);

    final rows = await stored(_sender);
    expect(rows, hasLength(32));
    expect(rows.first.text, 'm8', reason: 'the oldest make way');
  });

  test('a sender already listed goes straight through', () async {
    c.handleFrameForTest(_contact(_other, 'Bob'));
    c.handleFrameForTest(_dm(_other, 'hi'));
    expect(c.commands, isNot(contains(cmdGetContacts)));
    expect((await stored(_other)).single.text, 'hi');
  });

  group('during a queue drain', () {
    setUp(() async {
      c.markChannelsVerifiedForTest();
      await c.syncQueuedMessages(force: true);
      expect(c.commands, contains(cmdSyncNextMessage));
      c.sent.clear();
    });

    test('a listed sender moves on to the next message', () async {
      c.handleFrameForTest(_contact(_other, 'Bob'));
      c.handleFrameForTest(_dm(_other, 'hi'));
      expect(c.commands, [cmdSyncNextMessage]);
    });

    test('a failed fetch restarts it', () async {
      c.failGetContacts = true;
      c.handleFrameForTest(_dm(_sender, 'hello'));
      await pumpEventQueue(times: 50);
      expect(c.commands, contains(cmdSyncNextMessage));
    });

    test('an unknown sender pauses it until the list is in', () async {
      c.handleFrameForTest(_dm(_sender, 'hello'));
      expect(c.commands, [cmdGetContacts]);

      c.handleFrameForTest(_start);
      c.handleFrameForTest(_contact(_sender, 'Ann'));
      c.sent.clear();
      c.handleFrameForTest(_end);
      await pumpEventQueue(times: 200);

      expect((await stored(_sender)).single.text, 'hello');
      expect(c.commands, [cmdSyncNextMessage]);
    });
  });
}
