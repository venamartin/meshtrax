import 'dart:math' as math;
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:path_graph/path_graph.dart';
import 'package:test/test.dart';

void main() {
  const config = PathGraphConfig();
  const est = Estimator(config);
  const hour = 60 * 60 * 1000;

  /// [n] - [s] failures, all just now.
  EdgeState edge({int s = 0, int n = 0, double traffic = 0, int? last,
      double? measuredSnr, int obs = 0}) {
    return EdgeState(source: 'observed')
      ..s = s
      ..n = n
      ..failWeight = (n - s).toDouble()
      ..lastFailed = n > s ? 0 : null
      ..trafficWeight = traffic
      ..lastObserved = last
      ..obsCount = obs
      ..measuredSnr = measuredSnr;
  }

  test('traffic halves after one half-life', () {
    final e = edge(traffic: 10, last: 0);
    final t = est.decayedTraffic(
        e, (config.trafficHalfLifeHours * hour).round());
    expect(t, closeTo(5, 1e-9));
  });

  test('snr map is monotone and clamped', () {
    expect(est.snrQuality(config.snrZeroQualityDb - 5), 0);
    expect(est.snrQuality(config.snrFullQualityDb + 5), 1);
    expect(est.snrQuality(0), greaterThan(est.snrQuality(-10)));
  });

  test('a traced edge routes at its measured SNR', () {
    final e = edge(measuredSnr: 6.0);
    expect(est.calibratedP(e, 0), closeTo(est.snrQuality(6.0), 1e-9),
        reason: 'no attempts -> the measured prior stands alone');
    expect(est.usable(e, 0), isTrue);
  });

  // Owner, 2026-11-27: "If repeater A hears repeater B 1000 times it is
  // good." Every unmeasured link used to stand at one fixed 50%.
  test('an unmeasured link is rated by how often it is heard', () {
    expect(est.heardQuality(edge(traffic: 1, last: 0), 0), closeTo(1 / 11, 1e-9));
    expect(est.heardQuality(edge(traffic: config.heardHalf, last: 0), 0),
        closeTo(0.5, 1e-9));
    expect(est.heardQuality(edge(traffic: 1000, last: 0), 0), greaterThan(0.98));
    final days8 = (4 * config.trafficHalfLifeHours * hour).round();
    expect(est.heardQuality(edge(traffic: 160, last: 0), days8),
        closeTo(0.5, 1e-9),
        reason: 'not heard for four half-lives: a sixteenth is left');
    expect(est.usable(edge(traffic: 1, last: 0, obs: 1), 0), isTrue,
        reason: 'heard once just now: weak, still a link');
    expect(est.usable(edge(traffic: 1, last: 0, obs: 1), days8), isFalse,
        reason: 'heard once, days ago: gone');
  });

  // Owner, 2026-11-28: "A to B heard many times we have to presume B to
  // A. If we find it fails, then it loses weight."
  test('a link is rated by the direction it is heard best in', () {
    final often = edge(traffic: 1000, last: 0, obs: 1000);
    final seldom = edge(traffic: 1, last: 0, obs: 1);
    final q = est.heardQuality;
    expect(est.priorQuality(seldom, 0, reverse: often), q(often, 0),
        reason: 'the way heard well stands for the way out');
    expect(est.priorQuality(often, 0, reverse: seldom), q(often, 0));
    expect(est.priorQuality(often, 0), q(often, 0),
        reason: 'heard one way only: presumed as good the other way');
    expect(est.priorQuality(null, 0, reverse: often), q(often, 0),
        reason: 'never heard this way at all');
    expect(est.presumedP(often, 0), closeTo(q(often, 0), 1e-9));
    expect(est.priorQuality(seldom, 0, reverse: seldom), q(seldom, 0));
  });

  test('failures take weight from the direction they were in', () {
    final often = edge(traffic: 1000, last: 0, obs: 1000);
    // Sent on six times and never heard this way, with no delivery.
    final tried = edge(s: 0, n: 6);
    expect(est.hasEvidence(tried), isFalse);
    expect(est.usable(tried, 0, reverse: often), isTrue,
        reason: 'the other way is the evidence');
    expect(est.calibratedP(tried, 0, reverse: often),
        lessThan(est.presumedP(often, 0) * 0.6));
    expect(est.calibratedP(often, 0, reverse: tried),
        closeTo(est.presumedP(often, 0), 1e-9),
        reason: 'the way in lost nothing');
    final later = (5 * config.failureHalfLifeHours * hour).round();
    expect(est.calibratedP(tried, later, reverse: edge(traffic: 1000, last: later)),
        greaterThan(0.95), reason: 'a suspicion fades');
  });

  test('a traced link keeps its measured level, whatever the other way',
      () {
    final traced = edge(measuredSnr: 6.0);
    expect(est.priorQuality(traced, 0, reverse: edge(traffic: 1000, last: 0)),
        est.snrQuality(6.0));
  });

  test('a sighting adds to what is left of the count, not to what was', () {
    final e = edge(traffic: 1000, last: 0, obs: 1000);
    final days20 = 20 * 24 * hour;
    e.addTraffic(1, days20, config.trafficHalfLifeHours);
    expect(e.trafficWeight, closeTo(1 + 1000 / 1024, 1e-9));
    expect(e.lastObserved, days20);
  });

  test('traffic raises prior confidence', () {
    final thin = edge(traffic: 0);
    final thick = edge(traffic: 60, last: 0);
    expect(est.priorConfidence(thin, 0), config.n0Min);
    expect(est.priorConfidence(thick, 0), greaterThan(config.n0Min * 2));
  });

  test('attempts override the prior in both directions', () {
    final good = edge(measuredSnr: -14, s: 10, n: 10);
    expect(est.calibratedP(good, 0), greaterThan(0.8));

    final bad = edge(measuredSnr: 8, s: 0, n: 10);
    expect(est.calibratedP(bad, 0), lessThan(0.35));
  });

  test('passive-only edge becomes usable with traffic (reduced confidence)',
      () {
    final quiet = edge(traffic: 0, obs: 0);
    expect(est.usable(quiet, 0), isFalse, reason: 'no evidence at all');

    final busy = edge(traffic: 50, last: 0, obs: 50);
    expect(est.calibratedP(busy, 0), closeTo(50 / 60, 1e-9));
    expect(est.usable(busy, 0), isTrue);
  });

  // Owner, 2026-10-31: a failure is a suspicion on every hop of the route,
  // a delivery a fact. Field: two failures shut a link heard 3,942 times
  // out of routing for good.
  test('failures fade; deliveries do not', () {
    final burned = edge(s: 0, n: 2, traffic: 50, last: 0, obs: 50);
    final clean = edge(traffic: 50, last: 0, obs: 50);
    expect(est.calibratedP(burned, 0), lessThan(est.calibratedP(clean, 0)),
        reason: 'two fresh failures lower it');
    expect(est.usable(burned, 0), isTrue,
        reason: 'they do not shut out a link heard often');
    final later = (3 * config.failureHalfLifeHours * hour).round();
    expect(est.decayedFailures(burned, later), closeTo(0.25, 1e-9));

    final proven = edge(s: 3, n: 3, obs: 3);
    final years = 1000 * 24 * hour;
    expect(est.calibratedP(proven, years), est.calibratedP(proven, 0),
        reason: 'deliveries never fade');
    expect(est.calibratedP(proven, 0), closeTo(0.6, 1e-9));
  });

  // Review 2026-10-31: adding to the stored weight re-dated every old
  // failure to now, so a link failing once a week never faded.
  test('a new failure adds to what is left, not to what was', () {
    final e = edge(s: 2, n: 19, traffic: 50, last: 0, obs: 3942);
    final day4 = 4 * 24 * hour;
    expect(est.decayedFailures(e, day4), closeTo(17 / 16, 1e-9));
    e.addFailure(day4, config.failureHalfLifeHours);
    expect(est.decayedFailures(e, day4), closeTo(1 + 17 / 16, 1e-9));
    expect(est.usable(e, day4), isTrue);

    final weekly = edge(traffic: 50, last: 0, obs: 50);
    for (var week = 0; week < 20; week++) {
      weekly.addFailure(week * 7 * 24 * hour, config.failureHalfLifeHours);
    }
    expect(weekly.failWeight, lessThan(1.02),
        reason: 'a week-old failure weighs 2^-7');
  });

  test('a link that only ever failed is no evidence it exists', () {
    final failedOnly = edge(s: 0, n: 1);
    expect(est.hasEvidence(failedOnly), isFalse);
    expect(est.usable(failedOnly, 365 * 24 * hour), isFalse,
        reason: 'faded failures do not make it routable either');
  });

  test('edge cost is -log(p) + tau', () {
    final e = edge(measuredSnr: config.snrFullQualityDb);
    expect(est.edgeCost(e, 0), closeTo(config.tau, 1e-9));
    expect(config.tau, closeTo(-math.log(config.beta), 1e-12));
  });

  test('reportSendResult updates forward edges: success s+n, failure n only',
      () async {
    final graph = PathGraph(NativeDatabase.memory());
    await graph.init();
    graph.setRadioIdentity('ab' * 32, 2);
    final path = Uint8List.fromList([0xA2, 0x77, 0x13, 0x12]);

    graph.reportSendResult(path, true, tripTimeMs: 2100);
    final delivered = graph.snapshot().edges[('A277', '1312')]!.lastObserved;
    graph.reportSendResult(path, false);

    final e = graph.snapshot().edges[('A277', '1312')]!;
    expect(e.s, 1);
    expect(e.n, 2);
    expect(e.failWeight, 1);
    expect(e.lastFailed, isNotNull);
    expect(e.lastObserved, delivered,
        reason: 'a failed send saw nothing: not a sighting');
    await graph.dispose();
  });

  test('reportSendResult drops a 1-byte path instead of pairing its bytes',
      () async {
    // Live find (2026-09-23): a contact's stored route kept the 1-byte
    // width of the packet that built it; sliced at the radio's 2-byte
    // stride, A2,AA,BE,41 minted repeaters 'A2AA' and 'BE41'.
    final graph = PathGraph(NativeDatabase.memory());
    await graph.init();
    graph.setRadioIdentity('ab' * 32, 2);
    graph.reportSendResult(Uint8List.fromList([0xA2, 0xAA, 0xBE, 0x41]), true,
        contactPubkey: 'b0' * 32, stride: 1);
    expect(graph.snapshot().edges, isEmpty);
    expect(graph.snapshot().nodes, isEmpty);
    expect(graph.egressCandidates(), isEmpty);
    expect(graph.counters.droppedNarrow, 1);

    // The same bytes at their true width are two real hops.
    graph.reportSendResult(Uint8List.fromList([0xA2, 0xAA, 0xBE, 0x41]), true,
        contactPubkey: 'b0' * 32, stride: 2);
    expect(graph.snapshot().edges.keys, [('A2AA', 'BE41')]);
    expect(graph.snapshot().nodes.keys, unorderedEquals(['A2AA', 'BE41']));
    await graph.dispose();
  });
}
