import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/models/contact.dart';

// A route the radio stores at one hash width while running at another can
// never deliver: the firmware sends it as stored and the first repeater
// strips the wrong number of bytes. Such routes are forgotten on sync.
void main() {
  Contact contact({
    required int pathLength,
    required List<int> path,
    required int pathHashSize,
  }) {
    return Contact(
      publicKey: Uint8List.fromList(List.filled(32, 7)),
      name: 'MADONNA',
      type: 2,
      pathLength: pathLength,
      path: Uint8List.fromList(path),
      pathHashSize: pathHashSize,
      lastSeen: DateTime(2026, 10, 10),
    );
  }

  const twoByteRoute = [0xA2, 0x77, 0xBE, 0xEF];

  test('a route at the radio width is fine', () {
    final c = contact(pathLength: 2, path: twoByteRoute, pathHashSize: 2);
    expect(MeshCoreConnector.routeWidthStale(c, 2), isFalse);
  });

  test('a route at another width is stale', () {
    // The same bytes labelled 4 × 1-byte on a 2-byte radio, or a 2-byte
    // route left behind after switching the radio to 1 byte.
    final mislabelled =
        contact(pathLength: 4, path: twoByteRoute, pathHashSize: 1);
    expect(MeshCoreConnector.routeWidthStale(mislabelled, 2), isTrue);

    final leftover = contact(pathLength: 2, path: twoByteRoute, pathHashSize: 2);
    expect(MeshCoreConnector.routeWidthStale(leftover, 1), isTrue);
  });

  test('flood, direct and empty routes are never stale', () {
    expect(
      MeshCoreConnector.routeWidthStale(
        contact(pathLength: -1, path: const [], pathHashSize: 1),
        2,
      ),
      isFalse,
    );
    expect(
      MeshCoreConnector.routeWidthStale(
        contact(pathLength: 0, path: const [], pathHashSize: 1),
        2,
      ),
      isFalse,
    );
    expect(
      MeshCoreConnector.routeWidthStale(
        contact(pathLength: 2, path: const [], pathHashSize: 1),
        2,
      ),
      isFalse,
    );
  });
}
