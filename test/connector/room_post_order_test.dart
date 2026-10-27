import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/models/message.dart';
import 'package:meshtrax/services/message_retry_service.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// A room server gives up on a member after three unanswered pushes and
// starts again when that member next posts. The posts it held back then
// arrive after our post, though they were made before it. Field case
// 2026-10-26: a 07:32 post sat above the previous evening's posts, under a
// "Mon, 26 October" divider followed by "Sun, 25 October".
class _Connector extends MeshCoreConnector {
  final frames = <Uint8List>[];

  @override
  bool get isConnected => true;

  @override
  Future<void> sendFrame(
    Uint8List data, {
    String? channelSendQueueId,
    bool expectsGenericAck = false,
  }) async {
    frames.add(data);
  }
}

final _roomKey = Uint8List.fromList(List.generate(32, (i) => 0xA3 + i));
final _chatKey = Uint8List.fromList(List.generate(32, (i) => 0x5B + i));
final _selfKey = Uint8List.fromList(List.generate(32, (i) => 0x11 + i));

Message _theirs(String text, DateTime stamp) => Message(
      senderKey: _roomKey,
      text: text,
      timestamp: stamp,
      isOutgoing: false,
      status: MessageStatus.delivered,
      fourByteRoomContactKey: Uint8List.fromList([0xC1, 0xC2, 0xC3, 0xC4]),
    );

Message _ours(String text, DateTime sent) => Message(
      senderKey: _roomKey,
      text: text,
      timestamp: sent,
      isOutgoing: true,
    );

List<String> _order(List<Message> byArrival, {int? skewSecs}) =>
    MeshCoreConnector.roomPostOrder(byArrival, skewSecs: skewSecs)
        .map((m) => m.text)
        .toList();

Uint8List _u32(int v) => Uint8List.fromList(
    [v & 0xFF, (v >> 8) & 0xFF, (v >> 16) & 0xFF, (v >> 24) & 0xFF]);

