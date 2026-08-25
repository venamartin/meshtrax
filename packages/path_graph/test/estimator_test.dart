import 'dart:math' as math;
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:path_graph/path_graph.dart';
import 'package:test/test.dart';

void main() {
  const config = PathGraphConfig();
  const est = Estimator(config);
  const hour = 60 * 60 * 1000;

  EdgeState edge({int s = 0, int n = 0, double traffic = 0, int? last,
      double? importedSnr, int impObs = 0, int impDelivered = 0,
      int impAttempts = 0, int? impLast, double? measuredSnr, int obs = 0}) {
    return EdgeState(source: 'observed')
      ..s = s
      ..n = n
      ..trafficWeight = traffic
      ..lastObserved = last
      ..obsCount = obs
      ..importedSnr = importedSnr
      ..importedObservations = impObs
      ..importedDelivered = impDelivered
      ..importedAttempts = impAttempts
      ..importedLastObserved = impLast
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

  test('imported-only edge routes at its imported SNR', () {
    final e = edge(importedSnr: 6.0);
    expect(est.calibratedP(e, 0), closeTo(est.snrQuality(6.0), 1e-9),
        reason: 'no local attempts → the prior stands alone');
    expect(est.usable(e, 0), isTrue);
  });

  test('measured trace SNR outranks the imported one', () {
    final e = edge(
        importedSnr: config.snrZeroQualityDb,
        measuredSnr: config.snrFullQualityDb);
    expect(est.priorQuality(e), 1.0);
  });

  test('imported SNR and delivery record average into one prior', () {
    final snrOnly = edge(importedSnr: config.snrFullQualityDb);
    final both = edge(
        importedSnr: config.snrFullQualityDb,
        impDelivered: 0,
        impAttempts: 8);
    expect(est.priorQuality(snrOnly), 1.0);
    expect(est.priorQuality(both), lessThan(0.7),
        reason: 'a strong signal that never delivers is not a good link');
  });

  test('imported observations raise prior confidence', () {
    final thin = edge(importedSnr: 6.0, impObs: 0);
    final thick = edge(importedSnr: 6.0, impObs: 60, impLast: 0);
    expect(est.priorConfidence(thin, 0), config.n0Min);
    expect(est.priorConfidence(thick, 0), greaterThan(config.n0Min * 2));
  });

  test('attempts override the prior in both directions', () {
    final good = edge(importedSnr: -14, s: 10, n: 10);
    expect(est.calibratedP(good, 0), greaterThan(0.8));

    final bad = edge(importedSnr: 8, s: 0, n: 10);
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

  test('edge cost is -log(p) + tau', () {
    final e = edge(importedSnr: config.snrFullQualityDb);
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
    graph.reportSendResult(path, false);

    final e = graph.snapshot().edges[('A277', '1312')]!;
    expect(e.s, 1);
    expect(e.n, 2);
    await graph.dispose();
  });
}
