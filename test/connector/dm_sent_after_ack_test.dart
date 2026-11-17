import 'dart:convert';
import 'dart:typed_data';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/helpers/timeout_helper.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/models/message.dart';
import 'package:meshtrax/services/message_retry_service.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// A copy of a DM can still be on its way to the radio when the ACK for an
// earlier copy comes. Its RESP_CODE_SENT then matches no message waiting,
// and used to be handed to another contact's DM, which the radio's ACK
// for the copy then marked delivered.
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

  List<Uint8List> get dms =>
      frames.where((f) => f[0] == cmdSendTxtMsg).toList();
}

Uint8List _u32(int v) =>
    (ByteData(4)..setUint32(0, v, Endian.little)).buffer.asUint8List();

Uint8List _selfInfo(Uint8List pubKey) {
  final w = BytesBuilder();
  w.add([respCodeSelfInfo, advTypeChat, 20, 22]);
  w.add(pubKey);
  w.add(Uint8List(8)); // lat, lon
  w.add([0, 0, 0, 1]);
  w.add(_u32(910525000));
  w.add(_u32(62500));
  w.add([7, 5]);
  w.add(utf8.encode('GWQ'));
  return w.toBytes();
}

Uint8List _contactFrame(Uint8List pubKey, String name) {
  final w = BytesBuilder();
  w.addByte(respCodeContact);
  w.add(pubKey);
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

Uint8List _dm(Uint8List from, int secs, String text) => Uint8List.fromList([
  respCodeContactMsgRecvV3, 0x14, 0, 0,
  ...from.sublist(0, 6),
  0, // path len: direct
  txtTypePlain,
  ..._u32(secs),
  ...utf8.encode(text),
]);

Uint8List _sent(int ackHash) =>
    Uint8List.fromList([respCodeSent, 1, ..._u32(ackHash), ..._u32(5000)]);

Uint8List _confirmed(int ackHash) => Uint8List.fromList([
  pushCodeSendConfirmed,
  ..._u32(ackHash),
  ..._u32(2500),
]);

const _sos = 'SOS: hurt at the spring';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final selfKey = Uint8List.fromList(List.generate(32, (i) => 0xAB + i));
  final bobKey = Uint8List.fromList(List.generate(32, (i) => 0x5B + i));
  final carolKey = Uint8List.fromList(List.generate(32, (i) => 0x31 + i));

  late _Connector c;
  late MessageRetryService retry;
  late Contact bob;
  late Contact carol;

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 50));

  /// The ACK hash the radio reports for a CMD_SEND_TXT_MSG [frame]:
  /// [cmd][type][attempt][stamp x4][key prefix x6][text][0].
  int ackOf(Uint8List frame) => MessageRetryService.computeExpectedAckHash(
    ByteData.sublistView(frame, 3, 7).getUint32(0, Endian.little),
    frame[2],
    utf8.decode(frame.sublist(13, frame.length - 1)),
    selfKey,
  );

  Future<MessageStatus> status(Contact contact, String text) async =>
      (await c.loadMessagesFor(contact))
          .singleWhere((m) => m.isOutgoing && m.text == text)
          .status;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
    retry = MessageRetryService();
    c = _Connector()..initialize(retryService: retry);
    c.handleFrameForTest(_selfInfo(selfKey));
    // SELF_INFO's load of the empty store would replace the list below.
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await c.getContacts();
    c.handleFrameForTest(
      Uint8List.fromList([respCodeContactsStart, 2, 0, 0, 0]),
    );
    c.handleFrameForTest(_contactFrame(bobKey, 'Bob'));
    c.handleFrameForTest(_contactFrame(carolKey, 'Carol'));
    c.handleFrameForTest(
      Uint8List.fromList([respCodeEndOfContacts, 0, 0, 0, 0]),
    );
    bob = c.contacts.firstWhere((x) => x.name == 'Bob');
    carol = c.contacts.firstWhere((x) => x.name == 'Carol');
  });

  tearDown(() => retry.dispose());

  test('a garbled delivery receipt marks no DM delivered', () async {
    await c.sendMessage(bob, 'one');
    await settle();
    final bobAck = ackOf(c.dms.last);
    c.handleFrameForTest(_sent(bobAck));
    await settle();
    expect(await status(bob, 'one'), MessageStatus.sent);

    // Too short to hold an ACK hash: whose it was can't be told.
    c.handleFrameForTest(Uint8List.fromList([pushCodeSendConfirmed, 1, 2]));
    await settle();
    expect(await status(bob, 'one'), MessageStatus.sent);

    c.handleFrameForTest(_confirmed(bobAck));
    await settle();
    expect(await status(bob, 'one'), MessageStatus.delivered);
  });

  test(
    'a SENT for Bob\'s copy after his ACK leaves Carol\'s SOS waiting',
    () async {
      await c.sendMessage(bob, 'one');
      await settle();
      final bobAck = ackOf(c.dms.last);
      c.handleFrameForTest(_sent(bobAck));
      c.handleFrameForTest(_confirmed(bobAck));
      await settle();
      expect(await status(bob, 'one'), MessageStatus.delivered);

      await c.sendMessage(carol, _sos);
      await settle();
      final carolAck = ackOf(c.dms.last);
      expect(await status(carol, _sos), MessageStatus.pending);

      // A copy of Bob's DM reached the radio as his ACK came: its SENT,
      // then Bob's radio ACKing it.
      c.handleFrameForTest(_sent(bobAck));
      await settle();
      expect(
        await status(carol, _sos),
        MessageStatus.pending,
        reason: 'not hers, and no fallback marks her SOS sent',
      );
      c.handleFrameForTest(_confirmed(bobAck));
      await settle();
      expect(
        await status(carol, _sos),
        MessageStatus.pending,
        reason: 'Carol sent nothing back',
      );

      c.handleFrameForTest(_sent(carolAck));
      await settle();
      expect(await status(carol, _sos), MessageStatus.sent);
      c.handleFrameForTest(_confirmed(carolAck));
      await settle();
      expect(await status(carol, _sos), MessageStatus.delivered);
    },
  );

  // Bob's flood is parked (no repeater echoed it), and a DM from Carol has
  // just come in, so the resend a repeater wakes first sits out the 5 s
  // backoff. The test wakes it itself: a relayed packet would also start
  // the 3 s quiet wait, which runs on the wall clock.
  List<int> resendAttempts({required bool ackDuringWait}) {
    late List<int> attempts;
    fakeAsync((async) {
      c.sendMessage(bob, 'one');
      async.flushMicrotasks();
      final bobAck = ackOf(c.dms.single);
      c.handleFrameForTest(_sent(bobAck));
      // The echo wait and the cooldown, each a minute at most.
      async.elapse(const Duration(milliseconds: 2 * TimeoutHelper.maxMs + 1));
      expect(retry.hasMessagesInFlight, isFalse, reason: 'parked');
      expect(retry.hasMessagesWaiting, isTrue);

      c.handleFrameForTest(
        _dm(
          carolKey,
          DateTime.now().millisecondsSinceEpoch ~/ 1000,
          'on my way',
        ),
      );
      retry.noteRepeaterHeard();
      async.elapse(const Duration(seconds: 1));
      expect(c.dms, hasLength(1), reason: 'the resend is waiting');
      if (ackDuringWait) c.handleFrameForTest(_confirmed(bobAck));
      async.elapse(const Duration(seconds: 5));
      attempts = [for (final f in c.dms) f[2]];
    });
    return attempts;
  }

  test('a resend whose ACK comes while it waits for the radio is not sent', () {
    expect(resendAttempts(ackDuringWait: true), [0]);
    expect(retry.hasMessagesWaiting, isFalse);
  });

  test('a resend with no ACK during the wait goes out', () {
    expect(resendAttempts(ackDuringWait: false), [0, 4]);
  });
}
