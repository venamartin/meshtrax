import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:path_graph/path_graph.dart';
import 'package:test/test.dart';

Uint8List path(List<int> bytes) => Uint8List.fromList(bytes);

const selfPk = 'ab' 'ab' 'ab';
const contactPk = 'c1' 'c1' 'c1';

const a277 = [0xA2, 0x77];
const aa77 = [0xAA, 0x77];
const f5ee = [0xF5, 0xEE];
const r036e = [0x03, 0x6E];
const r4000 = [0x40, 0x00];
const f4d5 = [0xF4, 0xD5];

/// Field 2026-11-21: a contact's home doorstep AA77 (45 sightings, 32
/// deliveries) kept every route after they moved 35 km, while their DMs
/// came in through F4D5 and FD33 with AA77 four hops down the paths. The
/// way to F4D5 was known; one new sighting only halved AA77. Owner: use the
/// repeater that heard them.
void main() {
  late PathGraph graph;
  var nowMillis = 1000000000;

  setUp(() async {
    nowMillis = 1000000000;
    graph = PathGraph(NativeDatabase.memory(),
        now: () => DateTime.fromMillisecondsSinceEpoch(nowMillis),
        config: const PathGraphConfig(newCodeConfirmMinutes: 0));
    await graph.init();
    graph.setRadioIdentity(selfPk, 2);
    // A277 hears me, proven, and carries much of my traffic to AA77.
    for (var i = 0; i < 4; i++) {
      graph.reportSendResult(path(a277), true);
    }
    for (final hops in [
      [...a277, ...aa77, ...r036e, ...f4d5],
      [...aa77, ...r036e, ...r4000],
      [...a277, ...f5ee],
    ]) {
      for (final id in ['x', 'y']) {
        graph.observePath(path(hops), 2, const ObservationOrigin.anonymous(),
            lastHopHeard: false, messageId: '$id$hops');
      }
    }
  });

  tearDown(() => graph.dispose());

  List<int> route() => (graph.findPath(contactPk) as RouteResult).pathBytes;

  void heardVia(List<int> hops) => graph.observeContactSender(
      contactPk, path(hops), 2, confirmed: true);

  test('one DM through a new repeater moves their route there', () {
    for (var i = 0; i < 20; i++) {
      heardVia([...aa77, ...a277]);
      graph.reportSendResult(path([...a277, ...aa77]), true,
          contactPubkey: contactPk);
      nowMillis += 20 * 60 * 1000;
    }
    expect(route(), [...a277, ...aa77], reason: 'at home');

    // After the move: F4D5 heard them first; AA77 only after three
    // repeaters.
    heardVia([...f4d5, ...r036e, ...r4000, ...aa77, ...a277]);
    expect(route().sublist(route().length - 2), f4d5,
        reason: 'the repeater that heard them ends the route');
    expect(route(), [...a277, ...aa77, ...r036e, ...f4d5]);
  });

  test('two repeaters that both hear them at home take turns', () {
    heardVia([...aa77, ...a277]);
    expect(route(), [...a277, ...aa77]);
    heardVia([...f5ee, ...a277]);
    expect(route(), [...a277, ...f5ee]);
    heardVia([...aa77, ...a277]);
    expect(route(), [...a277, ...aa77]);
  });

  test('with no way known to the newest repeater, the old one is the '
      'fallback', () {
    heardVia([...aa77, ...a277]);
    // 1312 is new to the graph: no corridor reaches it.
    heardVia([0x13, 0x12, ...a277]);
    expect(route(), [...a277, ...aa77]);
    expect((graph.findPath(contactPk) as RouteResult).estDelivery,
        lessThan(0.1), reason: 'a fallback, and priced as one');
  });
}
