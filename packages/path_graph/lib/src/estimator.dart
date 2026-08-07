import 'dart:math' as math;

import 'graph_store.dart';

/// Tunables in one place. Defaults follow the design doc; the harness
/// exposes the ones users touch (β) and verification tunes the rest.
class PathGraphConfig {
  const PathGraphConfig({
    this.beta = 0.95,
    this.trafficHalfLifeHours = 48,
    this.n0Min = 2,
    this.n0Max = 8,
    this.trafficConfidenceHalf = 6,
    this.passiveDefaultQ = 0.5,
    this.snrFullQualityDb = 8,
    this.snrZeroQualityDb = -18,
    this.pThreshold = 0.40,
    this.maxHops = 32,
    this.egressHalfLifeMinutes = 45,
    this.egressProvenDecayFactor = 4,
    this.ingressHalfLifeHours = 72,
    this.directFreshMinutes = 30,
    this.slashEpochMinutes = 2,
    this.slashFactorProven = 0.3,
    this.slashFactorInferred = 0.2,
  });

  /// Hop tax: an extra hop hurts like ×β reliability.
  final double beta;

  /// Passive traffic EWMA half-life (infrastructure decays slowly —
  /// the decay *floor* is confidence fading, not topology).
  final double trafficHalfLifeHours;

  /// Prior confidence (pseudo-attempts) bounds; grows with traffic.
  final double n0Min;
  final double n0Max;

  /// Decayed traffic at which prior confidence is halfway to n0Max.
  final double trafficConfidenceHalf;

  /// Prior quality for passive-only edges (no import, no SNR).
  final double passiveDefaultQ;

  /// Monotone SNR→quality map anchors (dB).
  final double snrFullQualityDb;
  final double snrZeroQualityDb;

  /// Minimum calibrated p for an edge direction to count as usable.
  final double pThreshold;

  /// Path budget: 64 wire bytes ÷ 2-byte hops.
  final int maxHops;

  /// Mobility: self-egress ages fast (my doorstep changes when I move),
  /// contact ingress slowly. Verification finding (2026-08-05): a
  /// 10-minute half-life evaporates bench evidence between tests —
  /// minutes-scale must still survive a quiet coffee break. Movement,
  /// not the clock, is the real invalidator (position gating handles
  /// that when a position source exists).
  final double egressHalfLifeMinutes;

  /// Proven egress (Discover response, delivered send, trace) decays
  /// this many times slower than an inferred last-hop guess.
  final double egressProvenDecayFactor;

  final double ingressHalfLifeHours;

  /// Zero-hop direct wins while direct-reception evidence is this fresh.
  final double directFreshMinutes;

  /// Supersede slash: epoch-limited, floored (proven keeps ≥ this).
  final double slashEpochMinutes;
  final double slashFactorProven;
  final double slashFactorInferred;

  double get tau => -math.log(beta);

  PathGraphConfig copyWith({double? beta, double? pThreshold, int? maxHops}) =>
      PathGraphConfig(
        beta: beta ?? this.beta,
        trafficHalfLifeHours: trafficHalfLifeHours,
        n0Min: n0Min,
        n0Max: n0Max,
        trafficConfidenceHalf: trafficConfidenceHalf,
        passiveDefaultQ: passiveDefaultQ,
        snrFullQualityDb: snrFullQualityDb,
        snrZeroQualityDb: snrZeroQualityDb,
        pThreshold: pThreshold ?? this.pThreshold,
        maxHops: maxHops ?? this.maxHops,
        egressHalfLifeMinutes: egressHalfLifeMinutes,
        egressProvenDecayFactor: egressProvenDecayFactor,
        ingressHalfLifeHours: ingressHalfLifeHours,
        directFreshMinutes: directFreshMinutes,
        slashEpochMinutes: slashEpochMinutes,
        slashFactorProven: slashFactorProven,
        slashFactorInferred: slashFactorInferred,
      );
}

/// Pure estimator functions over [EdgeState]. Lazy decay: nothing here
/// mutates state.
class Estimator {
  const Estimator(this.config);

  final PathGraphConfig config;

  double decayedTraffic(EdgeState e, int nowMillis) {
    final last = e.lastObserved;
    if (last == null || e.trafficWeight == 0) return 0;
    final hours = (nowMillis - last) / (1000 * 60 * 60);
    if (hours <= 0) return e.trafficWeight;
    return e.trafficWeight *
        math.pow(0.5, hours / config.trafficHalfLifeHours);
  }

  /// Monotone dB → [0,1].
  double snrQuality(double db) {
    final span = config.snrFullQualityDb - config.snrZeroQualityDb;
    return ((db - config.snrZeroQualityDb) / span).clamp(0.0, 1.0);
  }

  /// Someone else's traffic count for this direction, decayed from
  /// *their* last observation. Feeds confidence only — never p.
  double importedTraffic(EdgeState e, int nowMillis) {
    final last = e.importedLastObserved;
    if (e.importedObservations == 0) return 0;
    final obs = e.importedObservations.toDouble();
    if (last == null) return obs;
    final hours = (nowMillis - last) / (1000 * 60 * 60);
    if (hours <= 0) return obs;
    return obs * math.pow(0.5, hours / config.trafficHalfLifeHours);
  }

  /// Prior quality q₀ for THIS direction: my own measured SNR (trace)
  /// outranks an imported measurement, which outranks the passive
  /// default. An import carrying both a measured SNR and a delivery
  /// record averages the two — they are independent readings of the
  /// same link.
  double priorQuality(EdgeState e) {
    if (e.measuredSnr != null) return snrQuality(e.measuredSnr!);
    var sum = 0.0, parts = 0;
    if (e.importedSnr != null) {
      sum += snrQuality(e.importedSnr!);
      parts++;
    }
    if (e.importedAttempts > 0) {
      // Beta-smoothed toward the passive default so a lone 1/1 does not
      // read as certainty.
      sum += (e.importedDelivered + config.passiveDefaultQ * config.n0Min) /
          (e.importedAttempts + config.n0Min);
      parts++;
    }
    return parts == 0 ? config.passiveDefaultQ : sum / parts;
  }

  /// Prior confidence n₀: how often this direction has been seen — by
  /// me or by the collector I imported from — scales trust in q₀.
  double priorConfidence(EdgeState e, int nowMillis) {
    final t = decayedTraffic(e, nowMillis) + importedTraffic(e, nowMillis);
    final scale = t / (t + config.trafficConfidenceHalf);
    return config.n0Min + (config.n0Max - config.n0Min) * scale;
  }

  /// Calibrated delivery probability: local attempts override the prior.
  double calibratedP(EdgeState e, int nowMillis) {
    final n0 = priorConfidence(e, nowMillis);
    return (e.s + priorQuality(e) * n0) / (e.n + n0);
  }

  /// Any evidence at all? (Nodes minted by a single sighting shouldn't
  /// route on the bare passive default.)
  bool hasEvidence(EdgeState e) => e.n > 0 || e.obsCount > 0 || e.hasImport;

  /// Usable in this direction.
  bool usable(EdgeState e, int nowMillis) =>
      hasEvidence(e) && calibratedP(e, nowMillis) >= config.pThreshold;

  /// Edge cost for the search: −log(p) + τ.
  double edgeCost(EdgeState e, int nowMillis) {
    final p = calibratedP(e, nowMillis).clamp(0.01, 1.0);
    return -math.log(p) + config.tau;
  }
}