Uint8List _contactFrame(Uint8List pubKey, String name, {required int type}) {
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

Uint8List _selfInfo(Uint8List pubKey) {
  final w = BytesBuilder();
  w.addByte(respCodeSelfInfo);
  w.addByte(advTypeChat);
  w.addByte(22);
  w.addByte(22);
  w.add(pubKey);
  w.add(_u32(0));
  w.add(_u32(0));
  w.add([0, 0, 0, 0]);
  w.add(_u32(920000000));
  w.add(_u32(250000));
  w.add([11, 5]);
  w.add('ME'.codeUnits);
  w.addByte(0);
  return w.toBytes();
}

/// A post the room server pushes: signed, stamped by the server's clock.
Uint8List _roomPost(int stampSecs, String text) => Uint8List.fromList([
      respCodeContactMsgRecvV3,
      40, 0, 0, // snr, reserved
      ..._roomKey.sublist(0, 6),
      0, // path len: direct
      txtTypeSigned,
      ..._u32(stampSecs),
      0xC1, 0xC2, 0xC3, 0xC4, // author prefix
      ...text.codeUnits,
      0,
    ]);

Uint8List _dm(Uint8List from, int stampSecs, String text) =>
    Uint8List.fromList([
      respCodeContactMsgRecvV3,
      40, 0, 0,
      ...from.sublist(0, 6),
      0,
      txtTypePlain,
      ..._u32(stampSecs),
      ...text.codeUnits,
      0,
    ]);

/// LOGIN_OK (14-byte form) carrying the room server's clock.
Uint8List _loginOk(int serverClockSecs) => Uint8List.fromList([
      pushCodeLoginSuccess,
      0, // not admin
      ..._roomKey.sublist(0, 6),
      ..._u32(serverClockSecs),
      2, // permissions: member
      1, // firmware level
    ]);

Future<void> settle() async {
  for (var i = 0; i < 40; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('roomPostOrder', () {
    final sent = DateTime(2026, 10, 26, 7, 32);

    test('posts the server held back go above the post that released them',
        () {
      final rows = [
        _theirs('Test watsonville', DateTime(2026, 10, 25, 16, 16)),
        _ours('are you in Watsonville?', sent),
        _theirs('what you doing', DateTime(2026, 10, 25, 16, 30)),
        _theirs('Small Craft Advisory', DateTime(2026, 10, 25, 20, 1)),
        _theirs('Coastal Flood Advisory', DateTime(2026, 10, 25, 20, 36)),
      ];
      const expected = [
        'Test watsonville',
        'what you doing',
        'Small Craft Advisory',
        'Coastal Flood Advisory',
        'are you in Watsonville?',
      ];
      expect(_order(rows, skewSecs: 0), expected);
      expect(_order(rows), expected,
          reason: 'hours apart, an unmeasured clock cannot be the reason');
    });

    test('a reply the server stamped after our post stays below it', () {
      final rows = [
        _ours('ping', sent),
        _theirs('pong', sent.add(const Duration(seconds: 20))),
      ];
      expect(_order(rows, skewSecs: 0), ['ping', 'pong']);
      expect(_order(rows), ['ping', 'pong']);
    });

    test('a slow room clock is read through the measured skew', () {
      // The room's clock runs three minutes slow.
      const skew = -180;
      final rows = [
        _ours('ping', sent),
        _theirs('held', sent.subtract(const Duration(seconds: 60 + 180))),
        _theirs('pong', sent.add(const Duration(seconds: 20 - 180))),
      ];
      expect(_order(rows, skewSecs: skew), ['held', 'ping', 'pong']);
      // Unmeasured, a stamp must be five minutes older than our post to
      // move: the reply must not go above the post it answers, and the
      // cost is a post held back for under five minutes staying below.
      expect(_order(rows), ['ping', 'held', 'pong']);
    });

    test('a stamp the ingest rewrote never moves a post', () {
      // A dead RTC's stamp, rewritten to its arrival by the ingest; the
      // message id still carries the stamp the wire had.
      final broken = _theirs('pong', DateTime(2024, 5, 15))
          .copyWith(timestamp: sent.add(const Duration(seconds: 5)));
      final rows = [_ours('ping', sent), broken];
      expect(_order(rows, skewSecs: 0), ['ping', 'pong']);
      expect(_order(rows), ['ping', 'pong']);
    });

    test('a post here before we sent ours stays above it, whatever its stamp',
        () {
      // The room's clock runs a minute fast.
      final rows = [
        _theirs('early', sent.add(const Duration(minutes: 1))),
        _ours('ping', sent),
      ];
      expect(_order(rows, skewSecs: 0), ['early', 'ping']);
    });

    test('each side keeps its own order; the two interleave by time', () {
      final rows = [
        _ours('first', sent),
        _ours('second', sent.add(const Duration(minutes: 10))),
        _theirs('b1', sent.subtract(const Duration(minutes: 30))),
        _theirs('b2', sent.add(const Duration(minutes: 5))),
      ];
      expect(_order(rows, skewSecs: 0), ['b1', 'first', 'b2', 'second']);
    });

    test('a conversation with only one side is returned as it came', () {
      final rows = [
        _theirs('a', sent),
        _theirs('b', sent.subtract(const Duration(hours: 1))),
      ];
      expect(identical(MeshCoreConnector.roomPostOrder(rows), rows), isTrue);
    });
  });

  group('watchConversation', () {
    late _Connector c;
    var nextHash = 0x2000;

    Contact byName(String n) => c.allContacts.firstWhere((x) => x.name == n);
    int nowSecs() => DateTime.now().millisecondsSinceEpoch ~/ 1000;

    Future<void> send(Contact contact, String text) async {
      await c.sendMessage(contact, text);
      await settle();
      final hash = nextHash++;
      c.handleFrameForTest(
          Uint8List.fromList([respCodeSent, 1, ..._u32(hash), ..._u32(0)]));
      await settle();
      c.handleFrameForTest(
          Uint8List.fromList([pushCodeSendConfirmed, ..._u32(hash), ..._u32(2500)]));
      await settle();
    }

    Future<void> hear(Uint8List frame) async {
      c.handleFrameForTest(frame);
      await settle();
    }

    Future<List<String>> shown(Contact contact) async =>
        (await c.watchConversation(contact).first).map((m) => m.text).toList();

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      PrefsManager.reset();
      await PrefsManager.initialize();
      AppDatabase.useInMemoryForTesting();
      c = _Connector();
      c.initialize(retryService: MessageRetryService());
      c.handleFrameForTest(_selfInfo(_selfKey));
      await settle();
      await c.getContacts();
      c.handleFrameForTest(
        Uint8List.fromList([respCodeContactsStart, 2, 0, 0, 0]),
      );
      c.handleFrameForTest(_contactFrame(_roomKey, 'ROOM', type: advTypeRoom));
      c.handleFrameForTest(_contactFrame(_chatKey, 'ALICE', type: advTypeChat));
      c.handleFrameForTest(
        Uint8List.fromList([respCodeEndOfContacts, 0, 0, 0, 0]),
      );
      await settle();
    });

    test('a room shows its held-back posts above ours; rows keep arrival',
        () async {
      final room = byName('ROOM');
      await send(room, 'are you in Watsonville?');
      final now = nowSecs();
      await hear(_roomPost(now - 15 * 3600, 'what you doing'));
      await hear(_roomPost(now - 11 * 3600, 'Small Craft Advisory'));
      await hear(_roomPost(now - 10 * 3600, 'Coastal Flood Advisory'));

      expect(await shown(room), [
        'what you doing',
        'Small Craft Advisory',
        'Coastal Flood Advisory',
        'are you in Watsonville?',
      ]);
      expect((await c.loadMessagesFor(room)).map((m) => m.text), [
        'are you in Watsonville?',
        'what you doing',
        'Small Craft Advisory',
        'Coastal Flood Advisory',
      ], reason: 'unread and read marks go by the stored arrival order');
    });

    test('with the room clock measured, a post held two minutes moves too',
        () async {
      final room = byName('ROOM');
      await hear(_loginOk(nowSecs()));
      await send(room, 'mine');
      await hear(_roomPost(nowSecs() - 120, 'two minutes before'));
      expect(await shown(room), ['two minutes before', 'mine']);
    });

    test('unmeasured, a post held two minutes stays below ours', () async {
      final room = byName('ROOM');
      await send(room, 'mine');
      await hear(_roomPost(nowSecs() - 120, 'two minutes before'));
      expect(await shown(room), ['mine', 'two minutes before']);
    });

    test('a 1:1 conversation keeps arrival order', () async {
      final alice = byName('ALICE');
      await send(alice, 'hi');
      await hear(_dm(_chatKey, nowSecs() - 3600, 'sent an hour ago'));
      expect(await shown(alice), ['hi', 'sent an hour ago']);
    });

    // A window that did not change is not passed on, so an open chat has
    // nothing to rebuild when another chat's message lands (owner,
    // 2026-10-26: glitches scrolling).
    test('another chat\'s message passes nothing on', () async {
      final alice = byName('ALICE');
      await send(alice, 'hi');
      final seen = <List<Message>>[];
      final sub = c.watchConversation(alice).listen(seen.add);
      await settle();
      expect(seen, hasLength(1));

      await hear(_roomPost(nowSecs(), 'room chatter'));
      expect(seen, hasLength(1));
      await hear(_dm(_chatKey, nowSecs(), 'for me'));
      expect(seen.last.map((m) => m.text), ['hi', 'for me']);
      await sub.cancel();
    });

    test('a login that measures the room clock re-orders on the next write',
        () async {
      final room = byName('ROOM');
      await send(room, 'mine');
      await hear(_roomPost(nowSecs() - 120, 'two minutes before'));
      final seen = <List<String>>[];
      final sub = c
          .watchConversation(room)
          .listen((rows) => seen.add([for (final m in rows) m.text]));
      await settle();
      expect(seen.last, ['mine', 'two minutes before']);

      // The login changes no row of the room; another chat's message runs
      // the query again, and the order the measured clock gives goes on.
      await hear(_loginOk(nowSecs()));
      await hear(_dm(_chatKey, nowSecs(), 'unrelated'));
      expect(seen.last, ['two minutes before', 'mine']);
      await sub.cancel();
    });
  });
}
