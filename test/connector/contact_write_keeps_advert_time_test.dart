import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/services/message_retry_service.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// The firmware drops any advert that is not newer than the contact's stored
// last_advert_timestamp (BaseChatMesh::onAdvertRecv). Contact writes used to
// stamp it "now", so a contact whose clock runs behind ours went unheard
// until its clock caught up. A write now sends back the radio's own value,
// and the live row's flags: a caller's old copy must not undo a permission.
class _Connector extends MeshCoreConnector {
  final frames = <Uint8List>[];
  Uint8List? snapshot;

  @override
  bool get isConnected => true;

  @override
  Future<void> sendFrame(
    Uint8List data, {
    String? channelSendQueueId,
    bool expectsGenericAck = false,
  }) async {
    frames.add(data);
    if (data[0] == cmdGetContactByKey && snapshot != null) {
      scheduleMicrotask(() => handleFrameForTest(snapshot!));
    }
  }

  List<Uint8List> get writes =>
      frames.where((f) => f[0] == cmdAddUpdateContact).toList();
}

final _key = Uint8List.fromList(List.generate(32, (i) => 0x5B + i));
const _advertSecs = 1761400000;

Uint8List _u32(int v) => Uint8List.fromList(
    [v & 0xFF, (v >> 8) & 0xFF, (v >> 16) & 0xFF, (v >> 24) & 0xFF]);

Uint8List _contactFrame({required int flags, required int advertSecs}) {
  final w = BytesBuilder();
  w.addByte(respCodeContact);
  w.add(_key);
  w.addByte(advTypeChat);
  w.addByte(flags);
  w.addByte(0xFF);
  w.add(Uint8List(maxPathSize));
  final name = Uint8List(maxNameSize);
  name.setRange(0, 5, 'ALICE'.codeUnits);
  w.add(name);
  w.add(_u32(advertSecs));
  w.add(Uint8List(8)); // no position
  w.add(_u32(advertSecs + 60)); // lastmod
  return w.toBytes();
}

int _advertOf(Uint8List write) =>
    ByteData.sublistView(write).getUint32(132, Endian.little);

Future<void> settle() async {
  for (var i = 0; i < 40; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Connector c;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
    c = _Connector();
    c.initialize(retryService: MessageRetryService());
    await c.getContacts();
    c.handleFrameForTest(
        Uint8List.fromList([respCodeContactsStart, 1, 0, 0, 0]));
    c.handleFrameForTest(_contactFrame(flags: 0, advertSecs: _advertSecs));
    c.handleFrameForTest(
        Uint8List.fromList([respCodeEndOfContacts, 0, 0, 0, 0]));
    await settle();
    c.frames.clear();
  });

  test('the contact keeps the radio\'s advert time', () {
    expect(c.contacts.single.lastAdvertSecs, _advertSecs);
  });

  test('a route write sends it back, with the live flags', () async {
    final stale = c.contacts.single;
    // The radio's row gains a permission after the caller took its copy.
    c.handleFrameForTest(Uint8List.fromList([respCodeContactsStart, 1, 0, 0, 0]));
    c.handleFrameForTest(
        _contactFrame(flags: contactFlagTeleBase, advertSecs: _advertSecs));
    c.handleFrameForTest(Uint8List.fromList([respCodeEndOfContacts, 0, 0, 0, 0]));
    await settle();
    c.frames.clear();

    await c.setContactPath(stale, Uint8List.fromList([0xA2, 0x77]), 1,
        hashSize: 2);
    final write = c.writes.single;
    expect(_advertOf(write), _advertSecs);
    expect(write[contactFlagsOffset], contactFlagTeleBase,
        reason: 'the old copy had no permission; the radio\'s row does');
  });

  test('a permission change sends back the snapshot\'s advert time',
      () async {
    c.snapshot = _contactFrame(flags: 0, advertSecs: _advertSecs + 500);
    await c.setContactFlags(c.contacts.single, teleBase: true);
    final write = c.writes.single;
    expect(_advertOf(write), _advertSecs + 500);
    expect(write[contactFlagsOffset], contactFlagTeleBase);
  });
}
