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

  test('an unmeasured edge sits at the passive default', () {
    expect(est.priorQuality(edge()), config.passiveDefaultQ);
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
    expect(est.usable(bad, 0), isFalse);
  });

  test('passive-only edge becomes usable with traffic (reduced confidence)',
      () {
    final quiet = edge(traffic: 0, obs: 0);
    expect(est.usable(quiet, 0), isFalse, reason: 'no evidence at all');

    final busy = edge(traffic: 50, last: 0, obs: 50);
    expect(est.calibratedP(busy, 0), closeTo(config.passiveDefaultQ, 1e-9));
    expect(est.usable(busy, 0), isTrue,
        reason: 'passive default clears the threshold');
  });

  // Owner, 2026-10-31: a failure is a suspicion on every hop of the route,
  // a delivery a fact. Field: two failures shut a link heard 3,942 times
  // out of routing for good.
  test('failures fade; deliveries do not', () {
    final burned = edge(s: 0, n: 2, traffic: 50, last: 0, obs: 50);
    expect(est.usable(burned, 0), isFalse, reason: 'two fresh failures');
    final later = (3 * config.failureHalfLifeHours * hour).round();
    expect(est.decayedFailures(burned, later), closeTo(0.25, 1e-9));
    expect(est.usable(burned, later), isTrue);

    final proven = edge(s: 3, n: 3, obs: 3);
    final years = 1000 * 24 * hour;
    expect(est.calibratedP(proven, years), est.calibratedP(proven, 0),
        reason: 'deliveries never fade');
    expect(est.calibratedP(proven, 0), closeTo(0.8, 1e-9));
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
