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
    int? pathOverrideHashSize,
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
      pathOverrideHashSize: pathOverrideHashSize,
      lastSeen: DateTime(2026, 10, 10),
    );
  }

  test('a device route keeps the width it was learned at', () {
    final sel = resolvePathSelection(contact(), radioWidth: 1);

    expect(sel.useFlood, isFalse);
    expect(sel.hopCount, 2);
    expect(sel.hashSize, 2);
    expect(sel.pathBytes, route);
    expect(sel.source, RouteSource.firmware);
  });

  test('a user override keeps the width it was set at', () {
    // Set as two 1-byte hops; the radio has since moved to 2 bytes. The
    // override must not be re-read as one 2-byte hop.
    final sel = resolvePathSelection(
      contact(
        pathOverride: 2,
        pathOverrideBytes: Uint8List.fromList([0xA2, 0x77]),
        pathOverrideHashSize: 1,
      ),
      radioWidth: 2,
    );

    expect(sel.hopCount, 2);
    expect(sel.hashSize, 1);
    expect(sel.source, RouteSource.custom);
  });

  test('an override saved without a width is at the radio width', () {
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
    expect(sel.source, isNull);
  });

  group('planAttempts', () {
    PathSelection graph(List<int> bytes, double est) => PathSelection(
          pathBytes: bytes,
          hopCount: bytes.length ~/ 2,
          hashSize: 2,
          useFlood: false,
          source: RouteSource.graph,
          estDelivery: est,
        );
    final g1 = graph([0xA2, 0x77, 0xA1, 0x77, 0x10, 0x00], 0.8);
    final g2 = graph([0xA2, 0x77, 0x10, 0x00], 0.5);
    final g3 = graph([0xBE, 0xEF, 0x10, 0x00], 0.3);

    List<String> kinds(List<PathSelection> plan) =>
        [for (final s in plan) s.useFlood ? 'flood' : s.source!.name];

    List<PathSelection> plan(
      Contact c, {
      required int budget,
      List<PathSelection>? graphRoutes,
      bool floodFirst = false,
    }) =>
        planAttempts(c,
            radioWidth: 2,
            budget: budget,
            graphRoutes: graphRoutes,
            floodFirst: floodFirst);

    test('graph routes first, best first, two floods close the ladder', () {
      final all = [g1, g2, g3];
      expect(kinds(plan(contact(), budget: 5, graphRoutes: all)),
          ['graph', 'graph', 'graph', 'flood', 'flood']);
      expect(kinds(plan(contact(), budget: 4, graphRoutes: all)),
          ['graph', 'graph', 'flood', 'flood']);
      expect(kinds(plan(contact(), budget: 3, graphRoutes: all)),
          ['graph', 'flood', 'flood']);
      expect(plan(contact(), budget: 3, graphRoutes: all).first.pathBytes,
          g1.pathBytes);
    });

    test('a slot the graph left free floods; the stored route is never tried',
        () {
      // Owner rule 2026-10-14: with Pathfinder on, the radio's stored route
      // is never a rung.
      expect(kinds(plan(contact(), budget: 4, graphRoutes: [g1])),
          ['graph', 'flood', 'flood', 'flood']);
      expect(kinds(plan(contact(), budget: 5, graphRoutes: [g1])),
          ['graph', 'flood', 'flood', 'flood', 'flood']);
    });

    test('a stored route never appears in a Pathfinder ladder', () {
      for (final budget in [1, 2, 3, 4, 5]) {
        for (final routes in [<PathSelection>[], [g1], [g1, g2, g3]]) {
          expect(kinds(plan(contact(), budget: budget, graphRoutes: routes)),
              isNot(contains('firmware')));
        }
      }
    });

    test('Pathfinder has nothing: every attempt floods', () {
      expect(kinds(plan(contact(), budget: 4, graphRoutes: [])),
          ['flood', 'flood', 'flood', 'flood']);
      expect(kinds(plan(contact(), budget: 3, graphRoutes: [])),
          ['flood', 'flood', 'flood']);
    });

    test('no route of any kind floods every attempt', () {
      expect(kinds(plan(contact(pathLength: -1), budget: 3, graphRoutes: [])),
          ['flood', 'flood', 'flood']);
    });

    test('budgets of 1 and 2', () {
      expect(kinds(plan(contact(), budget: 1, graphRoutes: [g1])), ['graph']);
      expect(kinds(plan(contact(), budget: 2, graphRoutes: [g1])),
          ['graph', 'flood']);
      expect(kinds(plan(contact(pathLength: -1), budget: 1, graphRoutes: [])),
          ['flood']);
      expect(kinds(plan(contact(), budget: 2, graphRoutes: [])),
          ['flood', 'flood']);
    });

    test('routes below the delivery threshold are skipped', () {
      final weak = graph([0x11, 0x11, 0x10, 0x00], 0.1);
      final ladder = plan(contact(), budget: 3, graphRoutes: [weak, g2]);
      expect(ladder.first.pathBytes, g2.pathBytes);
    });

    test('a graph direct hit is a zero-hop route, not a flood', () {
      final direct = const PathSelection(
          pathBytes: [],
          hopCount: 0,
          hashSize: 2,
          useFlood: false,
          source: RouteSource.graph);
      final ladder = plan(contact(), budget: 3, graphRoutes: [direct]);
      expect(ladder.first.useFlood, isFalse);
      expect(ladder.first.hopCount, 0);
      expect(kinds(ladder), ['graph', 'flood', 'flood']);
    });

    test('Pathfinder off keeps the firmware ladder', () {
      expect(kinds(plan(contact(), budget: 4)),
          ['firmware', 'firmware', 'flood', 'flood']);
      expect(kinds(plan(contact(), budget: 3)), ['firmware', 'flood', 'flood']);
      expect(kinds(plan(contact(pathLength: -1), budget: 3)),
          ['flood', 'flood', 'flood']);
    });

    test('a user override keeps its ladder and ignores the graph', () {
      final c = contact(
          pathOverride: 1, pathOverrideBytes: Uint8List.fromList([0x33]));
      expect(kinds(plan(c, budget: 4, graphRoutes: [g1])),
          ['custom', 'custom', 'flood', 'flood']);
      expect(kinds(plan(c, budget: 3, graphRoutes: [g1], floodFirst: true)),
          ['custom', 'flood', 'flood']);
    });

    test('a manual resend floods every attempt', () {
      expect(kinds(plan(contact(), budget: 3, graphRoutes: [g1], floodFirst: true)),
          ['flood', 'flood', 'flood']);
      expect(kinds(plan(contact(), budget: 3, floodFirst: true)),
          ['flood', 'flood', 'flood']);
    });
  });
}
