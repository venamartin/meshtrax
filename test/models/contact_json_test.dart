import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/models/contact.dart';

// Contact.toJson/fromJson is the backup file format. Files written before
// the route width was recorded must still restore; only their routes are
// dropped, since nobody can say how those bytes were grouped.
void main() {
  final key = Uint8List.fromList(List.generate(32, (i) => i + 1));

  Map<String, dynamic> json() => Contact(
        publicKey: key,
        name: 'MADONNA',
        type: 2,
        pathLength: 2,
        path: Uint8List.fromList([0xA2, 0x77, 0xBE, 0xEF]),
        pathHashSize: 2,
        pathOverride: 1,
        pathOverrideBytes: Uint8List.fromList([0xA2, 0x77]),
        pathOverrideHashSize: 2,
        lastSeen: DateTime(2026, 10, 10),
      ).toJson();

  test('round-trips the route and override widths', () {
    final c = Contact.fromJson(json());

    expect(c.pathHashSize, 2);
    expect(c.pathLength, 2);
    expect(c.displayPathString, 'A277,BEEF');
    expect(c.pathOverrideHashSize, 2);
  });

  test('a file without a route width restores the contact route-less', () {
    final legacy = json()
      ..remove('pathHashSize')
      ..remove('pathOverrideHashSize');

    final c = Contact.fromJson(legacy);

    expect(c.name, 'MADONNA');
    expect(c.pathLength, -1);
    expect(c.path, isEmpty);
    expect(c.pathOverride, 1);
    expect(c.pathOverrideHashSize, isNull);
    expect(c.overrideHashSize(2), 2);
  });
}
