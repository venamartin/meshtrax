import 'dart:convert';
import 'dart:typed_data';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/models/channel_message.dart';
import 'package:meshtrax/models/message.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/channel_message_store.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// After a queue drain gives up, what the radio still holds comes in on a
// later drain and is read as LIVE: a text sent at 14:00 that waited until
// 16:30 shows at 16:30, newest at the bottom. It keeps that place and time
// (a wrong clock never moves a message); when its sender's time is
// believable it also gets "sent 14:00 by its clock" (Martin, 2026-11-16).
class _Radio extends MeshCoreConnector {
  final sent = <Uint8List>[];

  // disconnect() and the drop handler leave this alone, so a test can be
  // back on the radio straight after.
  bool linked = true;

  @override
  bool get isConnected => linked;

  @override
  Future<void> sendFrame(
    Uint8List data, {
    String? channelSendQueueId,
    bool expectsGenericAck = false,
  }) async {
    sent.add(data);
  }
}

final _selfKey = Uint8List(32)..fillRange(0, 32, 0x11);
final _bobKey = Uint8List(32)..fillRange(0, 32, 0x22);
final _psk = Uint8List.fromList(List.generate(16, (i) => 0x30 + i));

Uint8List _selfInfo() {
  final w = BytesBuilder();
  w.add([respCodeSelfInfo, advTypeChat, 20, 22]);
  w.add(_selfKey);
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
  w.add(utf8.encode('Base'));
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

// RESP_CODE_CHANNEL_INFO has the same layout as CMD_SET_CHANNEL.
Uint8List _channelInfo({int slot = 1, String name = '#trip'}) =>
    Uint8List.fromList([
      respCodeChannelInfo,
      ...buildSetChannelFrame(
        slot,
        name,
        Uint8List.fromList([for (final b in _psk) b + slot]),
      ).sublist(1),
    ]);

/// [t] in whole seconds, as the wire carries a send time.
Uint8List _wire(DateTime t) =>
    (ByteData(4)..setUint32(0, t.millisecondsSinceEpoch ~/ 1000, Endian.little))
        .buffer
        .asUint8List();

/// What the wire keeps of [t]: whole seconds.
DateTime _secs(DateTime t) => DateTime.fromMillisecondsSinceEpoch(
  t.millisecondsSinceEpoch ~/ 1000 * 1000,
);

/// A channel message as the queue hands it over:
/// [code][snr][rsv][rsv][channel_idx][path_len][txt_type][ts x4][text].
Uint8List _queued(String senderAndText, DateTime sent, {int slot = 1}) {
  final w = BytesBuilder();
  w.add([respCodeChannelMsgRecvV3, 0, 0, 0, slot, 2, txtTypePlain]);
  w.add(_wire(sent));
  w.add(utf8.encode(senderAndText));
  return w.toBytes();
}

/// A DM from Bob as the queue hands it over, arrived direct.
Uint8List _dm(String text, DateTime sent) {
  final w = BytesBuilder();
  w.add([respCodeContactMsgRecvV3, 0x14, 0, 0]);
  w.add(_bobKey.sublist(0, 6));
  w.add([0xFF, txtTypePlain]);
  w.add(_wire(sent));
  w.add(utf8.encode(text));
  return w.toBytes();
}

DateTime _ago(Duration d) => DateTime.now().subtract(d);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Radio c;

  Future<void> handshake() async {
    // Below 14: no companion CLI, so no wifi probe once the sync completes.
    c.handleFrameForTest([respCodeDeviceInfo, 9, 0, 0]);
    c.handleFrameForTest(_selfInfo());
    await pumpEventQueue(times: 200);
    c.handleFrameForTest([respCodeContactsStart, 1, 0, 0, 0]);
    c.handleFrameForTest(_contact(_bobKey, 'Bob'));
    c.handleFrameForTest([respCodeEndOfContacts, 0, 0, 0, 0]);
    await pumpEventQueue(times: 200);
    c.handleFrameForTest(_channelInfo());
    await pumpEventQueue(times: 200);
    c.markChannelsVerifiedForTest();
    c.sent.clear();
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
    c = _Radio();
    await handshake();
  });

  /// A message the chat held before this connection: what the channel's
  /// floor is made of.
  Future<void> heldBefore(String sender, String text, DateTime sent) async {
    final store = ChannelMessageStore()
      ..setPublicKeyHex = pubKeyToHex(_selfKey);
    await store.insertIfNew(
      c.channels.single.idKey,
      ChannelMessage(
        senderName: sender,
        text: text,
        timestamp: sent,
        isOutgoing: false,
        status: ChannelMessageStatus.sent,
        channelIndex: 1,
      ),
    );
  }

  /// A new message is queued, its drain gets no answer to 4 requests and
  /// gives up, and 30 s later the retry starts to drain what was left.
  void giveUpThenRetry() {
    fakeAsync((async) {
      c.handleFrameForTest([pushCodeMsgWaiting]);
      async.flushMicrotasks();
      expect(c.isSyncingQueuedMessages, isTrue);
      for (var i = 0; i < 4; i++) {
        c.fireQueueSyncTimeoutForTest();
      }
      expect(c.isSyncingQueuedMessages, isFalse, reason: 'the drain gave up');
      async.elapse(const Duration(seconds: 30));
      expect(c.isSyncingQueuedMessages, isTrue, reason: 'the retry');
    });
  }

  /// One frame off the queue. Out of fake time: a database write does not
  /// finish in it.
  Future<void> read(Uint8List frame) async {
    c.handleFrameForTest(frame);
    await pumpEventQueue(times: 200);
  }

  Future<void> queueEmpty() =>
      read(Uint8List.fromList([respCodeNoMoreMessages]));

  /// A drain that is not after a give-up: MSG_WAITING, the frames, the end.
  Future<void> drain(List<Uint8List> frames) async {
    await read(Uint8List.fromList([pushCodeMsgWaiting]));
    expect(c.isSyncingQueuedMessages, isTrue);
    for (final f in frames) {
      await read(f);
    }
    await queueEmpty();
  }

  Future<List<ChannelMessage>> channelRows() =>
      c.loadChannelMessagesFor(c.channels.single);

  Future<ChannelMessage> channelRow(String text) async =>
      (await channelRows()).singleWhere((m) => m.text == text);

  Future<List<Message>> dmRows() =>
      c.watchConversation(c.contacts.single).first;

  Future<Message> dmRow(String text) async =>
      (await dmRows()).singleWhere((m) => m.text == text);

  /// Shown at the moment it was read, as a live message with an old time.
  void expectShownNow(DateTime shown, DateTime readFrom) {
    expect(shown.isBefore(readFrom), isFalse, reason: 'shown at $shown');
    expect(shown.isAfter(DateTime.now()), isFalse, reason: 'shown at $shown');
  }

  group('a channel message the radio held past a give-up', () {
    test('stays at the bottom, shown when it got here, with the time its '
        'sender claimed', () async {
      await heldBefore('Ann', 'Leaving camp', _ago(const Duration(days: 1)));
      giveUpThenRetry();
      final claim = _ago(const Duration(minutes: 150));
      final readFrom = _secs(DateTime.now());
      await read(_queued('Bob: Water at the spring', claim));
      await queueEmpty();

      final row = await channelRow('Water at the spring');
      expectShownNow(row.timestamp, readFrom);
      expect(row.claimedAt, _secs(claim));
      expect((await channelRows()).map((m) => m.text), [
        'Leaving camp',
        'Water at the spring',
      ], reason: 'its place is where it got here, as before');
    });

    test('a reply keeps the line too', () async {
      await heldBefore('Ann', 'Leaving camp', _ago(const Duration(days: 1)));
      giveUpThenRetry();
      final claim = _ago(const Duration(minutes: 150));
      await read(_queued("Bob: @[Ann]\n>Leaving ca..\nWe'll wait", claim));
      await queueEmpty();

      final row = await channelRow("We'll wait");
      expect(row.replyToSenderName, 'Ann');
      expect(row.claimedAt, _secs(claim));
    });

    test('in a channel with no history, the 30-day cap decides', () async {
      giveUpThenRetry();
      final week = _ago(const Duration(days: 6));
      final readFrom = _secs(DateTime.now());
      await read(_queued('Bob: Last week', week));
      await read(_queued('Bob: Last month', _ago(const Duration(days: 31))));
      await queueEmpty();

      final lastWeek = await channelRow('Last week');
      expectShownNow(lastWeek.timestamp, readFrom);
      expect(lastWeek.claimedAt, _secs(week));
      final lastMonth = await channelRow('Last month');
      expectShownNow(lastMonth.timestamp, readFrom);
      expect(lastMonth.claimedAt, isNull);
    });

    test('a claim from before what the chat held gets no line, and shows '
        'as today', () async {
      await heldBefore('Ann', 'Leaving camp', _ago(const Duration(hours: 1)));
      giveUpThenRetry();
      final readFrom = _secs(DateTime.now());
      await read(
        _queued('Bob: Before the floor', _ago(const Duration(hours: 3))),
      );
      await read(
        _queued('Bob: Dead clock', DateTime.fromMillisecondsSinceEpoch(1000)),
      );
      await read(
        _queued(
          'Bob: Fast clock',
          DateTime.now().add(const Duration(minutes: 30)),
        ),
      );
      await queueEmpty();

      for (final text in ['Before the floor', 'Dead clock', 'Fast clock']) {
        final row = await channelRow(text);
        expectShownNow(row.timestamp, readFrom);
        expect(row.claimedAt, isNull, reason: text);
      }
    });

    test(
      'the floor keeps the same 10 minutes of slack as the backlog rule',
      () async {
        final floor = _ago(const Duration(hours: 2));
        await heldBefore('Ann', 'Leaving camp', floor);
        giveUpThenRetry();
        final inSlack = floor.subtract(const Duration(minutes: 9));
        await read(_queued('Bob: Within the slack', inSlack));
        await read(
          _queued(
            'Bob: Past the slack',
            floor.subtract(const Duration(minutes: 11)),
          ),
        );
        await queueEmpty();

        expect(
          (await channelRow('Within the slack')).claimedAt,
          _secs(inSlack),
        );
        expect((await channelRow('Past the slack')).claimedAt, isNull);
      },
    );

    test('the floor is what the chat held before this connection: what came '
        'in since, my own sends included, does not raise it', () async {
      await heldBefore('Ann', 'Leaving camp', _ago(const Duration(days: 1)));
      // The first drain brings in an hour-old message, then gives up.
      await read(Uint8List.fromList([pushCodeMsgWaiting]));
      await read(_queued('Ann: At the pass', _ago(const Duration(hours: 1))));
      fakeAsync((async) {
        for (var i = 0; i < 4; i++) {
          c.fireQueueSyncTimeoutForTest();
        }
        async.elapse(const Duration(seconds: 30));
        expect(c.isSyncingQueuedMessages, isTrue, reason: 'the retry');
      });
      await c.sendChannelMessage(c.channels.single, 'Heading down');
      await pumpEventQueue(times: 200);
      final claim = _ago(const Duration(hours: 2));
      await read(_queued('Bob: Two hours ago', claim));
      await queueEmpty();

      expect((await channelRow('Two hours ago')).claimedAt, _secs(claim));
    });

    test('a fresh one gets no line', () async {
      giveUpThenRetry();
      final justNow = _ago(const Duration(seconds: 20));
      await read(_queued('Bob: Just now', justNow));
      await queueEmpty();

      final row = await channelRow('Just now');
      expect(row.timestamp, _secs(justNow));
      expect(row.claimedAt, isNull);
    });

    test(
      'one held for a slot the app does not know yet keeps the line',
      () async {
        giveUpThenRetry();
        // Slot 2 is not in the channel list: the message waits for its
        // CHANNEL_INFO, and the drain reaches its end meanwhile.
        final claim = _ago(const Duration(minutes: 90));
        await read(_queued('Bob: Held for the slot', claim, slot: 2));
        await queueEmpty();
        c.handleFrameForTest(_channelInfo(slot: 2, name: '#camp'));
        await pumpEventQueue(times: 200);

        final camp = c.channels.singleWhere((ch) => ch.index == 2);
        final rows = await c.loadChannelMessagesFor(camp);
        expect(rows.map((m) => m.text), ['Held for the slot']);
        expect(rows.single.claimedAt, _secs(claim));
      },
    );
  });

  group('no line', () {
    test('once a drain has reached the end, an old live claim is a broken '
        'clock, as before', () async {
      giveUpThenRetry();
      await queueEmpty();
      final readFrom = _secs(DateTime.now());
      await drain([
        _queued('Bob: Slow clock', _ago(const Duration(minutes: 150))),
        _dm('Slow clock too', _ago(const Duration(minutes: 150))),
      ]);

      final row = await channelRow('Slow clock');
      expectShownNow(row.timestamp, readFrom);
      expect(row.claimedAt, isNull);
      expect((await dmRow('Slow clock too')).claimedAt, isNull);
    });

    test('in the first drain: the backlog shows its own time', () async {
      final claim = _ago(const Duration(minutes: 150));
      await drain([
        _queued('Bob: While you were away', claim),
        _dm('Away too', claim),
      ]);

      final row = await channelRow('While you were away');
      expect(row.timestamp, _secs(claim));
      expect(row.claimedAt, isNull);
      expect((await dmRow('Away too')).claimedAt, isNull);
    });

    test('on my own messages', () async {
      giveUpThenRetry();
      await c.sendChannelMessage(c.channels.single, 'Heading down');
      await c.sendMessage(c.contacts.single, 'See you there');
      await pumpEventQueue(times: 200);
      // My own name on a queued channel copy is my own echo: dropped, as
      // before, whatever its time.
      await read(_queued('Base: Heading down', _ago(const Duration(hours: 2))));
      await queueEmpty();

      final mine = await channelRows();
      expect(mine.map((m) => m.text), ['Heading down']);
      expect(mine.single.isOutgoing, isTrue);
      expect(mine.single.claimedAt, isNull);
      final dm = await dmRow('See you there');
      expect(dm.isOutgoing, isTrue);
      expect(dm.claimedAt, isNull);
    });
  });

  group('a DM the radio held past a give-up', () {
    test(
      'stands where it got here, keeps its time, and gets the line',
      () async {
        await drain([_dm('Morning', _ago(const Duration(hours: 5)))]);
        giveUpThenRetry();
        final claim = _ago(const Duration(minutes: 150));
        await read(_dm('Running low on water', claim));
        await queueEmpty();

        final rows = await dmRows();
        expect(rows.map((m) => m.text), ['Morning', 'Running low on water']);
        // The DM rule believes 30 days either way, so its time is the claim,
        // as before: the line tells a reader that it waited.
        expect(rows.last.timestamp, _secs(claim));
        expect(rows.last.claimedAt, _secs(claim));
      },
    );

    test('past the 30-day cap: shown as today, no line', () async {
      giveUpThenRetry();
      final readFrom = _secs(DateTime.now());
      await read(_dm('Old clock', _ago(const Duration(days: 40))));
      await read(
        _dm('Fast clock', DateTime.now().add(const Duration(hours: 1))),
      );
      await queueEmpty();

      for (final text in ['Old clock', 'Fast clock']) {
        final row = await dmRow(text);
        expectShownNow(row.timestamp, readFrom);
        expect(row.claimedAt, isNull, reason: text);
      }
    });

    test('a fresh one gets no line', () async {
      giveUpThenRetry();
      await read(_dm('Just now', _ago(const Duration(seconds: 20))));
      await queueEmpty();
      expect((await dmRow('Just now')).claimedAt, isNull);
    });
  });

  group('leaving the radio starts over', () {
    Future<void> backOnTheRadio() async {
      c.linked = true;
      await handshake();
    }

    for (final how in ['disconnect', 'a BLE drop']) {
      test(
        '$how: what a new connection reads outside a drain gets no line',
        () async {
          giveUpThenRetry();
          c.linked = false;
          if (how == 'disconnect') {
            await c.disconnect();
          } else {
            c.handleBleDropForTest();
          }
          await backOnTheRadio();
          await read(_dm('Late DM', _ago(const Duration(minutes: 150))));
          await read(
            _queued('Bob: Late post', _ago(const Duration(minutes: 150))),
          );

          expect((await dmRow('Late DM')).claimedAt, isNull);
          expect((await channelRow('Late post')).claimedAt, isNull);
        },
      );

      test('$how: the next connection takes its own floor', () async {
        // The first connection brings in a message an hour old.
        await drain([
          _queued('Ann: At the pass', _ago(const Duration(hours: 1))),
        ]);
        c.linked = false;
        if (how == 'disconnect') {
          await c.disconnect();
        } else {
          c.handleBleDropForTest();
        }
        await backOnTheRadio();
        // On the next, a drain gives up and a leftover claims 90 minutes
        // ago: before what the chat held when this connection's sync began.
        giveUpThenRetry();
        await read(
          _queued('Bob: Before the pass', _ago(const Duration(minutes: 90))),
        );
        await queueEmpty();

        expect((await channelRow('Before the pass')).claimedAt, isNull);
      });
    }
  });

  group('heldClaimToShow', () {
    final now = DateTime(2026, 11, 16, 16, 30);
    DateTime? held(DateTime claim, {DateTime? floor}) =>
        MeshCoreConnector.heldClaimToShow(claim, now, floor: floor);

    test('a claim the live rule keeps needs no line', () {
      expect(held(now.subtract(const Duration(seconds: 90))), isNull);
      expect(held(now.add(const Duration(seconds: 30))), isNull);
    });

    test('a claim the live rule rewrites, and the backlog rule believes', () {
      final claim = DateTime(2026, 11, 16, 14);
      expect(held(claim), claim);
      expect(held(claim, floor: DateTime(2026, 11, 15, 20)), claim);
    });

    test('a claim the backlog rule would not believe', () {
      final floor = DateTime(2026, 11, 16, 15);
      expect(held(DateTime(2026, 11, 16, 14), floor: floor), isNull);
      expect(held(now.subtract(const Duration(days: 31))), isNull);
      expect(held(DateTime.fromMillisecondsSinceEpoch(0)), isNull);
      expect(held(now.add(const Duration(minutes: 5))), isNull);
    });
  });
}
