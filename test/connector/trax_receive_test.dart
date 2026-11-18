import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/helpers/structured_message.dart';
import 'package:meshtrax/models/channel.dart';
import 'package:meshtrax/models/radio_settings.dart';
import 'package:meshtrax/services/app_settings_service.dart';
import 'package:meshtrax/services/message_retry_service.dart';
import 'package:meshtrax/services/notification_service.dart';
import 'package:meshtrax/services/trax_service.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// A member with the phone in a pocket hears only the notification. On a
// private channel a member's TRAX message gets one button there, Switch
// too, or Leave too while this radio is on TRAX: only where the app would
// ask, and the button only opens the app to ask.
class _Connector extends MeshCoreConnector {
  final frames = <Uint8List>[];

  @override
  bool get isConnected => true;

  @override
  Future<void> sendFrame(
    Uint8List data, {
    String? channelSendQueueId,
    bool expectsGenericAck = false,
  }) async => frames.add(data);
}

/// DEVICE_INFO of companion 1.18: byte 80 is Off-Grid Repeat.
Uint8List _deviceInfo({bool repeat = false}) {
  final frame = Uint8List(82);
  frame[0] = respCodeDeviceInfo;
  frame[1] = 14;
  frame.setRange(60, 67, 'v1.18.0'.codeUnits);
  frame[80] = repeat ? 1 : 0;
  return frame;
}

Uint8List _selfInfo({int freq = 910525}) {
  final w = BytesBuilder();
  w.add([respCodeSelfInfo, advTypeChat, 20, 22]);
  w.add(Uint8List.fromList(List.filled(32, 0x77)));
  w.add(Uint8List(8));
  w.add([0, 0, 0, 1]);
  w.add(
    (ByteData(8)
          ..setUint32(0, freq, Endian.little)
          ..setUint32(4, 62500, Endian.little))
        .buffer
        .asUint8List(),
  );
  w.add([7, 5]);
  w.add(utf8.encode('GWQ'));
  return w.toBytes();
}

Uint8List _channelInfo(int index, String name, Uint8List psk) =>
    Uint8List.fromList([
      respCodeChannelInfo,
      ...buildSetChannelFrame(index, name, psk).sublist(1),
    ]);

/// A channel message as the radio hands over one it heard live.
Uint8List _heard(int index, String sender, String text) {
  final secs = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  return Uint8List.fromList([
    respCodeChannelMsgRecvV3,
    0x28,
    0,
    0,
    index,
    0,
    txtTypePlain,
    ...(ByteData(4)..setUint32(0, secs, Endian.little)).buffer.asUint8List(),
    ...utf8.encode('$sender: $text'),
    0,
  ]);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Connector c;
  late TraxService trax;
  final shown = <ShownNotification>[];
  final on = TraxMessage.switching(
    until: DateTime.now().add(const Duration(days: 1)),
    preset: const LoRaParams(freqKhz: 918000, bwHz: 62500, sf: 7, cr: 5),
  ).toWire();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
    final settings = AppSettingsService();
    await settings.loadSettings();
    c = _Connector()
      ..initialize(
        retryService: MessageRetryService(),
        appSettingsService: settings,
      );
    c.handleFrameForTest(_deviceInfo());
    c.handleFrameForTest(_selfInfo());
    await pumpEventQueue(times: 200);
    c.handleFrameForTest(
      _channelInfo(
        1,
        'Desert trip',
        Uint8List.fromList(List.generate(16, (i) => 0x30 + i)),
      ),
    );
    c.handleFrameForTest(
      _channelInfo(2, '#desert', Channel.derivePskFromHashtag('#desert')),
    );
    await pumpEventQueue(times: 200);
    c.markChannelsVerifiedForTest();
    trax = TraxService(c);
    // As the app wires it.
    c.traxActionFor = trax.notificationAction;
    shown.clear();
    NotificationService.debugOnShow = shown.add;
  });

  tearDown(() {
    NotificationService.debugOnShow = null;
    trax.dispose();
  });

  Future<void> hear(int index, String sender, String text) async {
    c.handleFrameForTest(_heard(index, sender, text));
    await pumpEventQueue(times: 200);
  }

  test('only where the app would ask', () async {
    await hear(1, 'Ana', on);
    await hear(2, 'Bo', on);
    await hear(1, 'Cy', 'Switching at the trailhead');
    expect(shown.map((n) => (n.body.split(':').first, n.action)), [
      ('Ana', NotificationService.traxFollowAction),
      ('Bo', null),
      ('Cy', null),
    ], reason: 'a hashtag channel anyone can read never asks');
    expect(shown.first.channelId, 'meshtrax_channels');
    expect(shown.first.payload, 'channel:1');
    expect(trax.askedOn(1), isA<TraxFollowPrompt>());

    // The radio moves to TRAX.
    c.handleFrameForTest(_deviceInfo(repeat: true));
    c.handleFrameForTest(_selfInfo(freq: 918000));
    await pumpEventQueue(times: 200);
    expect(trax.isOn, isTrue);
    shown.clear();
    await hear(1, 'Dee', on);
    await hear(1, 'Ana', 'TRAX: off');
    expect(shown.map((n) => (n.body.split(':').first, n.action)), [
      ('Dee', null),
      ('Ana', NotificationService.traxLeaveAction),
    ]);
    expect(
      c.frames.where((f) => f[0] == cmdSetRadioParams),
      isEmpty,
      reason: 'nothing switches by itself',
    );
  });
}
