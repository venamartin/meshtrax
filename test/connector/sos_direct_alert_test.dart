import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/services/app_settings_service.dart';
import 'package:meshtrax/services/message_retry_service.dart';
import 'package:meshtrax/services/notification_service.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// An SOS in a direct message alerts like one in a channel: on the SOS
// category, with direct-message notifications switched off.
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
  w.add(
    (ByteData(8)
          ..setUint32(0, 910525000, Endian.little)
          ..setUint32(4, 62500, Endian.little))
        .buffer
        .asUint8List(),
  );
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

Uint8List _msgFrame(Uint8List sender, String text, int seconds) {
  final w = BytesBuilder();
  w.add([respCodeContactMsgRecvV3, 0x14, 0, 0]);
  w.add(sender.sublist(0, 6));
  w.addByte(0);
  w.addByte(txtTypePlain);
  w.add(
    (ByteData(4)..setUint32(0, seconds, Endian.little)).buffer.asUint8List(),
  );
  w.add(utf8.encode(text));
  return w.toBytes();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final selfKey = Uint8List.fromList(List.generate(32, (i) => 0xAB + i));
  final annKey = Uint8List.fromList(List.generate(32, (i) => 0x5B + i));
  final shown = <ShownNotification>[];
  late _Connector c;
  late Contact ann;
  late AppSettingsService settings;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
    settings = AppSettingsService();
    await settings.loadSettings();
    c = _Connector()
      ..initialize(
        retryService: MessageRetryService(),
        appSettingsService: settings,
      );
    c.handleFrameForTest(_selfInfo(selfKey));
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await c.getContacts();
    c.handleFrameForTest(
      Uint8List.fromList([respCodeContactsStart, 1, 0, 0, 0]),
    );
    c.handleFrameForTest(_contactFrame(annKey, 'Ann'));
    c.handleFrameForTest(
      Uint8List.fromList([respCodeEndOfContacts, 0, 0, 0, 0]),
    );
    ann = c.contacts.single;
    shown.clear();
    NotificationService.debugOnShow = shown.add;
  });

  tearDown(() {
    NotificationService.debugOnShow = null;
    c.dispose();
  });

  Future<void> receive(String text, int secs) async {
    final before = (await c.loadMessagesFor(ann)).length;
    c.handleFrameForTest(_msgFrame(annKey, text, secs));
    for (var i = 0; i < 50; i++) {
      if ((await c.loadMessagesFor(ann)).length > before) break;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }

  test('an SOS in a direct message alerts with DM notifications off', () async {
    await settings.setNotifyOnNewMessage(false);
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await receive('are you there?', now - 20);
    expect(shown, isEmpty);
    await receive('SOS: Lost\n36.460000, -116.870000', now - 10);
    final alert = shown.single;
    expect(alert.channelId, 'meshtrax_sos_morse');
    expect(alert.title, 'SOS from Ann');
    expect(alert.body, 'Lost');
    expect(alert.payload, ann.publicKeyHex);
  });
}
