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
const c0de = [0xC0, 0xDE];
const r036e = [0x03, 0x6E];
const r4000 = [0x40, 0x00];
const f4d5 = [0xF4, 0xD5];

/// Field 2026-11-21. Morning: a contact 35 km from home was sent to
/// through their home doorstep AA77 on every route attempt, then by flood,
/// while AA77 stood fourth in the path of both of their DMs and a route to
/// the repeater that heard them was known. Evening: a rule that put the
/// newest sighting first and erased the records sent a contact who had not
/// moved to one-off repeaters, then to floods. The owner: use the repeater
/// that heard them, and use what is stored before flooding.
void main() {
  late PathGraph graph;
  var nowMillis = 1000000000;

  Future<void> open({bool newestBeforeRecord = false}) async {
    nowMillis = 1000000000;
    graph = PathGraph(NativeDatabase.memory(),
        now: () => DateTime.fromMillisecondsSinceEpoch(nowMillis),
        config: PathGraphConfig(
            newCodeConfirmMinutes: 0,
            newestBeforeRecord: newestBeforeRecord));
    await graph.init();
    graph.setRadioIdentity(selfPk, 2);
    // A277 hears me, proven; the corridors heard going out from it.
    for (var i = 0; i < 4; i++) {
      graph.reportSendResult(path(a277), true);
    }
    for (final hops in [
      [...a277, ...aa77, ...r036e, ...f4d5],
      [...a277, ...f5ee, ...aa77],
      [...a277, ...f5ee, ...c0de],
    ]) {
      for (final id in ['x', 'y']) {
        graph.observePath(path(hops), 2, const ObservationOrigin.anonymous(),
            lastHopHeard: false, messageId: '$id$hops');
      }
    }
  }

  tearDown(() => graph.dispose());

  var packets = 0;

  /// One packet surely theirs, heard on [hops].
  void heard(List<int> hops, {String? id}) => graph.observeContactSender(
      contactPk, path(hops), 2,
      confirmed: true, messageId: id ?? 'p${packets++}');

  /// Twenty DMs at home, each heard first by AA77 and answered through it.
  void atHome() {
    for (var i = 0; i < 20; i++) {
      heard([...aa77, ...a277]);
      graph.reportSendResult(path([...a277, ...aa77]), true,
          contactPubkey: contactPk);
      nowMillis += 20 * 60 * 1000;
    }
  }

  List<int> doorstepOf(RouteResult r) =>
      r.pathBytes.sublist(r.pathBytes.length - 2);

  /// The doorsteps a message's route attempts end at, in order.
  List<List<int>> ladder() {
    final routes = graph.findRoutes(contactPk);
    final ends = <List<int>>[];
    for (final r in [routes.best as RouteResult, ...routes.alternatives]) {
      final end = doorstepOf(r);
      if (!ends.any((e) => e.join() == end.join())) ends.add(end);
    }
    return ends;
  }

  double weightOf(String hash) => graph
      .ingressCandidates(contactPk)
      .firstWhere((c) => c.repeaterHash == hash)
      .weight;

  test('the attempts after the best one go to their other doorsteps', () async {
    await open();
    atHome();
    heard([...f5ee, ...a277]);
    final routes = graph.findRoutes(contactPk);
    expect((routes.best as RouteResult).pathBytes, [...a277, ...aa77]);
    expect(routes.alternatives.map((r) => r.pathBytes), [
      [...a277, ...f5ee], // their other doorstep first
      [...a277, ...aa77], // the best one again, as before
      [...a277, ...f5ee, ...aa77], // then another corridor to AA77
    ]);
  });

  test('a doorstep that only passed their packet on comes last, record kept',
      () async {
    await open();
    atHome();
    final before = weightOf('AA77');

    // 35 km away: F4D5 heard them; AA77 passed it on fourth.
    heard([...f4d5, ...r036e, ...r4000, ...aa77, ...a277]);
    expect(ladder(), [f4d5, aa77],
        reason: 'the repeater that heard them, then the record');
    expect(weightOf('AA77'), closeTo(before * 0.5, 0.01),
        reason: 'halved as any sighting does, not erased');

    // Home again: AA77 hears them first.
    nowMillis += 60 * 1000;
    heard([...aa77, ...a277]);
    expect(ladder().first, aa77);
  });

  test('one sighting through another repeater leaves the record first, and '
      'that repeater is the next attempt', () async {
    await open();
    atHome();
    heard([...c0de, ...f5ee, ...a277]);
    expect(ladder(), [aa77, c0de]);
  });

  test('while their latest packet came through the doorstep ranked first, '
      'the next attempt is another way to it, not an old one-off', () async {
    await open();
    atHome();
    heard([...c0de, ...f5ee, ...a277]);
    nowMillis += 60 * 1000;
    heard([...aa77, ...a277]);
    final routes = graph.findRoutes(contactPk);
    expect((routes.best as RouteResult).pathBytes, [...a277, ...aa77]);
    expect(routes.alternatives.take(2).map((r) => r.pathBytes), [
      [...a277, ...aa77],
      [...a277, ...f5ee, ...aa77],
    ], reason: 'a first attempt can fail by bad luck');
  });

  test('a doorstep their packet overruled keeps the last route attempt when '
      'it has a delivery record', () async {
    await open();
    // Three corridors to F4D5.
    for (final hops in [
      [...a277, ...f5ee, ...f4d5],
      [...a277, ...f5ee, ...c0de, ...f4d5],
    ]) {
      graph.observePath(path(hops), 2, const ObservationOrigin.anonymous(),
          lastHopHeard: false, messageId: 'z$hops');
    }
    atHome();
    heard([...f4d5, ...r036e, ...r4000, ...aa77, ...a277]);
    final routes = graph.findRoutes(contactPk);
    expect(doorstepOf(routes.best as RouteResult), f4d5);
    expect(routes.alternatives, hasLength(3));
    expect(routes.alternatives.last.pathBytes, [...a277, ...aa77],
        reason: 'one packet that overruled it can be a fluke');
  });

  // Simulator 2026-11-22: with one doorstep on my end, two failed route
  // attempts of one message closed every route, so the ladder's last route
  // attempt never came: two messages lost that master delivered.
  test('a failure through a second opinion on their end is not held against '
      'my doorstep', () async {
    await open();
    atHome();
    heard([...c0de, ...f5ee, ...a277]); // a stray heard them
    int myFails() => graph
        .egressCandidates()
        .firstWhere((c) => c.repeaterHash == 'A277')
        .failedSinceProof;
    graph.reportSendResult(path([...a277, ...f5ee, ...c0de]), false,
        contactPubkey: contactPk);
    expect(myFails(), 0, reason: 'C0DE heard them and never delivered');
    graph.reportSendResult(path([...a277, ...aa77]), false,
        contactPubkey: contactPk);
    expect(myFails(), 1, reason: 'a failure through the record counts');
  });

  test('bad luck on the record, then the stray, then the record again by '
      'another way', () async {
    await open();
    atHome();
    heard([...c0de, ...f5ee, ...a277]);
    RouteResult best() => graph.findPath(contactPk) as RouteResult;
    expect(best().pathBytes, [...a277, ...aa77]);

    graph.reportSendResult(path([...a277, ...aa77]), false,
        contactPubkey: contactPk);
    expect(doorstepOf(best()), c0de,
        reason: 'the record failed; the repeater that heard them is next');

    graph.reportSendResult(path([...a277, ...f5ee, ...c0de]), false,
        contactPubkey: contactPk);
    expect(doorstepOf(best()), aa77, reason: 'the stray failed too');
    expect(
        graph.findRoutes(contactPk).alternatives.map((r) => r.pathBytes),
        contains(equals([...a277, ...f5ee, ...aa77])),
        reason: 'another way to the record, with my doorstep still open');
  });

  test('two of their packets in a row without it, and it comes last',
      () async {
    await open();
    atHome();
    heard([...c0de, ...f5ee, ...a277]);
    heard([...c0de, ...f5ee, ...a277]);
    expect(ladder(), [c0de, aa77]);
  });

  test('one packet heard first far from their doorstep moves nothing: a '
      'high site hears them far from home', () async {
    await open();
    // About 90 km apart.
    graph.ingestNode('AA77', lat: 10.0, lon: 10.0);
    graph.ingestNode('C0DE', lat: 10.8, lon: 10.0);
    atHome();
    final before = weightOf('AA77');
    heard([...c0de, ...f5ee, ...a277]);
    expect(ladder(), [aa77, c0de],
        reason: 'the record first, the repeater that heard them next');
    expect(weightOf('AA77'), closeTo(before * 0.5, 0.01),
        reason: 'halved as by any sighting elsewhere, never wiped');

    heard([...c0de, ...f5ee, ...a277]);
    expect(ladder(), [c0de, aa77], reason: 'two in a row without it');
  });

  test('copies of one packet are one sighting', () async {
    await open();
    atHome();
    // One advert, heard twice: by AA77, then by C0DE.
    heard([...aa77, ...a277], id: 'advert');
    final afterFirst = weightOf('AA77');
    heard([...c0de, ...f5ee, ...a277], id: 'advert');
    expect(weightOf('AA77'), closeTo(afterFirst, 0.01),
        reason: 'the second copy pushes nothing down');
    expect(ladder(), [aa77, c0de]);

    // The next packet through C0DE alone is AA77's first miss, not its
    // second.
    heard([...c0de, ...f5ee, ...a277]);
    expect(ladder(), [aa77, c0de]);
  });

  test('newestBeforeRecord: who heard their latest packet goes first',
      () async {
    await open(newestBeforeRecord: true);
    atHome();
    heard([...c0de, ...f5ee, ...a277]);
    expect(ladder(), [c0de, aa77]);
    heard([...aa77, ...a277]);
    expect(ladder().first, aa77);
  });

  test('with one doorstep, the next attempts are other corridors to it',
      () async {
    await open();
    atHome();
    final routes = graph.findRoutes(contactPk);
    expect(routes.alternatives.map((r) => r.pathBytes), [
      [...a277, ...aa77],
      [...a277, ...f5ee, ...aa77],
    ]);
  });
}
