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
    this.ingressHalfLifeHours = 12,
    this.contactSupersedeFactor = 0.5,
    this.contactMoveWipeKm = 60,
    this.selfProofStaleMinutes = 15,
    this.selfSupersedeFactor = 0.5,
    this.selfWeightCap = 12,
    this.doorstepWeight = 3,
    this.directFreshMinutes = 30,
    this.measuredSnrHalfLifeMinutes = 45,
    this.selfFailGate = 2,
    this.selfSilenceMinutes = 30,
    this.selfSilenceMinEvents = 3,
    this.relayedCopyGraceSeconds = 60,
    this.liveRouteMinutes = 10,
    this.newCodeConfirmMinutes = 10,
    this.mobileFreshMinutes = 15,
    this.mobileNewLinks = 5,
    this.mobileNewShare = 0.5,
    this.mobileMoveKm = 2,
    this.mobileTagDays = 14,
    this.mobileAutoTagsRoute = false,
    this.slashEpochMinutes = 2,
    this.slashFactorProven = 0.3,
    this.slashFactorInferred = 0.2,
    this.allowInferredEndpoints = false,
    this.guessQ = 0.3,
    this.maxGuessedHops = 2,
    this.hintFreshMinutes = 10,
    this.hintLinkMinAgeMinutes = 10,
    this.hintMaxHopKm = 60,
    this.hintsPerContact = 4,
    this.contactFailGate = 2,
  });

  /// A contact's doorstep is a repeater heard carrying their packets, which
  /// proves it hears THEM; a route ending there assumes it also reaches
  /// them. When this many direct sends ending at it have failed since its
  /// last proven delivery, the assumption is wrong for this pair (field
  /// 2026-10-24: F5EE heard Monterey Bay and this radio, the room did not
  /// hear F5EE, four posts failed on it) and it stops ending routes to that
  /// contact. Only a delivery through it resets the count — hearing them via
  /// it again proves the wrong direction. Negative-only, like
  /// [selfFailGate].
  final int contactFailGate;

  /// The splice (owner, 2026-10-23/24): a contact's recent inbound flood
  /// path, read backwards, offers the reverse of each repeater-to-repeater
  /// link on it as a GUESS for one search, never stored. My end still has
  /// to be a proven doorstep; the search joins my proven corridor to the
  /// reversed tail wherever that is cheapest. A guessed hop is priced at
  /// this delivery estimate, below [passiveDefaultQ] on purpose: an
  /// overheard-only link in the sending direction (0.5) must always beat
  /// a guess, and a one-guess splice still beats a weak proven route
  /// (p in 0.40..0.5). Checked by replay before the field.
  final double guessQ;

  /// A route may carry at most this many guessed hops.
  final int maxGuessedHops;

  /// An inbound path older than this is no hint: their doorstep and the
  /// corridor may both have moved on.
  final double hintFreshMinutes;

  /// Ducting guard (owner: "crazy paths" from atmospheric conditions must
  /// not drive routes). A link is reversible as a guess only when its
  /// observed direction was heard in two different packets and first seen
  /// at least this long before the hint. Ducting makes new links; stable
  /// corridors have history. Copies of one flood always carry distinct
  /// paths, so two sightings means two packets.
  final double hintLinkMinAgeMinutes;

  /// Where both repeaters have advert positions, a hop longer than this
  /// cannot be a normal LoRa hop and is not reversed.
  final double hintMaxHopKm;

  /// Distinct inbound paths kept per contact, newest first.
  final int hintsPerContact;

  /// Let a route START at a doorstep I only ever heard (a reciprocity
  /// guess about MY end). Off by default: a repeater that hears me is
  /// proven by a delivered send, a trace or a Discover answer. The
  /// contact's end is not gated by this — a repeater heard carrying
  /// their traffic as first hop reaches them by first-hop symmetry (see
  /// `ingressHalfLifeHours`). The harness turns this on to compare
  /// against the guess.
  final bool allowInferredEndpoints;

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

  /// Mobility: self-egress ages fast (my doorstep changes when I move).
  /// Verification finding (2026-08-05): a 10-minute half-life evaporates
  /// bench evidence between tests — minutes-scale must still survive a
  /// quiet coffee break. Movement, not the clock, is the real
  /// invalidator: see [selfProofStaleMinutes]. A proven row ages from
  /// its last proof — hearing a repeater says nothing about whether it
  /// still hears me.
  final double egressHalfLifeMinutes;

  /// Proven egress (Discover response, delivered send, trace) decays
  /// this many times slower than an inferred last-hop guess.
  final double egressProvenDecayFactor;

  /// A contact's doorstep list answers "which repeater hears them RIGHT
  /// NOW" (2026-09-25). Antenna gain is reciprocal and a handheld is
  /// out-transmitted by the repeater, so a repeater that heard them
  /// almost always reaches them — the heard-from row is a route end.
  /// The list must therefore forget fast: an unrefreshed row fades in
  /// hours, every fresh sighting slashes the others
  /// ([contactSupersedeFactor]), and a sighting through a repeater far
  /// from the current top one wipes the list outright
  /// ([contactMoveWipeKm]) — Watsonville to San Francisco in one
  /// message, not three days.
  final double ingressHalfLifeHours;

  /// Every attributed first-hop sighting multiplies the contact's other
  /// doorstep rows by this. Alternating between two repeaters that both
  /// hear them keeps both alive; a move buries the old one in two or
  /// three messages.
  final double contactSupersedeFactor;

  /// When repeater advert positions are known: a new first hop farther
  /// than this from the contact's current top doorstep wipes their list
  /// (they cannot be inside both footprints).
  final double contactMoveWipeKm;

  /// My own end's move rule, no position needed (field finding
  /// 2026-10-14: home doorstep A277 kept every route after a 20-mile
  /// move because nothing on my end forgot). When an echo of my flood or
  /// a Discover answer proves a doorstep — events every doorstep had the
  /// same chance to answer — every other proven doorstep whose last
  /// proof is older than this is multiplied by [selfSupersedeFactor],
  /// once per [slashEpochMinutes]. One that answers inside the same
  /// epoch gets its weight back, so echo order never ranks doorsteps
  /// that all heard the send; a quiet radio fades nothing.
  final double selfProofStaleMinutes;
  final double selfSupersedeFactor;

  /// Ceiling on my doorstep weights: days at home must not build a
  /// reserve that decay and supersede cannot dent (A277 reached 206).
  final double selfWeightCap;

  /// How much a doorstep's strength counts against corridor length: one
  /// nat of doorstep confidence costs this many nats of corridor. A
  /// route must start at the repeater that hears me strongest and end at
  /// the one that hears them strongest; at 3, a weak doorstep with a
  /// shorter corridor only wins when the strong doorstep's corridor is
  /// about four passive hops longer (field finding 2026-09-25: at 1 the
  /// router picked a repeater that heard this radio weakly once because
  /// its corridor was a hop shorter).
  final double doorstepWeight;

  /// Zero-hop direct wins while direct-reception evidence is this fresh,
  /// and until a later packet of theirs reaches me only through a
  /// repeater (field 2026-10-16: walking away from home, "direct" won for
  /// half an hour while their DMs arrived over 2-5 hops).
  final double directFreshMinutes;

  /// A measured level (trace, Discover answer) belongs to the place it was
  /// measured: its share of a doorstep's confidence halves every this many
  /// minutes since the doorstep's last proof. Proven weights decay
  /// [egressProvenDecayFactor] times slower, which is why the dB needs its
  /// own clock (field 2026-10-17: a home measurement propped a doorstep
  /// 40 km away).
  final double measuredSnrHalfLifeMinutes;

  /// The route-start gate on my own doorsteps (owner, 2026-10-17). A
  /// failed one-hop route marks nothing down, Dijkstra never drops a
  /// source by weight and the ladder always tries the best route, so a
  /// stale home doorstep held every route 40 km away; only exclusion can
  /// turn that into a flood, whose echo and PATH reply then teach the
  /// graph where I am. Negative-only: nothing here mints a proof.
  ///
  /// [selfFailGate]: this many direct sends failed from a doorstep since
  /// its last proof and it stops starting routes (replay of that drive:
  /// at 2, 113 of 186 failed route attempts skipped, 2 of 7 deliveries
  /// blocked). [selfSilenceMinutes]: a doorstep this much quieter than
  /// the newest-heard of my doorsteps stops too — a repeater out-transmits
  /// a handheld, so not hearing it for that long while hearing others is
  /// as good as it not hearing me. Self-gated: the clock is my own
  /// newest hearing, so a quiet mesh excludes nothing, and silence only
  /// counts once [selfSilenceMinEvents] packets have been heard inside
  /// the window.
  final int selfFailGate;
  final double selfSilenceMinutes;
  final int selfSilenceMinEvents;

  /// Copies of one flood land within seconds of each other: a relayed
  /// copy this soon after a direct one is the same packet, not a move.
  final double relayedCopyGraceSeconds;

  /// A route a flood of mine just took to them, named in their PATH
  /// reply (or a path discovery), leads for this long, until a send on
  /// it fails or a newer one replaces it. It is the one corridor proven
  /// end to end this minute; history ranks it only after (field
  /// 2026-10-16: an older favourite that had stopped working replaced it
  /// within milliseconds, and the ACKs that followed were lost).
  final double liveRouteMinutes;

  /// A link heard on the air that touches a repeater code the graph never
  /// had is filed only when the same link is heard again at least this
  /// long after the first time. Field, 2026-10-23: some transmitter puts
  /// random bytes in flood paths and real repeaters relay them, so three
  /// codes in four were one-off junk, heard in a single burst and never
  /// again (copies of one packet land within seconds); a real link comes
  /// back. My own packets and decoded messages vouch for their paths.
  /// 0 files every link at once.
  final double newCodeConfirmMinutes;

  /// A moving repeater (owner, 2026-10-19) collects links to every
  /// repeater it passes, and old ones make it a wormhole: "A hears it"
  /// in Oakland at 10:00 plus "it reaches B" in Sacramento at 14:00 reads
  /// as a two-hop corridor. Everything about one — its links, my doorstep
  /// row for it (from its last proof), a contact's row for it (from the
  /// last sighting) — counts for this long after it was last refreshed.
  /// A hard window, not a faster fade: a faded two-hop shortcut still
  /// beats a real five-hop corridor. One riding with me keeps my doorstep
  /// row; its links still expire.
  final double mobileFreshMinutes;

  /// Watching-only detector ("keeps meeting new repeaters"): this many
  /// links first seen in the last three hours, spread over at least three
  /// of its half-hours, from a repeater known for a day, each to a
  /// repeater also known for a day (one-off codes are mostly garbage).
  final int mobileNewLinks;

  /// ...and more than this share of its links heard in those hours are
  /// new: a busy fixed repeater meets new ones too, but keeps being heard
  /// with the ones it had; a moving one leaves them behind.
  final double mobileNewShare;

  /// An advert from the same key this far from its last real position
  /// marks the repeater as moving.
  final double mobileMoveKm;

  /// A moving sign (advert move, detector) lasts this long.
  final double mobileTagDays;

  /// Off: the traffic detectors only watch (shown, logged, exported),
  /// until a week of field data has set their thresholds (owner,
  /// 2026-10-19). The user's tags and advert moves always act.
  final bool mobileAutoTagsRoute;

  /// Supersede slash: epoch-limited, floored (proven keeps ≥ this).
  final double slashEpochMinutes;
  final double slashFactorProven;
  final double slashFactorInferred;

  double get tau => -math.log(beta);

  PathGraphConfig copyWith(
          {double? beta,
          double? pThreshold,
          int? maxHops,
          double? doorstepWeight,
          double? newCodeConfirmMinutes,
          double? mobileFreshMinutes,
          bool? mobileAutoTagsRoute,
          bool? allowInferredEndpoints}) =>
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
        contactSupersedeFactor: contactSupersedeFactor,
        contactMoveWipeKm: contactMoveWipeKm,
        selfProofStaleMinutes: selfProofStaleMinutes,
        selfSupersedeFactor: selfSupersedeFactor,
        selfWeightCap: selfWeightCap,
        doorstepWeight: doorstepWeight ?? this.doorstepWeight,
        directFreshMinutes: directFreshMinutes,
        measuredSnrHalfLifeMinutes: measuredSnrHalfLifeMinutes,
        selfFailGate: selfFailGate,
        selfSilenceMinutes: selfSilenceMinutes,
        selfSilenceMinEvents: selfSilenceMinEvents,
        relayedCopyGraceSeconds: relayedCopyGraceSeconds,
        liveRouteMinutes: liveRouteMinutes,
        newCodeConfirmMinutes:
            newCodeConfirmMinutes ?? this.newCodeConfirmMinutes,
        mobileFreshMinutes: mobileFreshMinutes ?? this.mobileFreshMinutes,
        mobileNewLinks: mobileNewLinks,
        mobileNewShare: mobileNewShare,
        mobileMoveKm: mobileMoveKm,
        mobileTagDays: mobileTagDays,
        mobileAutoTagsRoute: mobileAutoTagsRoute ?? this.mobileAutoTagsRoute,
        slashEpochMinutes: slashEpochMinutes,
        slashFactorProven: slashFactorProven,
        slashFactorInferred: slashFactorInferred,
        allowInferredEndpoints:
            allowInferredEndpoints ?? this.allowInferredEndpoints,
        guessQ: guessQ,
        maxGuessedHops: maxGuessedHops,
        hintFreshMinutes: hintFreshMinutes,
        hintLinkMinAgeMinutes: hintLinkMinAgeMinutes,
        hintMaxHopKm: hintMaxHopKm,
        hintsPerContact: hintsPerContact,
        contactFailGate: contactFailGate,
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

  /// Prior quality q₀ for THIS direction: a traced SNR when we have one,
  /// else the passive default.
  double priorQuality(EdgeState e) =>
      e.measuredSnr != null ? snrQuality(e.measuredSnr!) : config.passiveDefaultQ;

  /// Prior confidence n₀: how often this direction has been seen scales
  /// trust in q₀.
  double priorConfidence(EdgeState e, int nowMillis) {
    final t = decayedTraffic(e, nowMillis);
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
  bool hasEvidence(EdgeState e) =>
      e.n > 0 || e.obsCount > 0 || e.measuredSnr != null;

  /// Usable in this direction.
  bool usable(EdgeState e, int nowMillis) =>
      hasEvidence(e) && calibratedP(e, nowMillis) >= config.pThreshold;

  /// Edge cost for the search: −log(p) + τ.
  double edgeCost(EdgeState e, int nowMillis) {
    final p = calibratedP(e, nowMillis).clamp(0.01, 1.0);
    return -math.log(p) + config.tau;
  }

  /// Cost of a guessed reverse hop ([PathGraphConfig.guessQ]). The hair
  /// above the formula breaks any tie with an observed link in the
  /// observed link's favour.
  double get guessedCost => -math.log(config.guessQ) + config.tau + 1e-9;
}

/// Great-circle distance between two advert positions.
double haversineKm(double lat1, double lon1, double lat2, double lon2) {
  const r = 6371.0;
  double rad(double deg) => deg * math.pi / 180;
  final dLat = rad(lat2 - lat1);
  final dLon = rad(lon2 - lon1);
  final a = math.pow(math.sin(dLat / 2), 2) +
      math.cos(rad(lat1)) * math.cos(rad(lat2)) * math.pow(math.sin(dLon / 2), 2);
  return 2 * r * math.asin(math.sqrt(a));
}
