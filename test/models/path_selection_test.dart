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

  test("with no route known it is the radio's route: a flood at the radio "
      'width, unless the radio has learned one', () {
    final sel = resolvePathSelection(contact(pathLength: -1), radioWidth: 1);

    expect(sel.useFlood, isTrue);
    expect(sel.hashSize, 1);
    expect(sel.pathBytes, isEmpty);
    expect(sel.source, RouteSource.firmware);
  });

  test('a flood the user set, or a forced one, is a flood chosen as one', () {
    final userFlood = resolvePathSelection(contact(pathOverride: -1),
        radioWidth: 2);
    final forced = resolvePathSelection(contact(pathLength: -1),
        radioWidth: 2, forceFlood: true);

    for (final sel in [userFlood, forced]) {
      expect(sel.useFlood, isTrue);
      expect(sel.source, isNull);
    }
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

    test('re-planning the rest of a ladder: tried routes are skipped and the '
        'owed floods still close it', () {
      // Budget 4 planned [g1, g2, flood, flood]; g1 was sent and failed,
      // and Pathfinder now ranks g3 first.
      final tail = planAttempts(contact(),
          radioWidth: 2,
          budget: 3,
          graphRoutes: [g3, g1, g2],
          tried: [g1],
          floods: 2);
      expect(tail.first.pathBytes, g3.pathBytes,
          reason: 'the best route not yet tried, whatever its score');
      expect(kinds(tail), ['graph', 'flood', 'flood']);

      // Two rungs sent (g1, g2): only the two floods are owed.
      expect(
          kinds(planAttempts(contact(),
              radioWidth: 2,
              budget: 2,
              graphRoutes: [g3],
              tried: [g1, g2],
              floods: 2)),
          ['flood', 'flood']);
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

    test('the best route is tried whatever its score', () {
      // Field 2026-10-14: three links nobody had sent on scored the best
      // route to a contact 14%, its alternatives 7% and 4%, and every
      // message flooded. The best is tried; the weak alternatives are not.
      final best = graph([0xA2, 0x77, 0x10, 0x00, 0x88, 0x02], 0.14);
      final alt1 = graph([0xA2, 0x77, 0xAD, 0x77, 0x10, 0x00, 0x88, 0x02], 0.07);
      final alt2 = graph([0xA2, 0x77, 0x44, 0x4A, 0x88, 0x02], 0.035);
      final routes = [best, alt1, alt2];
      expect(kinds(plan(contact(), budget: 3, graphRoutes: routes)),
          ['graph', 'flood', 'flood']);
      expect(plan(contact(), budget: 3, graphRoutes: routes).first.pathBytes,
          best.pathBytes);
      // 7% clears the 5% cutoff; 3.5% does not.
      expect(
          [
            for (final s in plan(contact(), budget: 5, graphRoutes: routes))
              s.useFlood ? 'flood' : s.pathBytes
          ],
          [best.pathBytes, alt1.pathBytes, 'flood', 'flood', 'flood']);
    });

    test('later routes below the delivery threshold are skipped', () {
      final weak = graph([0x11, 0x11, 0x10, 0x00], 0.04);
      final ladder = plan(contact(), budget: 5, graphRoutes: [g1, weak, g2]);
      expect([for (final s in ladder) s.useFlood ? 'flood' : s.pathBytes], [
        g1.pathBytes,
        g2.pathBytes,
        'flood',
        'flood',
        'flood',
      ]);
    });

    test('zero-hop routes at two widths take one slot', () {
      PathSelection direct(int width) => PathSelection(
          pathBytes: const [],
          hopCount: 0,
          hashSize: width,
          useFlood: false,
          source: RouteSource.graph);
      final ladder =
          plan(contact(), budget: 4, graphRoutes: [direct(2), direct(1), g2]);
      expect([for (final s in ladder) s.useFlood ? 'flood' : s.hopCount],
          [0, 2, 'flood', 'flood']);
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

    test("only the firmware ladder's route tries are the radio's route; every "
        'other flood is one the ladder chose', () {
      List<RouteSource?> sources(List<PathSelection> plan) =>
          [for (final s in plan) s.source];
      final none = contact(pathLength: -1);

      expect(sources(plan(none, budget: 4)),
          [RouteSource.firmware, RouteSource.firmware, null, null]);
      expect(sources(plan(none, budget: 3)), [RouteSource.firmware, null, null]);
      expect(sources(plan(none, budget: 3, floodFirst: true)), [null, null, null]);
      expect(sources(plan(none, budget: 3, graphRoutes: [])), [null, null, null]);
      expect(sources(plan(contact(), budget: 3, graphRoutes: [g1])).skip(1),
          [null, null]);
      expect(sources(plan(contact(pathOverride: -1), budget: 3)),
          [null, null, null]);
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

  // Owner, 2026-11-24: a missed ACK is most often two radios sending at
  // once, about one try in four at home, so one is no reason to leave a
  // route. Pathfinder's first choice gets two tries.
  group("a DM's ladder: the best route twice", () {
    PathSelection via(List<int> bytes, {double est = 0.6}) => PathSelection(
          pathBytes: bytes,
          hopCount: bytes.length ~/ 2,
          hashSize: 2,
          useFlood: false,
          source: RouteSource.graph,
          estDelivery: est,
        );
    // Three ways to the contact's repeater AA77, and one to C0DE.
    final best = via([0xA2, 0x77, 0xAA, 0x77], est: 0.74);
    final second = via([0xA2, 0x77, 0xF5, 0xEE, 0xAA, 0x77], est: 0.55);
    final third = via([0xA2, 0x77, 0xBE, 0xEF, 0xAA, 0x77], est: 0.48);
    final elsewhere = via([0xA2, 0x77, 0xC0, 0xDE], est: 0.3);
    final none = Contact(
      publicKey: Uint8List.fromList(List.filled(32, 9)),
      name: 'B',
      type: 1,
      pathLength: -1,
      path: Uint8List(0),
      pathHashSize: 2,
      lastSeen: DateTime(2026, 11, 24),
    );

    String name(PathSelection s) => s.useFlood
        ? 'flood'
        : identical(s, best)
            ? 'best'
            : identical(s, second)
                ? 'second'
                : identical(s, third)
                    ? 'third'
                    : 'elsewhere';

    List<String> ladder(int budget, List<PathSelection> routes,
            {List<PathSelection> tried = const [], int? floods}) =>
        planAttempts(none,
                radioWidth: 2,
                budget: budget,
                graphRoutes: routes,
                tried: tried,
                floods: floods,
                bestTwice: true)
            .map(name)
            .toList();

    test('five tries: best, best, the next route, then two floods', () {
      expect(ladder(5, [best, second, third]),
          ['best', 'best', 'second', 'flood', 'flood']);
    });

    test('four tries: best, best, two floods', () {
      expect(ladder(4, [best, second]), ['best', 'best', 'flood', 'flood']);
    });

    test('three tries: best, best, and one flood', () {
      expect(ladder(3, [best, second]), ['best', 'best', 'flood']);
    });

    test('two tries and one: the route, then a flood; the route alone', () {
      expect(ladder(2, [best, second]), ['best', 'flood']);
      expect(ladder(1, [best, second]), ['best']);
    });

    test('one route known: it is tried twice, never a third time', () {
      expect(ladder(5, [best]), ['best', 'best', 'flood', 'flood', 'flood']);
    });

    test('the next route ends at another repeater (their latest packet was '
        'heard there): it goes second, and the best gets its second try after',
        () {
      expect(ladder(5, [best, elsewhere, second]),
          ['best', 'elsewhere', 'best', 'flood', 'flood']);
    });

    test('planned again after the first try, the next route ending at '
        'another repeater: that one, then the best route again', () {
      expect(ladder(4, [best, elsewhere, second], tried: [best], floods: 2),
          ['elsewhere', 'best', 'flood', 'flood']);
    });

    // Simulator, 2026-11-24: after the route to the other repeater failed,
    // a second route there took the last route slot from an 82% route.
    test('planned again after the route to the other repeater was tried: '
        "the best route's second try comes before another route there", () {
      final again = via([0xA2, 0x77, 0x10, 0x00, 0xC0, 0xDE], est: 0.16);
      expect(
          ladder(3, [best, again, second],
              tried: [best, elsewhere], floods: 2),
          ['best', 'flood', 'flood']);
      expect(
          ladder(4, [best, again, second],
              tried: [best, elsewhere], floods: 2),
          ['best', 'elsewhere', 'flood', 'flood']);
    });

    test('planned again after the first try failed: its second try is next',
        () {
      expect(ladder(4, [best, second], tried: [best], floods: 2),
          ['best', 'second', 'flood', 'flood']);
    });

    test('planned again after both of its tries: the next route, then floods',
        () {
      expect(ladder(3, [best, second, third], tried: [best, best], floods: 2),
          ['second', 'flood', 'flood']);
    });

    test('planned again with a new best route: that one gets two tries', () {
      expect(ladder(4, [second, best], tried: [best], floods: 2),
          ['second', 'second', 'flood', 'flood']);
    });

    test('a weak second route is left out while better is on offer', () {
      final weak = via([0xA2, 0x77, 0x10, 0x00, 0xAA, 0x77], est: 0.02);
      expect(ladder(5, [best, weak]).where((n) => n != 'best' && n != 'flood'),
          isEmpty);
    });

    // Simulator, 2026-11-24: a contact who had moved was reachable only
    // over long unproven routes; none of 55 tries on them was answered.
    test('a best route that is unlikely to work gets one try, and the '
        'ladder is as it was', () {
      final long = via([0xA2, 0x77, 0x10, 0x00, 0x40, 0x00], est: 0.12);
      final longer =
          via([0xA2, 0x77, 0x10, 0x00, 0x20, 0x00, 0xF4, 0xD5], est: 0.06);
      List<String> kinds(int budget) => planAttempts(none,
              radioWidth: 2,
              budget: budget,
              graphRoutes: [long, longer],
              bestTwice: true)
          .map((s) => s.useFlood
              ? 'flood'
              : identical(s, long)
                  ? 'long'
                  : 'longer')
          .toList();
      expect(kinds(5), ['long', 'longer', 'flood', 'flood', 'flood']);
      expect(kinds(3), ['long', 'flood', 'flood']);
    });

    test('just likely enough: twice', () {
      final even = via([0xA2, 0x77, 0xAA, 0x77], est: repeatMinDelivery);
      expect(
          planAttempts(none,
                  radioWidth: 2,
                  budget: 3,
                  graphRoutes: [even],
                  bestTwice: true)
              .map((s) => s.useFlood),
          [false, false, true]);
    });

    test('Pathfinder knows nothing: every try floods', () {
      expect(ladder(3, const []), ['flood', 'flood', 'flood']);
    });

    test('other ladders are as they were: each route once', () {
      expect(
          planAttempts(none,
                  radioWidth: 2, budget: 5, graphRoutes: [best, second, third])
              .map(name),
          ['best', 'second', 'third', 'flood', 'flood']);
    });
  });
}
