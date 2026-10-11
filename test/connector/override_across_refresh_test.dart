import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// A full contact download empties the list and rebuilds it from the radio's
// frames, which know nothing of the user's route choices. Custom path and
// Always flood must come through it.
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

Uint8List _contactFrame(Uint8List pubKey, String name, {int pathLen = 0xFF}) {
  final w = BytesBuilder();
  w.addByte(respCodeContact);
  w.add(pubKey);
  w.addByte(advTypeRepeater);
  w.addByte(0); // flags
  w.addByte(pathLen);
  w.add(Uint8List(maxPathSize));
  final nameBytes = Uint8List(maxNameSize);
  nameBytes.setRange(0, name.length, name.codeUnits);
  w.add(nameBytes);
  w.add(Uint8List.fromList([1, 0, 0, 0])); // last advert timestamp
  w.add(Uint8List(8)); // lat, lon
  return w.toBytes();
}

Uint8List _contactsStart(int total) =>
    Uint8List.fromList([respCodeContactsStart, total, 0, 0, 0]);

Uint8List _endOfContacts() =>
    Uint8List.fromList([respCodeEndOfContacts, 0, 0, 0, 0]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final madonna = Uint8List.fromList(List.generate(32, (i) => 0xA3 + i));
  final other = Uint8List.fromList(List.generate(32, (i) => 0x5B + i));

  late _Connector c;

  Future<void> fullDownload(List<Uint8List> frames) async {
    await c.getContacts();
    c.handleFrameForTest(_contactsStart(frames.length));
    for (final f in frames) {
      c.handleFrameForTest(f);
    }
    c.handleFrameForTest(_endOfContacts());
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
    c = _Connector();
    await fullDownload([
      _contactFrame(madonna, 'MADONNA'),
      _contactFrame(other, 'OTHER'),
    ]);
  });

  test('a route override survives a full contact download', () async {
    final before = c.allContacts.firstWhere((x) => x.name == 'MADONNA');
    await c.setPathOverride(before, pathLen: -1);
    expect(
      c.allContacts.firstWhere((x) => x.name == 'MADONNA').pathOverride,
      -1,
    );

    await fullDownload([
      _contactFrame(madonna, 'MADONNA', pathLen: 0x42),
      _contactFrame(other, 'OTHER'),
    ]);

    final after = c.allContacts.firstWhere((x) => x.name == 'MADONNA');
    expect(after.pathOverride, -1, reason: 'Always flood must come through');
    expect(after.pathLength, 2, reason: "the radio's route is still taken");
    expect(after.pathHashSize, 2);
    expect(
      c.allContacts.firstWhere((x) => x.name == 'OTHER').pathOverride,
      isNull,
    );
  });

  test('a contact the radio no longer sends takes nothing with it', () async {
    final before = c.allContacts.firstWhere((x) => x.name == 'MADONNA');
    await c.setPathOverride(before, pathLen: -1);

    // MADONNA is gone from the radio; a later download that brings her
    // back must not resurrect the old choice.
    await fullDownload([_contactFrame(other, 'OTHER')]);
    expect(c.allContacts.where((x) => x.name == 'MADONNA'), isEmpty);

    await fullDownload([
      _contactFrame(madonna, 'MADONNA'),
      _contactFrame(other, 'OTHER'),
    ]);
    expect(
      c.allContacts.firstWhere((x) => x.name == 'MADONNA').pathOverride,
      isNull,
    );
  });
}
