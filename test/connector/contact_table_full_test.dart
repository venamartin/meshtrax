import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/services/message_retry_service.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// User report 2026-10-26: "max contacts reached", asked to enable Overwrite
// Oldest, with 13 contacts and no auto-add. The firmware answers
// ERR_CODE_TABLE_FULL to any send that finds none of its 16 packet buffers
// free (a DM, a login, a request, a Discover), so that code alone must not
// say the contact list is full.
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

Uint8List _contactFrame(int n) {
  final w = BytesBuilder();
  w.addByte(respCodeContact);
  w.add([0x40 + n, ...List.filled(31, 0x22)]);
  w.addByte(advTypeChat);
  w.addByte(0);
  w.addByte(0xFF);
  w.add(Uint8List(maxPathSize));
  final name = Uint8List(maxNameSize);
  name.setRange(0, 4, 'C${n.toString().padLeft(3, '0')}'.codeUnits);
  w.add(name);
  w.add([1, 0, 0, 0]);
  w.add(Uint8List(8));
  return w.toBytes();
}

Future<void> settle() async {
  for (var i = 0; i < 40; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Connector c;
  late int events;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
    c = _Connector();
    c.initialize(retryService: MessageRetryService());
    events = 0;
    c.contactTableFullEvents.listen((_) => events++);
  });

  Future<void> load(int count) async {
    await c.getContacts();
    c.handleFrameForTest(
        Uint8List.fromList([respCodeContactsStart, count, 0, 0, 0]));
    for (var i = 0; i < count; i++) {
      c.handleFrameForTest(_contactFrame(i));
    }
    c.handleFrameForTest(
        Uint8List.fromList([respCodeEndOfContacts, 0, 0, 0, 0]));
    await settle();
  }

  test('a send the radio had no buffer for is not a full contact list',
      () async {
    await load(13);
    expect(c.contactTableFull, isFalse);
    c.handleFrameForTest(Uint8List.fromList([respCodeErr, errCodeTableFull]));
    await settle();
    expect(events, 0);
  });

  test('the same code with the table at its limit is', () async {
    await load(c.maxContacts - 1);
    expect(c.contactTableFull, isTrue);
    c.handleFrameForTest(Uint8List.fromList([respCodeErr, errCodeTableFull]));
    await settle();
    expect(events, 1);
    c.handleFrameForTest(Uint8List.fromList([respCodeErr, 2])); // not found
    await settle();
    expect(events, 1, reason: 'another error says nothing about it');
  });

  test('the radio saying so (no slot for an auto-add) always is', () async {
    await load(13);
    c.handleFrameForTest(Uint8List.fromList([pushCodeContactsFull]));
    await settle();
    expect(events, 1);
  });
}
