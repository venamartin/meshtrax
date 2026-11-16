import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/models/contact.dart';

// A channel message carries the sender's handle and no key, so the name the
// user gave a contact is matched by handle; a shared handle is a guess.
Contact _contact(
  int seed,
  String name, {
  int type = advTypeChat,
  int hour = 9,
}) =>
    Contact(
      publicKey: Uint8List.fromList(List.generate(32, (i) => seed + i)),
      name: name,
      type: type,
      pathLength: -1,
      path: Uint8List(0),
      pathHashSize: 1,
      lastSeen: DateTime(2026, 11, 16, hour),
    );

void main() {
  final walker = _contact(0x10, 'Ridge Walker');
  final pineOld = _contact(0x30, 'Pine Hollow', hour: 8);
  final pineNew = _contact(0x50, ' pine hollow ', hour: 10);
  final repeater = _contact(0x70, 'Lookout', type: advTypeRepeater);
  final me = _contact(0x90, 'Lookout');

  Map<String, ({String name, bool guess})> index(
    List<Contact> contacts,
    Map<Contact, String> names, {
    String? self,
  }) =>
      MeshCoreConnector.nicknamesByHandle(
        contacts,
        (key) => names.entries
            .where((e) => e.key.publicKeyHex == key)
            .map((e) => e.value)
            .firstOrNull,
        self,
      );

  test('a handle one contact uses is a sure match', () {
    final names = index([walker, pineOld], {walker: 'Annie'});
    expect(names['ridge walker'], (name: 'Annie', guess: false));
    expect(names.containsKey('pine hollow'), isFalse, reason: 'not named');
  });

  test('a shared handle is a guess, named after the newest one heard', () {
    expect(
      index([pineOld, pineNew], {pineOld: 'Bob'})['pine hollow'],
      (name: 'Bob', guess: true),
      reason: 'handles match trimmed and in any case',
    );
    expect(
      index([pineOld, pineNew], {pineOld: 'Bob', pineNew: 'Cy'})['pine hollow'],
      (name: 'Cy', guess: true),
    );
  });

  test('the same contact listed twice is still one contact', () {
    expect(
      index([walker, walker], {walker: 'Annie'})['ridge walker'],
      (name: 'Annie', guess: false),
    );
  });

  test('repeaters and this radio itself are left out', () {
    expect(index([repeater], {repeater: 'Tower'}), isEmpty);
    expect(
      index([me, repeater], {me: 'Me'}, self: me.publicKeyHex),
      isEmpty,
    );
  });
}
