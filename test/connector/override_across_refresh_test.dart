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

Uint8List _contactFrame(
  Uint8List pubKey,
  String name, {
  int pathLen = 0xFF,
  int code = respCodeContact,
}) {
  final w = BytesBuilder();
  w.addByte(code);
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

  test('an advert landing before CONTACTS_START keeps the override', () async {
    // Auto-add repeaters, so a live advert adds the contact on its own.
    c.handleFrameForTest(
      Uint8List.fromList([respCodeAutoAddConfig, autoAddRepeaterFlag]),
    );
    await c.setPathOverride(
      c.allContacts.firstWhere((x) => x.name == 'MADONNA'),
      pathLen: -1,
    );

    await c.getContacts();
    // The advert adds MADONNA to the just-emptied list; CONTACTS_START then
    // empties it again and her own frame must still find the override.
    c.handleFrameForTest(
      _contactFrame(madonna, 'MADONNA', code: pushCodeNewAdvert),
    );
    c.handleFrameForTest(_contactsStart(2));
    c.handleFrameForTest(_contactFrame(madonna, 'MADONNA', pathLen: 0x42));
    c.handleFrameForTest(_contactFrame(other, 'OTHER'));
    c.handleFrameForTest(_endOfContacts());

    expect(
      c.allContacts.firstWhere((x) => x.name == 'MADONNA').pathOverride,
      -1,
    );
  });

  test('a choice made mid-download waits for the contact frame', () async {
    final m = c.allContacts.firstWhere((x) => x.name == 'MADONNA');
    await c.setPathOverride(m, pathLen: -1);

    await c.getContacts();
    c.handleFrameForTest(_contactsStart(2));
    // Custom path set while MADONNA's frame is still on its way, replacing
    // the stashed Always flood.
    await c.setPathOverride(
      m,
      pathLen: 1,
      pathBytes: Uint8List.fromList([0xA2]),
    );
    c.handleFrameForTest(_contactFrame(madonna, 'MADONNA'));
    c.handleFrameForTest(_contactFrame(other, 'OTHER'));
    c.handleFrameForTest(_endOfContacts());

    final after = c.allContacts.firstWhere((x) => x.name == 'MADONNA');
    expect(after.pathOverride, 1);
    expect(after.pathOverrideBytes, [0xA2]);
    expect(after.pathOverrideHashSize, c.pathHashByteWidth);

    // And a clear made mid-download must not be undone by the frame.
    await c.getContacts();
    c.handleFrameForTest(_contactsStart(1));
    await c.setPathOverride(after, pathLen: null);
    c.handleFrameForTest(_contactFrame(madonna, 'MADONNA'));
    c.handleFrameForTest(_endOfContacts());
    expect(
      c.allContacts.firstWhere((x) => x.name == 'MADONNA').pathOverride,
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
