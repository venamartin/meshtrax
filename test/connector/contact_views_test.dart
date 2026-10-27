import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Message rows read the contact lists many times a frame. The connector
// keeps each copy, and the index a room post finds its author by, until a
// list changes; the change must show at once (owner, 2026-10-26: glitches
// scrolling through messages).
Uint8List _contactFrame(int code, Uint8List pubKey, String name) {
  final w = BytesBuilder();
  w.addByte(code);
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

  late MeshCoreConnector c;

  void saved(Uint8List key, String name) =>
      c.handleFrameForTest(_contactFrame(respCodeContact, key, name));
  // An advert while auto-add is off: heard, not saved.
  void heard(Uint8List key, String name) =>
      c.handleFrameForTest(_contactFrame(pushCodeNewAdvert, key, name));

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
    c = MeshCoreConnector();
  });

  test('a copy is kept until its list changes', () {
    saved(_key(0x10), 'Alpha');
    final contacts = c.contacts;
    final unfiltered = c.allContactsUnfiltered;
    final stamp = c.contactsStamp;
    expect(c.contacts, same(contacts));
    expect(c.allContactsUnfiltered, same(unfiltered));
    expect(c.contactsStamp, stamp);

    saved(_key(0x40), 'Bravo');
    expect(c.contacts, isNot(same(contacts)));
    expect(c.contacts.map((x) => x.name), ['Alpha', 'Bravo']);
    expect(c.contactsStamp, isNot(stamp));

    final discovered = c.discoveredContacts;
    heard(_key(0x70), 'Charlie');
    expect(c.discoveredContacts, isNot(same(discovered)));
    expect(c.discoveredContacts.map((x) => x.name), ['Charlie']);
    expect(c.allContactsUnfiltered.map((x) => x.name),
        ['Alpha', 'Bravo', 'Charlie']);
  });

  test('a room author is found by the first four key bytes', () {
    final alpha = _key(0x10);
    // Same four leading bytes, a different radio, heard first.
    final twin = Uint8List.fromList(
        [...alpha.sublist(0, 4), ...List.filled(28, 0xEE)]);
    final charlie = _key(0x70);
    heard(twin, 'Twin');
    saved(alpha, 'Alpha');
    heard(charlie, 'Charlie');

    expect(c.contactByKeyPrefix4(alpha.sublist(0, 4))?.name, 'Alpha',
        reason: 'a saved contact wins, as the old scan found it first');
    expect(c.contactByKeyPrefix4(charlie.sublist(0, 6))?.name, 'Charlie',
        reason: 'heard-only authors count too');
    expect(c.contactByKeyPrefix4(Uint8List.fromList([9, 9, 9, 9])), isNull);
    expect(c.contactByKeyPrefix4(Uint8List.fromList([0x10, 0x11, 0x12])),
        isNull);

    saved(alpha, 'Alpha renamed');
    expect(c.contactByKeyPrefix4(alpha.sublist(0, 4))?.name, 'Alpha renamed');
  });
}
