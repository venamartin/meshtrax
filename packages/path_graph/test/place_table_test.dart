import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:path_graph/path_graph.dart';
import 'package:test/test.dart';

Uint8List path(List<int> bytes) => Uint8List.fromList(bytes);

const selfPk = 'ab' 'ab' 'ab';
const bobPk = 'b0' 'b0' 'b0';
const a277 = [0xA2, 0x77];
const beef = [0xBE, 0xEF];
const minute = 60 * 1000;
const day = 24 * 60 * minute;

/// The place table (owner, 2026-10-25): where the radio is known, a
/// doorstep starts a route only if it was heard hearing me around here.
/// A row is eligibility, never a proof; the level measured here replaces
/// one measured elsewhere; rows fade after 30 days; they are never in an
/// export and only in a checkpoint on request.
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
  });

  tearDown(() => graph.dispose());

  void advance(int ms) => nowMillis += ms;

  /// Bob is reachable through A277 and BEEF alike (both proven, both end
  /// at his doorstep), so which one starts the route is down to my end.
  void corridors() {
    for (final hop in [a277, beef]) {
      graph.reportSendResult(path([...hop, ...hop]), true, contactPubkey: bobPk);
    }
  }

  String firstHop() =>
      ((graph.findPath(bobPk) as RouteResult).pathBytes.sublist(0, 2))
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join()
          .toUpperCase();

  test('with no cell nothing changes', () {
    corridors();
    expect(graph.findPath(bobPk), isA<RouteResult>());
    expect(graph.placesHere(), isEmpty);
  });

  test('where the radio is known, only doorsteps heard here start routes',
      () {
    corridors(); // proven, but with no cell: no rows written
    advance(4 * minute); // long enough ago that nothing is filed here
    graph.setPlace('c1_1', {'c1_2'});
    expect((graph.findPath(bobPk) as FloodResult).reason,
        FloodReason.doorstepsNotHere);

    // A277 echoes my flood here: a row, count only.
    graph.observeOwnEcho(path(a277), 2);
    expect(firstHop(), 'A277');
    expect(graph.placesHere()['A277']!.uplinkSnr, isNull);
    expect(graph.placesHere().containsKey('BEEF'), isFalse);
  });

  test('a Discover answer brings the level, which ranks ahead of a tally',
      () {
    corridors();
    graph.setPlace('c1_1', const {});
    graph.observeOwnEcho(path(a277), 2);
    graph.observeOwnEcho(path(beef), 2);
    graph.observeDiscoverResults(
        [const DiscoverResponse(repeaterHash: 'BEEF', uplinkSnr: 11)],
        failureEpisode: false);
    expect(graph.placesHere()['BEEF']!.uplinkSnr, 11);
    expect(firstHop(), 'BEEF');
  });

  test('a row is not a proof: it never resets the fail gate', () {
    corridors();
    advance(4 * minute); // long enough ago that nothing is filed here
    graph.setPlace('c1_1', const {});
    graph.observeOwnEcho(path(a277), 2);
    // Two failures from A277 trip D1 whatever the place rows say.
    graph.reportSendResult(path([...a277, ...a277]), false, contactPubkey: bobPk);
    graph.reportSendResult(path([...a277, ...a277]), false, contactPubkey: bobPk);
    graph.setPlace(null, const {});
    graph.setPlace('c1_1', const {});
    expect((graph.findPath(bobPk) as FloodResult).reason,
        FloodReason.doorstepsFailing);
  });

  test('one failure here holds the row until the doorstep proves here again',
      () {
    corridors();
    advance(4 * minute); // long enough ago that nothing is filed here
    graph.setPlace('c1_1', const {});
    graph.observeOwnEcho(path(a277), 2);
    graph.reportSendResult(path([...a277, ...a277]), false, contactPubkey: bobPk);
    expect((graph.findPath(bobPk) as FloodResult).reason,
        FloodReason.doorstepsNotHere);
    graph.observeOwnEcho(path(a277), 2);
    expect(firstHop(), 'A277');
  });

  test('the block around the cell counts; leaving it holds, deletes nothing',
      () {
    corridors();
    graph.setPlace('c1_1', {'c1_2'});
    graph.observeOwnEcho(path(a277), 2);
    graph.setPlace('c1_2', {'c1_1'}); // next door: the row still matches
    expect(firstHop(), 'A277');
    graph.setPlace('c9_9', const {}); // a drive away
    // Bob's way back is unknown, so the move rule speaks first; either
    // way the send floods and A277's row at home is untouched.
    expect((graph.findPath(bobPk) as FloodResult).reason,
        FloodReason.movedSinceTheyReachedMe);
    graph.reportFloodDelivered(bobPk);
    expect((graph.findPath(bobPk) as FloodResult).reason,
        FloodReason.doorstepsNotHere);
    graph.setPlace('c1_1', const {}); // back home: the row is still there
    expect(firstHop(), 'A277');
  });

  test('a direct reception from before the move no longer wins', () {
    graph.setPlace('c1_1', const {});
    graph.observePath(path([]), 2, const ObservationOrigin.pubkeyConfirmed(bobPk));
    expect(graph.findPath(bobPk), isA<DirectResult>());
    advance(minute);
    graph.setPlace('c9_9', const {});
    expect(graph.findPath(bobPk), isNot(isA<DirectResult>()));
  });

  test('proofs from the minutes before the first fix are filed under it',
      () {
    corridors(); // A277 and BEEF delivered just now, cell unknown
    advance(2 * minute);
    graph.setPlace('c1_1', const {});
    expect(graph.placesHere().keys, containsAll(['A277', 'BEEF']));
    expect(firstHop(), isIn(['A277', 'BEEF']));
  });

  test('older proofs are not, and a move backfills nothing', () {
    corridors();
    advance(4 * minute);
    graph.setPlace('c1_1', const {});
    expect(graph.placesHere(), isEmpty, reason: 'four minutes is too long ago');

    graph.observeOwnEcho(path(a277), 2);
    graph.setPlace('c9_9', const {});
    expect(graph.placesHere(), isEmpty, reason: 'a move carries nothing over');
  });

  test('rows fade after 30 days', () {
    graph.setPlace('c1_1', const {});
    graph.observeOwnEcho(path(a277), 2);
    advance(31 * day);
    final report = graph.sweepStale();
    expect(report.placesAged, 1);
    expect(graph.placesHere(), isEmpty);
  });

  test('never exported; in a checkpoint only on request; restored with it',
      () async {
    graph.setPlace('c1_1', const {});
    graph.observeOwnEcho(path(a277), 2);
    expect(graph.exportGraph().toString(), isNot(contains('c1_1')));
    expect(graph.saveSession().containsKey('places'), isFalse);
    final doc = graph.saveSession(includePlaces: true);
    expect(doc['places'], hasLength(1));

    await graph.clearLearnedData();
    expect(graph.placesHere(), isEmpty);
    await graph.loadSession(doc);
    graph.setPlace('c1_1', const {});
    expect(graph.placesHere().keys, ['A277']);

    await graph.loadSession(graph.saveSession());
    expect(graph.placesHere(), isEmpty, reason: 'a file without them restores none');
  });

  test('rows survive a restart', () async {
    final db = NativeDatabase.memory();
    final g1 = PathGraph(db, now: () => DateTime.fromMillisecondsSinceEpoch(nowMillis));
    await g1.init();
    g1.setRadioIdentity(selfPk, 2);
    g1.setPlace('c1_1', const {});
    g1.observeOwnEcho(path(a277), 2);
    await g1.flush();
    final g2 = PathGraph(db, now: () => DateTime.fromMillisecondsSinceEpoch(nowMillis));
    await g2.init();
    g2.setRadioIdentity(selfPk, 2);
    g2.setPlace('c1_1', const {});
    expect(g2.placesHere().keys, ['A277']);
    await g2.dispose();
  });
}
