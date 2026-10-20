import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/helpers/timeout_helper.dart';
import 'package:meshtrax/models/contact.dart';

// Drive 2026-10-17: a failed flood waited ~50-60 s (8 assumed hops) while
// every ACK that came back took 15 s or less. Pathfinder's distance sizes
// the wait when it has one.

class _Connector extends MeshCoreConnector {}

Contact _bob({int pathLength = -1, int? inboundHops}) => Contact(
      publicKey: Uint8List.fromList(List.generate(32, (i) => 0xAA + i)),
      name: 'Bob',
      type: 1,
      pathLength: pathLength,
      path: Uint8List(pathLength > 0 ? pathLength * 2 : 0),
      pathHashSize: 2,
      inboundHopCount: inboundHops,
      lastSeen: DateTime(2026, 10, 17),
    );

void main() {
  // No radio params in a bare connector: airtime falls back to 50 ms.
  const airtime = 50;
  int flood(int hops) =>
      (TimeoutHelper.sendLegMs(airtime, hops) * 2).clamp(
          TimeoutHelper.minFloodMs, TimeoutHelper.maxMs);

  test('a flood waits for the distance Pathfinder knows', () {
    final c = _Connector()..graphDistanceTo = (_) => 2;
    expect(c.calculateTimeout(pathLength: -1, contact: _bob(inboundHops: 7)),
        flood(2));
  });

  test('without Pathfinder the advert distance, then the default, apply', () {
    final c = _Connector();
    expect(c.calculateTimeout(pathLength: -1, contact: _bob(inboundHops: 7)),
        flood(7));
    expect(c.calculateTimeout(pathLength: -1, contact: _bob()),
        flood(TimeoutHelper.defaultFloodHops));
    c.graphDistanceTo = (_) => null;
    expect(c.calculateTimeout(pathLength: -1, contact: _bob(inboundHops: 7)),
        flood(7), reason: 'nothing recent: the old estimate stands');
  });

  test('a direct send is unchanged', () {
    final c = _Connector()..graphDistanceTo = (_) => 2;
    expect(c.calculateTimeout(pathLength: 3, contact: _bob(pathLength: 3)),
        TimeoutHelper.sendLegMs(airtime, 3).clamp(0, TimeoutHelper.maxMs));
  });
}
