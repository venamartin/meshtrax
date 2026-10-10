import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/models/path_selection.dart';

void main() {
  final route = Uint8List.fromList([0xA2, 0x77, 0xBE, 0xEF]);

  Contact contact({
    int pathLength = 2,
    int pathHashSize = 2,
    int? pathOverride,
    Uint8List? pathOverrideBytes,
  }) {
    return Contact(
      publicKey: Uint8List.fromList(List.filled(32, 9)),
      name: 'MADONNA',
      type: 2,
      pathLength: pathLength,
      path: route,
      pathHashSize: pathHashSize,
      pathOverride: pathOverride,
      pathOverrideBytes: pathOverrideBytes,
      lastSeen: DateTime(2026, 10, 10),
    );
  }

  test('a device route keeps the width it was learned at', () {
    final sel = resolvePathSelection(contact(), radioWidth: 1);

    expect(sel.useFlood, isFalse);
    expect(sel.hopCount, 2);
    expect(sel.hashSize, 2);
    expect(sel.pathBytes, route);
  });

  test('a user override is at the radio width', () {
    final sel = resolvePathSelection(
      contact(pathOverride: 1, pathOverrideBytes: Uint8List.fromList([0xA2, 0x77])),
      radioWidth: 2,
    );

    expect(sel.hopCount, 1);
    expect(sel.hashSize, 2);
  });

  test('a flood carries the radio width', () {
    final sel = resolvePathSelection(contact(pathLength: -1), radioWidth: 1);

    expect(sel.useFlood, isTrue);
    expect(sel.hashSize, 1);
    expect(sel.pathBytes, isEmpty);
  });
}
