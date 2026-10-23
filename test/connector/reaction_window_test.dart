import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/helpers/reaction_helper.dart';
import 'package:meshtrax/models/channel_message.dart';
import 'package:meshtrax/models/message.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/message_store.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Reactions in rooms (and channels) search only the last 48 h of arrivals
// and write back only their target; 1:1 chats still search everything.
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

Uint8List _selfInfo(Uint8List pubKey) {
  final w = BytesBuilder();
  w.add([respCodeSelfInfo, advTypeChat, 20, 22]);
  w.add(pubKey);
  w.add(Uint8List(8));
  w.add([0, 0, 0, 1]);
  w.add((ByteData(8)
        ..setUint32(0, 910525000, Endian.little)
        ..setUint32(4, 62500, Endian.little))
      .buffer
      .asUint8List());
  w.add([7, 5]);
  w.add(utf8.encode('GWQ'));
  return w.toBytes();
}

Uint8List _contactFrame(Uint8List pubKey, String name, int type) {
  final w = BytesBuilder();
  w.addByte(respCodeContact);
  w.add(pubKey);
  w.addByte(type);
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

Uint8List _msgFrame({
  required Uint8List sender,
  required String text,
  required int stampSecs,
  int txtType = txtTypePlain,
  Uint8List? author,
}) {
  final w = BytesBuilder();
  w.addByte(respCodeContactMsgRecvV3);
  w.add([0x14, 0, 0]);
  w.add(sender.sublist(0, 6));
  w.addByte(0xFF);
  w.addByte(txtType);
  w.add((ByteData(4)..setUint32(0, stampSecs, Endian.little))
      .buffer
      .asUint8List());
  if (author != null) w.add(author);
  w.add(utf8.encode(text));
  return w.toBytes();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final selfKey = Uint8List.fromList(List.generate(32, (i) => 0xAB + i));
  final chatKey = Uint8List.fromList(List.generate(32, (i) => 0x5B + i));
  final roomKey = Uint8List.fromList(List.generate(32, (i) => 0xC4 + i));

  late _Connector c;
  late MessageStore store;
  late String chatHex;
  late String roomHex;
  final now = DateTime.now();
  final nowSecs = now.millisecondsSinceEpoch ~/ 1000;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
    c = _Connector();
    c.handleFrameForTest(_selfInfo(selfKey));
    // SELF_INFO starts loading this radio's saved contacts; let that land
    // before the radio's own list does, or it replaces it.
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await c.getContacts();
    c.handleFrameForTest(
        Uint8List.fromList([respCodeContactsStart, 2, 0, 0, 0]));
    c.handleFrameForTest(_contactFrame(chatKey, 'WHALE', advTypeChat));
    c.handleFrameForTest(_contactFrame(roomKey, 'ROOM', advTypeRoom));
    c.handleFrameForTest(
        Uint8List.fromList([respCodeEndOfContacts, 0, 0, 0, 0]));
    chatHex = c.contacts.firstWhere((x) => x.name == 'WHALE').publicKeyHex;
    roomHex = c.contacts.firstWhere((x) => x.name == 'ROOM').publicKeyHex;
    store = MessageStore()..setPublicKeyHex = pubKeyToHex(selfKey);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(c.contacts.map((x) => x.name), containsAll(['WHALE', 'ROOM']));
  });

  /// A stored incoming message sent [age] ago (sender clock) that ARRIVED
  /// [age] ago.
  Future<Message> seed(String contactHex, String id, String text,
      Duration age) async {
    final sent = now.subtract(age);
    final msg = Message(
      senderKey: chatKey,
      text: text,
      timestamp: sent,
      isOutgoing: false,
      status: MessageStatus.delivered,
      messageId: '${sent.millisecondsSinceEpoch}_seed_$id',
    );
    await store.insertIfNew(contactHex, msg);
    await AppDatabase.instance.customStatement(
      'UPDATE contact_message_rows SET received_at_us = ? '
      'WHERE message_id = ?',
      [sent.microsecondsSinceEpoch, msg.messageId],
    );
    return msg;
  }

  Future<void> until(Future<bool> Function() done) async {
    for (var i = 0; i < 200; i++) {
      if (await done()) return;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    fail('timed out waiting for the reaction to settle');
  }

  Future<List<Map<String, Object?>>> rawRows() async => [
        for (final r in await AppDatabase.instance
            .customSelect(
              'SELECT id, message_id, received_at_us, unread_eligible, '
              'payload FROM contact_message_rows ORDER BY id',
            )
            .get())
          r.data,
      ];

  test('a 1:1 reaction still finds a month-old message', () async {
    final target =
        await seed(chatHex, 'old', 'see you in a month', const Duration(days: 30));
    c.handleFrameForTest(_msgFrame(
      sender: chatKey,
      text: MeshCoreConnector.contactReactionText(target, '👍'),
      stampSecs: nowSecs,
    ));
    await until(() async =>
        (await store.findByMessageId(chatHex, target.messageId))!
            .reactions
            .isNotEmpty);
    expect(
      (await store.findByMessageId(chatHex, target.messageId))!.reactions,
      {'👍': 1},
    );
  });

  test('a room reaction to a 3-day-old post parks', () async {
    final target =
        await seed(roomHex, 'old', 'room news from Monday', const Duration(days: 3));
    final reaction = MeshCoreConnector.contactReactionText(target, '👍');
    c.handleFrameForTest(_msgFrame(
      sender: roomKey,
      text: reaction,
      stampSecs: nowSecs,
      txtType: txtTypeSigned,
      author: chatKey.sublist(0, 4),
    ));
    await until(() async =>
        (await store.loadMessages(roomHex)).any((m) => m.text == reaction));
    expect(
      (await store.findByMessageId(roomHex, target.messageId))!.reactions,
      isEmpty,
    );
  });

  test('a room reaction to a recent post writes only that post', () async {
    await seed(roomHex, 'a', 'first', const Duration(hours: 5));
    final target = await seed(roomHex, 'b', 'second', const Duration(hours: 1));
    await seed(roomHex, 'c', 'third', const Duration(minutes: 5));
    final before = await rawRows();

    c.handleFrameForTest(_msgFrame(
      sender: roomKey,
      text: MeshCoreConnector.contactReactionText(target, '❤️'),
      stampSecs: nowSecs,
      txtType: txtTypeSigned,
      author: chatKey.sublist(0, 4),
    ));
    await until(() async =>
        (await store.findByMessageId(roomHex, target.messageId))!
            .reactions
            .isNotEmpty);

    final after = await rawRows();
    expect(after.length, before.length, reason: 'no stub row');
    for (var i = 0; i < before.length; i++) {
      final isTarget = before[i]['message_id'] == target.messageId;
      for (final column in ['id', 'received_at_us', 'unread_eligible']) {
        expect(after[i][column], before[i][column], reason: '$column, row $i');
      }
      expect(after[i]['payload'] == before[i]['payload'], !isTarget,
          reason: 'payload, row $i');
    }
    expect(
      (await store.findByMessageId(roomHex, target.messageId))!.reactions,
      {'❤️': 1},
    );
  });

  group('channelReactionTargetIndex', () {
    ChannelMessage row(String sender, String id, int wireMs) => ChannelMessage(
          senderName: sender,
          text: 'same words',
          timestamp: DateTime.fromMillisecondsSinceEpoch(wireMs),
          isOutgoing: false,
          status: ChannelMessageStatus.sent,
          messageId: '${wireMs}_x_$id',
        );

    test('the named sender wins a hash tie, as before', () {
      const wireMs = 1792700000000;
      final bob = row('Bob', 'b', wireMs);
      final alice = row('Alice', 'a', wireMs);
      final info = ReactionHelper.parseIncomingReaction(
        MeshCoreConnector.channelReactionText(bob, '👍'),
      )!;
      // Alice's identical message arrived later (newest last).
      expect(MeshCoreConnector.channelReactionTargetIndex([bob, alice], info),
          0);
    });

    test('a target outside the rows given is not found', () {
      final old = row('Bob', 'old', 1792000000000);
      final recent = row('Carol', 'new', 1792700000000);
      final info = ReactionHelper.parseIncomingReaction(
        MeshCoreConnector.channelReactionText(old, '👍'),
      )!;
      expect(MeshCoreConnector.channelReactionTargetIndex([recent], info), -1);
      expect(
          MeshCoreConnector.channelReactionTargetIndex([old, recent], info), 0);
    });
  });
}
