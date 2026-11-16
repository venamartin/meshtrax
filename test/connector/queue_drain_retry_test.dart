import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:fake_async/fake_async.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// A queue drain gives up when the radio answers neither a request nor its 3
// retries, 5 s each: an ESP32 radio drops a reply when its BLE send queue is
// full. The radio pushes MSG_WAITING only when it queues a new message, so
// what it still held, DMs and SOS included, stayed there until someone sent
// another: on a quiet trip, for hours.
class _Radio extends MeshCoreConnector {
  final sent = <Uint8List>[];
  int get syncRequests => sent.where((f) => f[0] == cmdSyncNextMessage).length;

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
Uint8List _channelInfo() => Uint8List.fromList([
  respCodeChannelInfo,
  ...buildSetChannelFrame(1, '#trip', _psk).sublist(1),
]);

/// Now, in whole seconds, as the wire carries a send time.
Uint8List _sentNow() {
  final secs = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  return (ByteData(4)..setUint32(0, secs, Endian.little)).buffer.asUint8List();
}

/// A channel message as the queue hands it over:
/// [code][snr][rsv][rsv][channel_idx][path_len][txt_type][ts x4][text].
Uint8List _queued(String senderAndText) {
  final w = BytesBuilder();
  w.add([respCodeChannelMsgRecvV3, 0, 0, 0, 1, 2, txtTypePlain]);
  w.add(_sentNow());
  w.add(utf8.encode(senderAndText));
  return w.toBytes();
}

/// A DM from Bob as the queue hands it over, arrived direct.
Uint8List _dm(String text) {
  final w = BytesBuilder();
  w.add([respCodeContactMsgRecvV3, 0x14, 0, 0]);
  w.add(_bobKey.sublist(0, 6));
  w.add([0xFF, txtTypePlain]);
  w.add(_sentNow());
  w.add(utf8.encode(text));
  return w.toBytes();
}

/// A channel datagram, a queued message with nothing to store:
/// [code][snr][rsv][rsv][channel_idx][path_len][type x2][len][data].
Uint8List _datagram() {
  final w = BytesBuilder();
  w.add([respCodeChannelDataRecv, 0x14, 0, 0, 1, 0xFF]);
  w.add([0x54, 0xFF, 3, 1, 2, 3]);
  return w.toBytes();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Radio c;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
    c = _Radio();
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
  });

  /// A new message is queued: the radio pushes MSG_WAITING.
  void msgWaiting(FakeAsync async) {
    c.handleFrameForTest([pushCodeMsgWaiting]);
    async.flushMicrotasks();
    expect(c.isSyncingQueuedMessages, isTrue);
  }

  /// The radio answers none of the drain's 4 requests.
  void giveUp() {
    expect(c.isSyncingQueuedMessages, isTrue);
    for (var i = 0; i < 4; i++) {
      c.fireQueueSyncTimeoutForTest();
    }
    expect(c.isSyncingQueuedMessages, isFalse, reason: 'the drain gave up');
  }

  /// Back on the radio with its channels read: a retry left from before
  /// would start a drain now.
  void backOnTheRadio() {
    c.linked = true;
    c.markChannelsVerifiedForTest();
    c.sent.clear();
  }

  test('a give-up tries again in 30 s, and that drain brings in what the '
      'radio kept', () async {
    fakeAsync((async) {
      msgWaiting(async);
      giveUp();
      c.sent.clear();
      async.elapse(const Duration(seconds: 29));
      expect(c.syncRequests, 0);
      async.elapse(const Duration(seconds: 1));
      expect(c.isSyncingQueuedMessages, isTrue);
      expect(c.syncRequests, 1);
    });

    // This time the radio answers. Out of fake time: a database write does
    // not finish in it.
    c.handleFrameForTest(_dm('Running low on water'));
    await pumpEventQueue(times: 200);
    c.handleFrameForTest(_queued('Bob: Camp at the spring'));
    await pumpEventQueue(times: 200);
    expect(c.syncRequests, 3, reason: 'it asks for the next after each');
    c.handleFrameForTest([respCodeNoMoreMessages]);
    await pumpEventQueue(times: 200);

    expect(c.isSyncingQueuedMessages, isFalse);
    expect(
      (await c.watchConversation(c.contacts.single).first).map((m) => m.text),
      ['Running low on water'],
    );
    expect(
      (await c.loadChannelMessagesFor(c.channels.single)).map((m) => m.text),
      ['Camp at the spring'],
    );
  });

  test('each give-up in a row waits longer, up to every 5 minutes', () {
    fakeAsync((async) {
      // The radio answers nothing. A drain asks 4 times, 5 s apart, and
      // gives up 20 s after it starts.
      msgWaiting(async);
      for (final wait in [30, 60, 120, 240, 300, 300]) {
        async.elapse(Duration(seconds: 20 + wait - 1));
        expect(c.isSyncingQueuedMessages, isFalse, reason: 'waiting $wait s');
        async.elapse(const Duration(seconds: 1));
        expect(c.isSyncingQueuedMessages, isTrue, reason: 'after $wait s');
      }
      expect(c.syncRequests, 4 + 5 * 4 + 1, reason: 'each retry asks again');
    });
  });

  test('a drain that reaches the end stops the retries, and a later give-up '
      'starts again at 30 s', () {
    fakeAsync((async) {
      msgWaiting(async);
      giveUp();
      async.elapse(const Duration(seconds: 30));
      giveUp();
      async.elapse(const Duration(seconds: 60));
      expect(c.isSyncingQueuedMessages, isTrue, reason: 'the second retry');
      c.handleFrameForTest([respCodeNoMoreMessages]);
      expect(c.isSyncingQueuedMessages, isFalse);
      c.sent.clear();
      async.elapse(const Duration(hours: 2));
      expect(c.syncRequests, 0, reason: 'the radio holds nothing more');

      msgWaiting(async);
      giveUp();
      async.elapse(const Duration(seconds: 30));
      expect(c.isSyncingQueuedMessages, isTrue);
    });
  });

  test('a retry that comes due while a drain runs leaves that drain alone', () {
    fakeAsync((async) {
      msgWaiting(async);
      giveUp();
      async.elapse(const Duration(seconds: 28));
      // A new message, and its drain is taking messages off the radio when
      // the retry comes due.
      msgWaiting(async);
      c.handleFrameForTest(_datagram());
      c.handleFrameForTest(_datagram());
      c.sent.clear();
      async.elapse(const Duration(seconds: 2));
      expect(c.queuedMessagesRead, 2, reason: 'the drain was not started over');
      expect(c.syncRequests, 0, reason: 'one request at a time');

      c.handleFrameForTest([respCodeNoMoreMessages]);
      async.elapse(const Duration(hours: 2));
      expect(c.syncRequests, 0, reason: 'that drain reached the end');
    });
  });

  group('leaving the radio drops the retry', () {
    test('disconnect', () {
      fakeAsync((async) {
        msgWaiting(async);
        giveUp();
        c.linked = false;
        unawaited(c.disconnect());
        async.flushMicrotasks();
        backOnTheRadio();
        async.elapse(const Duration(hours: 1));
        expect(c.syncRequests, 0);
      });
    });

    test('a BLE drop', () {
      fakeAsync((async) {
        msgWaiting(async);
        giveUp();
        c.linked = false;
        c.handleBleDropForTest();
        backOnTheRadio();
        async.elapse(const Duration(hours: 1));
        expect(c.syncRequests, 0);
      });
    });

    test('a give-up after the link dropped schedules none', () {
      fakeAsync((async) {
        msgWaiting(async);
        for (var i = 0; i < 3; i++) {
          c.fireQueueSyncTimeoutForTest();
        }
        // The link drops while the last request waits; its timeout fires.
        c.linked = false;
        c.handleBleDropForTest();
        async.elapse(const Duration(seconds: 5));
        backOnTheRadio();
        async.elapse(const Duration(hours: 1));
        expect(c.syncRequests, 0);
      });
    });
  });

  // The sync banner never cleared on Bluetooth and flashed "Reading
  // messages (1)" on every message (#132). A give-up still ends the first
  // sync, and the retries do not bring the banner back.
  test(
    'the sync banner clears after a give-up and stays down for the retry',
    () {
      fakeAsync((async) {
        msgWaiting(async);
        expect(c.currentSyncStatus, SyncStatus.messages);
        expect(c.isSynced, isFalse);
        giveUp();
        expect(c.isSynced, isTrue);
        expect(c.currentSyncStatus, isNull);

        async.elapse(const Duration(seconds: 30));
        expect(c.isSyncingQueuedMessages, isTrue, reason: 'the retry');
        expect(c.currentSyncStatus, isNull);
        c.handleFrameForTest([respCodeNoMoreMessages]);
        expect(c.isSynced, isTrue);
      });
    },
  );

  test('the give-up and each retry show in the log', () {
    final logs = <String>[];
    final saved = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null && message.contains('Queue drain')) logs.add(message);
    };
    try {
      fakeAsync((async) {
        msgWaiting(async);
        giveUp();
        async.elapse(const Duration(seconds: 30));
        giveUp();
        async.elapse(const Duration(seconds: 60));
        c.handleFrameForTest([respCodeNoMoreMessages]);
      });
    } finally {
      debugPrint = saved;
    }
    expect(logs, [
      '[Connector] WARN: Queue drain gave up: the radio did not answer 4 '
          'requests. Trying again in 30 s',
      '[Connector] INFO: Queue drain: retry 1',
      '[Connector] WARN: Queue drain gave up: the radio did not answer 4 '
          'requests. Trying again in 60 s',
      '[Connector] INFO: Queue drain: retry 2',
      '[Connector] INFO: Queue drain reached the end; no more retries',
    ]);
  });
}
