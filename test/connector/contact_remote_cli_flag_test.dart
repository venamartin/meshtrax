import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Firmware 1.18 stores "may run CLI commands on our radio" as contact flag
// 0x10, and CMD_ADD_UPDATE_CONTACT overwrites every flag bit. Any contact
// write that rebuilds the byte from known bits would silently revoke (or,
// with stale bits, grant) remote CLI access.
class _Connector extends MeshCoreConnector {
  int radioFlags = 0;
  final writes = <Uint8List>[];

  @override
  bool get isConnected => true;

  @override
  Future<void> sendFrame(
    Uint8List data, {
    String? channelSendQueueId,
    bool expectsGenericAck = false,
  }) async {
    if (data[0] == cmdGetContactByKey) {
      final frame = _contactFrame(data.sublist(1, 33), 'PEER', radioFlags);
      scheduleMicrotask(() => handleFrameForTest(frame));
    } else if (data[0] == cmdAddUpdateContact) {
      writes.add(data);
    }
  }
}

Uint8List _contactFrame(Uint8List pubKey, String name, int flags) {
  final w = BytesBuilder();
  w.addByte(respCodeContact);
  w.add(pubKey);
  w.addByte(advTypeChat);
  w.addByte(flags);
  w.addByte(0xFF);
  w.add(Uint8List(maxPathSize));
  final nameBytes = Uint8List(maxNameSize);
  nameBytes.setRange(0, name.length, name.codeUnits);
  w.add(nameBytes);
  w.add(Uint8List.fromList([1, 0, 0, 0]));
  w.add(Uint8List(8));
  return w.toBytes();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final key = Uint8List.fromList(List.generate(32, (i) => 0x31 + i));

  late _Connector c;

  Contact peer() => c.allContacts.firstWhere((x) => x.name == 'PEER');

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
    c = _Connector();
    await c.getContacts();
    c.handleFrameForTest(Uint8List.fromList([respCodeContactsStart, 1, 0, 0, 0]));
    c.handleFrameForTest(_contactFrame(key, 'PEER', contactFlagRemoteCli));
    c.handleFrameForTest(Uint8List.fromList([respCodeEndOfContacts, 0, 0, 0, 0]));
  });

  test('the parsed contact keeps the bit, and so does its stored copy', () {
    expect(peer().flags, contactFlagRemoteCli);
    expect(Contact.fromJson(peer().toJson()).flags, contactFlagRemoteCli);
  });

  test('favouriting keeps the grant the radio holds', () async {
    c.radioFlags = contactFlagRemoteCli;

    await c.setContactFlags(peer(), isFavorite: true);

    expect(c.writes.single[contactFlagsOffset],
        contactFlagRemoteCli | contactFlagFavorite);
    expect(peer().flags, contactFlagRemoteCli | contactFlagFavorite);
  });

  test('the radio is the truth, not the cached copy', () async {
    // Granted by another app on the same radio after our sync.
    c.radioFlags = contactFlagRemoteCli | contactFlagTeleBase;
    final stale = peer().copyWith(flags: 0);

    await c.setContactFlags(stale, teleBase: false);

    expect(c.writes.single[contactFlagsOffset], contactFlagRemoteCli);
  });

  test('a route write keeps the grant', () async {
    await c.setContactPath(peer(), Uint8List.fromList([0xA2]), 1, hashSize: 1);

    expect(c.writes.single[contactFlagsOffset], contactFlagRemoteCli);
  });
}
