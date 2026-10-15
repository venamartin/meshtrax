import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// A second full getContacts() while the radio is still streaming the first
// one. Firmware refuses the second CMD_GET_CONTACTS with ERR_CODE_BAD_STATE
// (MyMesh.cpp: `if (_iter_started) writeErrFrame(ERR_CODE_BAD_STATE)`) and
// keeps streaming the first iterator to END_OF_CONTACTS.
class _Connector extends MeshCoreConnector {
  final getContactsSent = <Uint8List>[];

  @override
  bool get isConnected => true;

  @override
  Future<void> sendFrame(
    Uint8List data, {
    String? channelSendQueueId,
    bool expectsGenericAck = false,
  }) async {
    if (data[0] == cmdGetContacts) getContactsSent.add(data);
  }
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

Uint8List _key(int seed) =>
    Uint8List.fromList(List.generate(32, (i) => (seed + i) & 0xFF));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final keys = {
    'A': _key(0x10),
    'B': _key(0x40),
    'C': _key(0x70),
    'D': _key(0xA0),
  };

  late _Connector c;
  Contact byName(String n) => c.allContacts.firstWhere((x) => x.name == n);

  void stream(List<String> names) {
    for (final n in names) {
      c.handleFrameForTest(_contactFrame(keys[n]!, n));
    }
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
    c = _Connector();
    await c.getContacts();
    c.handleFrameForTest(
        Uint8List.fromList([respCodeContactsStart, 4, 0, 0, 0]));
    stream(['A', 'B', 'C', 'D']);
    c.handleFrameForTest(
        Uint8List.fromList([respCodeEndOfContacts, 0, 0, 0, 0]));
  });

  test(
      'a full refresh requested mid-stream keeps every contact and its '
      'route choice', () async {
    await c.setPathOverride(byName('C'), pathLen: -1);
    expect(byName('C').pathOverride, -1);

    // First full download starts streaming.
    await c.getContacts();
    c.handleFrameForTest(
        Uint8List.fromList([respCodeContactsStart, 4, 0, 0, 0]));
    stream(['A', 'B']);

    // User taps "Refresh contacts" while the stream is busy.
    await c.getContacts();
    // Radio: iterator busy.
    c.handleFrameForTest(Uint8List.fromList([respCodeErr, 6]));

    // The first stream carries on to its end.
    stream(['C', 'D']);
    c.handleFrameForTest(
        Uint8List.fromList([respCodeEndOfContacts, 0, 0, 0, 0]));

    final names = c.allContacts.map((x) => x.name).toList()..sort();
    final cOverride = byName('C').pathOverride;
    expect(
      {'names': names, 'C.pathOverride': cOverride},
      {'names': ['A', 'B', 'C', 'D'], 'C.pathOverride': -1},
      reason: 'the radio streamed all 4 contacts and the Always-flood '
          'choice on C must survive the refresh',
    );
  });

  test('a double tap on refresh sends one request and keeps route choices',
      () async {
    await c.setPathOverride(byName('C'), pathLen: -1);
    c.getContactsSent.clear();

    await c.getContacts();
    await c.getContacts(); // before the radio's CONTACTS_START arrives
    expect(c.getContactsSent, hasLength(1));

    c.handleFrameForTest(
        Uint8List.fromList([respCodeContactsStart, 4, 0, 0, 0]));
    stream(['A', 'B', 'C', 'D']);
    c.handleFrameForTest(
        Uint8List.fromList([respCodeEndOfContacts, 0, 0, 0, 0]));

    expect(c.allContacts, hasLength(4));
    expect(byName('C').pathOverride, -1);
    expect(c.getContactsSent, hasLength(1),
        reason: 'the full download that ran already was the refresh');
  });

  test('a full request during a partial download runs when it ends',
      () async {
    c.getContactsSent.clear();

    await c.getContacts(since: 5, preserveExisting: true);
    c.handleFrameForTest(
        Uint8List.fromList([respCodeContactsStart, 4, 0, 0, 0]));
    await c.getContacts();
    expect(c.getContactsSent, hasLength(1), reason: 'not mid-stream');

    c.handleFrameForTest(
        Uint8List.fromList([respCodeEndOfContacts, 0, 0, 0, 0]));
    await Future<void>.delayed(Duration.zero);
    expect(c.getContactsSent, hasLength(2));
    expect(c.getContactsSent.last, hasLength(1),
        reason: 'the queued request is a full one (no since)');
  });
}
