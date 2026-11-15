import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/utils/contact_search.dart';

void main() {
  final contact = Contact(
    publicKey: Uint8List.fromList(List.generate(32, (i) => 0xA0 + i)),
    name: 'Ridge Walker',
    type: advTypeChat,
    pathLength: -1,
    path: Uint8List(0),
    pathHashSize: 1,
    lastSeen: DateTime(2026, 11, 15),
  );

  test('finds a contact by its radio name or by the real name given it', () {
    expect(matchesContactQuery(contact, 'walker'), isTrue);
    expect(matchesContactQuery(contact, 'smith'), isFalse);
    expect(
      matchesContactQuery(contact, 'smith', realName: 'Ann Smith'),
      isTrue,
    );
    expect(
      matchesContactQuery(contact, 'walker', realName: 'Ann Smith'),
      isTrue,
    );
    expect(matchesContactQuery(contact, 'bob', realName: 'Ann Smith'), isFalse);
  });

  test('still finds a contact by the start of its key', () {
    expect(matchesContactQuery(contact, 'a0a1a2'), isTrue);
  });
}
