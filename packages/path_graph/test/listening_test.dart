import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show QueryExecutor;
import 'package:drift/native.dart';
import 'package:path_graph/path_graph.dart';
import 'package:test/test.dart';

Uint8List path(List<int> bytes) => Uint8List.fromList(bytes);

const selfPk = 'ab' 'ab' 'ab';
const hour = 60 * 60 * 1000;
const day = 24 * hour;

// Owner, 2026-11-28. Sightings fade with the clock, and the clock ran while
// the app was off or the radio away on another mesh: after a week not
// listening, half the far doorsteps of a field graph had lost their route,
// with nothing wrong with any link. They fade with the time listened.
void main() {
  var nowMillis = 1000000000000;
  PathGraph open(QueryExecutor db) => PathGraph(db,
      now: () => DateTime.fromMillisecondsSinceEpoch(nowMillis),
      config: const PathGraphConfig(newCodeConfirmMinutes: 0));

  void hear(PathGraph graph, int times) {
    for (var i = 0; i < times; i++) {
      graph.observePath(path([0xA2, 0x77, 0x13, 0x12]), 2,
          const ObservationOrigin.anonymous(), lastHopHeard: false);
    }
  }

  double held(PathGraph graph) => graph.estimator.decayedTraffic(
      graph.snapshot().edges[('A277', '1312')]!, nowMillis);

  setUp(() => nowMillis = 1000000000000);

  test('a week with the radio not listened to fades nothing', () async {
    final graph = open(NativeDatabase.memory());
    await graph.init();
    graph.setRadioIdentity(selfPk, 2);
    graph.setListening(true);
    hear(graph, 40);
    expect(held(graph), closeTo(40, 1e-6));

    graph.setListening(false);
    nowMillis += 7 * day;
    expect(held(graph), lessThan(4), reason: 'by the clock it is nearly gone');
    graph.setListening(true);
    expect(held(graph), closeTo(40, 1e-6),
        reason: 'it was not listened for: it is what it was');
    await graph.dispose();
  });

  test('time listened still fades it', () async {
    final graph = open(NativeDatabase.memory());
    await graph.init();
    graph.setRadioIdentity(selfPk, 2);
    graph.setListening(true);
    hear(graph, 40);
    nowMillis += 2 * day;
    expect(held(graph), closeTo(20, 1e-6), reason: 'heard nothing for 48 h');
    graph.setListening(false);
    nowMillis += 5 * day;
    graph.setListening(true);
    expect(held(graph), closeTo(20, 1e-6));
    nowMillis += 2 * day;
    expect(held(graph), closeTo(10, 1e-6));
    await graph.dispose();
  });

  test('a short break is not counted', () async {
    final graph = open(NativeDatabase.memory());
    await graph.init();
    graph.setRadioIdentity(selfPk, 2);
    graph.setListening(true);
    hear(graph, 40);
    graph.setListening(false);
    nowMillis += 30 * 60 * 1000;
    final before = held(graph);
    graph.setListening(true);
    expect(held(graph), before, reason: 'under an hour: left alone');
    await graph.dispose();
  });

  test('an app that was killed while listening is a gap too', () async {
    final dir = Directory.systemTemp.createTempSync('path_graph_listen');
    final file = File('${dir.path}/g.db');
    var graph = open(NativeDatabase(file));
    await graph.init();
    graph.setRadioIdentity(selfPk, 2);
    graph.setListening(true);
    hear(graph, 40);
    // Saved while listening, then gone with no word that it stopped.
    await graph.dispose();

    nowMillis += 4 * day;
    graph = open(NativeDatabase(file));
    await graph.init();
    graph.setRadioIdentity(selfPk, 2);
    expect(held(graph), closeTo(10, 1e-6));
    graph.setListening(true);
    expect(held(graph), closeTo(40, 1e-6));
    await graph.dispose();
    dir.deleteSync(recursive: true);
  });

  test('a sighting after the gap adds to what was held', () async {
    final graph = open(NativeDatabase.memory());
    await graph.init();
    graph.setRadioIdentity(selfPk, 2);
    graph.setListening(true);
    hear(graph, 40);
    graph.setListening(false);
    nowMillis += 7 * day;
    graph.setListening(true);
    hear(graph, 1);
    expect(held(graph), closeTo(41, 1e-6));
    await graph.dispose();
  });
}
