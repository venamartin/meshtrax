import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/helpers/structured_message.dart';
import 'package:meshtrax/models/channel.dart';
import 'package:meshtrax/models/radio_settings.dart';
import 'package:meshtrax/services/trax_service.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// A member's TRAX message, all the way in from the radio: it is stored and
// shown like any message, asks once on a private channel, and never moves
// the radio. Public never asks, nor does the backlog.
class _Radio extends MeshCoreConnector {
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

final _selfKey = Uint8List(32)..fillRange(0, 32, 0x11);
final _tripPsk = Uint8List.fromList(List.generate(16, (i) => 0x30 + i));

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

Uint8List _channelInfo(int index, String name, Uint8List psk) =>
    Uint8List.fromList([
      respCodeChannelInfo,
      ...buildSetChannelFrame(index, name, psk).sublist(1),
    ]);

/// A channel message as the radio hands it over:
/// [code][snr][rsv][rsv][channel_idx][path_len][txt_type][ts x4][text].
Uint8List _message(int channel, String senderAndText) {
  final secs = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  final w = BytesBuilder();
  w.add([respCodeChannelMsgRecvV3, 0, 0, 0, channel, 0, txtTypePlain]);
  w.add((ByteData(4)..setUint32(0, secs, Endian.little)).buffer.asUint8List());
  w.add(utf8.encode(senderAndText));
  return w.toBytes();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Radio c;
  late TraxService trax;
  late List<TraxPrompt> prompts;
  final on = TraxMessage.switching(
    until: DateTime.now().add(const Duration(days: 1)),
    preset: const LoRaParams(freqKhz: 918000, bwHz: 62500, sf: 7, cr: 5),
  ).toWire();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
    c = _Radio();
    final info = Uint8List(82)
      ..[0] = respCodeDeviceInfo
      ..[1] = 9;
    c.handleFrameForTest(info);
    c.handleFrameForTest(_selfInfo());
    await pumpEventQueue(times: 200);
    c.handleFrameForTest([respCodeContactsStart, 0, 0, 0, 0]);
    c.handleFrameForTest([respCodeEndOfContacts, 0, 0, 0, 0]);
    await pumpEventQueue(times: 200);
    c.handleFrameForTest(
      _channelInfo(0, 'Public', Channel.parsePskHex(Channel.publicChannelPsk)),
    );
    c.handleFrameForTest(_channelInfo(1, 'Desert trip', _tripPsk));
    await pumpEventQueue(times: 200);
    c.markChannelsVerifiedForTest();
    trax = TraxService(c);
    prompts = [];
    trax.prompts.listen(prompts.add);
    c.sent.clear();
  });

  tearDown(() => trax.dispose());

  test(
    'a TRAX message on the trip channel asks, and the radio stays put',
    () async {
      c.handleFrameForTest(_message(1, 'Ana: $on'));
      await pumpEventQueue(times: 200);

      final prompt = prompts.single as TraxFollowPrompt;
      expect(prompt.sender, 'Ana');
      expect(prompt.channel.name, 'Desert trip');
      expect(
        c.sent.where((f) => f[0] == cmdSetRadioParams),
        isEmpty,
        reason: 'nothing retunes without a tap',
      );
      expect(
        (await c.loadChannelMessagesFor(prompt.channel)).single.text,
        on,
        reason: 'shown in the chat like any message',
      );
    },
  );

  test('on Public it never asks', () async {
    c.handleFrameForTest(_message(0, 'Mallory: $on'));
    await pumpEventQueue(times: 200);
    expect(prompts, isEmpty);
    expect(c.sent.where((f) => f[0] == cmdSetRadioParams), isEmpty);
  });

  test('from the backlog it never asks', () async {
    c.handleFrameForTest([pushCodeMsgWaiting]);
    await pumpEventQueue(times: 20);
    expect(c.isSyncingQueuedMessages, isTrue);
    c.handleFrameForTest(_message(1, 'Ana: $on'));
    await pumpEventQueue(times: 200);
    expect(prompts, isEmpty);
  });
}
