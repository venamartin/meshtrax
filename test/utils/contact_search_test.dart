import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/models/contact_note.dart';
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
  const note = ContactNote(nickname: 'Annie', realName: 'Ann Smith');

  test('finds a contact by its radio name or either name given it', () {
    expect(matchesContactQuery(contact, 'walker'), isTrue);
    expect(matchesContactQuery(contact, 'smith'), isFalse);
    expect(matchesContactQuery(contact, 'smith', note: note), isTrue);
    expect(matchesContactQuery(contact, 'annie', note: note), isTrue);
    expect(matchesContactQuery(contact, 'walker', note: note), isTrue);
    expect(matchesContactQuery(contact, 'bob', note: note), isFalse);
  });

  test('still finds a contact by the start of its key', () {
    expect(matchesContactQuery(contact, 'a0a1a2'), isTrue);
  });
}
