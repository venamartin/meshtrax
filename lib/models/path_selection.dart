import 'dart:typed_data';

import 'contact.dart';

const int recentAttemptDiversityWindow = 2;

/// Pathfinder's second and later routes below this delivery estimate are
/// not tried; its best route always is. Low on purpose: a route Pathfinder
/// knows beats a flood, and links nobody has sent on score 0.5 each, so a
/// four-hop route starts near 7% (owner, 2026-10-14).
const double minRouteDelivery = 0.05;

/// A DM's ladder gives Pathfinder's best route a second try only when its
/// delivery estimate reaches this. A missed ACK on a route that usually
/// works is most often chance; on a route that rarely works it is the
/// route (simulator, 2026-11-24: a contact who had moved was reachable
/// only over long unproven routes, none of 55 tries on them was answered,
/// and trying each twice cost half again as many transmissions as before).
const double repeatMinDelivery = 0.5;

/// Who chose a route: the firmware's learned `out_path`, the path graph
/// (Pathfinder), or the user's override.
enum RouteSource { firmware, graph, custom }

class PathSelection {
  final List<int> pathBytes;
  final int hopCount;
  // Hash width of pathBytes; the radio's own width for a flood.
  final int hashSize;
  final bool useFlood;
  // Null for a flood the ladder chose; see [PathSelection.flood].
  final RouteSource? source;
  // The graph's delivery estimate; only a graph route has one.
  final double? estDelivery;
  // Per between-hop link of a graph route: a splice guess (the reverse of
  // a link heard on the contact's inbound path) rather than an observed
  // link. Empty when nothing was guessed.
  final List<bool> guessedLinks;

  const PathSelection({
    required this.pathBytes,
    required this.hopCount,
    required this.hashSize,
    required this.useFlood,
    this.source,
    this.estDelivery,
    this.guessedLinks = const [],
  });

  /// A flood. With [RouteSource.firmware] as [source] it is the radio's
  /// route where the contact list shows none: a flood, unless the radio has
  /// learned a route the list doesn't show yet. Without, the ladder chose a
  /// flood, and the radio's stored route is cleared for it.
  const PathSelection.flood(int radioWidth, {this.source})
      : pathBytes = const [],
        hopCount = -1,
        hashSize = radioWidth,
        useFlood = true,
        estDelivery = null,
        guessedLinks = const [];

  /// How many of the route's links are splice guesses.
  int get guessedHops => guessedLinks.where((g) => g).length;

  /// Whether [contact], as the radio holds it, stores this route: what the
  /// radio's own sends and ACKs to that contact go out on.
  bool heldBy(Contact contact) {
    if (useFlood) return contact.pathLength < 0;
    if (contact.pathLength != hopCount) return false;
    if (hopCount == 0) return true;
    return contact.pathHashSize == hashSize &&
        _sameBytes(contact.path, pathBytes);
  }

  static bool _sameBytes(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// The route a send to [contact] goes out on. Every route carries the width
/// it was made at: an override the radio width when the user set it, the
/// firmware's own route the width it was learned at. [radioWidth] is only
/// for floods and for overrides saved before their width was recorded.
PathSelection resolvePathSelection(
  Contact contact, {
  required int radioWidth,
  PathSelection? selection,
  bool forceFlood = false,
}) {
  if (contact.pathOverride != null) {
    if (contact.pathOverride! < 0) {
      return PathSelection.flood(radioWidth);
    }
    return PathSelection(
      pathBytes: contact.pathOverrideBytes ?? Uint8List(0),
      hopCount: contact.pathOverride!,
      hashSize: contact.overrideHashSize(radioWidth),
      useFlood: false,
      source: RouteSource.custom,
    );
  }

  if (forceFlood || selection?.useFlood == true) {
    return PathSelection.flood(radioWidth);
  }
  if (contact.pathLength < 0) {
    return PathSelection.flood(radioWidth, source: RouteSource.firmware);
  }

  if (selection != null && selection.pathBytes.isNotEmpty) {
    return PathSelection(
      pathBytes: selection.pathBytes,
      hopCount: selection.hopCount,
      hashSize: selection.hashSize,
      useFlood: false,
      source: selection.source,
      estDelivery: selection.estDelivery,
      guessedLinks: selection.guessedLinks,
    );
  }

  return PathSelection(
    pathBytes: contact.path,
    hopCount: contact.pathLength,
    hashSize: contact.pathHashSize,
    useFlood: false,
    source: RouteSource.firmware,
  );
}

/// The attempt ladder for one message, decided once when it is sent.
///
/// With Pathfinder ([graphRoutes] non-null) the ladder is Pathfinder's
/// routes, best first and never repeated, then floods: two close the
/// ladder (one at a budget of 2, none at 1) and an unfilled route slot
/// floods. The best route is tried whatever its score: a link only
/// overheard, never sent on, scores low until a send proves it, so a cutoff
/// on the best route would keep Pathfinder from ever learning (field
/// 2026-10-14: a 3-hop route at 14% was never tried). Later routes must
/// reach [minDelivery]. The radio's stored route is never tried — Pathfinder exists
/// because firmware routing doesn't work (owner rule, 2026-10-14). An empty
/// [graphRoutes] means Pathfinder knows nothing: every attempt floods. When
/// Pathfinder cannot route at all the caller passes null instead.
///
/// Without Pathfinder, under a user override, or on a manual resend
/// ([floodFirst], which an override outranks) the ladder is the firmware
/// one: the known route for one try (two at a budget of 4 or more), then
/// floods.
///
/// Re-planning the rest of a ladder mid-message: [tried] are the rungs
/// already sent (their routes are never tried again) and [floods] how many
/// of the remaining [budget] close it (the floods the original ladder
/// still owes), so a route Pathfinder now ranks first after a failure is
/// tried next instead of being skipped.
///
/// [bestTwice], a DM's ladder (owner, 2026-11-24): a missed ACK is most
/// often two radios sending at once, not a broken route, so Pathfinder's
/// first choice gets two tries before another route or a flood, when it
/// is a route likely to work ([repeatMinDelivery]; a weaker one keeps the
/// ladder above). Back to back when the next route ends at the same
/// repeater (the contact has not moved); around the next route when that
/// one ends elsewhere (the repeater that heard their latest packet goes
/// second). A likely route to a repeater not tried yet comes before
/// another way to one that was, and, once a route elsewhere was tried,
/// before the best route's second try. With five tries: best, best, next,
/// flood, flood; with three: best, best, flood.
List<PathSelection> planAttempts(
  Contact contact, {
  required int radioWidth,
  required int budget,
  List<PathSelection>? graphRoutes,
  bool floodFirst = false,
  double minDelivery = minRouteDelivery,
  Iterable<PathSelection> tried = const [],
  int? floods,
  bool bestTwice = false,
}) {
  final flood = PathSelection.flood(radioWidth);
  final resend = floodFirst && contact.pathOverride == null;
  if (graphRoutes == null || contact.pathOverride != null || resend) {
    final routeAttempts = budget >= 4 ? 2 : 1;
    return [
      for (var i = 0; i < budget; i++)
        i < routeAttempts && !resend
            ? resolvePathSelection(contact, radioWidth: radioWidth)
            : flood,
    ];
  }

  // A zero-hop route is "no repeater" at any width: one slot.
  String key(PathSelection s) => s.hopCount == 0
      ? 'direct'
      : '${s.hashSize}:${s.pathBytes.join(',')}';
  final seen = <String>{for (final t in tried) if (!t.useFlood) key(t)};
  var routes = <PathSelection>[];
  final best = graphRoutes.firstOrNull;
  final twice = bestTwice &&
      best != null &&
      (best.estDelivery ?? 1) >= repeatMinDelivery;
  if (!twice) {
    for (final g in graphRoutes) {
      final k = key(g);
      if (seen.contains(k)) continue;
      // The best remaining route is tried whatever its score.
      if (routes.isNotEmpty && (g.estDelivery ?? 1) < minDelivery) continue;
      seen.add(k);
      routes.add(g);
    }
  } else {
    String lastHop(PathSelection s) {
      final from = s.pathBytes.length - s.hashSize;
      return s.hopCount == 0
          ? 'direct'
          : s.pathBytes.sublist(from < 0 ? 0 : from).join(',');
    }
    final timesTried = <String, int>{};
    for (final t in tried) {
      if (!t.useFlood) timesTried[key(t)] = (timesTried[key(t)] ?? 0) + 1;
    }
    final distinct = <PathSelection>[];
    final keys = <String>{};
    for (final g in graphRoutes) {
      if (keys.add(key(g))) distinct.add(g);
    }
    final bestLeft = (2 - (timesTried[key(best)] ?? 0)).clamp(0, 2);
    final others = <PathSelection>[];
    for (final g in distinct.skip(1)) {
      if (timesTried.containsKey(key(g))) continue;
      // With nothing else left, the next route is tried whatever its score.
      final needsScore = bestLeft > 0 || others.isNotEmpty;
      if (needsScore && (g.estDelivery ?? 1) < minDelivery) continue;
      others.add(g);
    }
    // The repeaters routes end at, tried or planned so far.
    final ends = {
      lastHop(best),
      for (final t in tried)
        if (!t.useFlood) lastHop(t),
    };
    // Where the contact is has come into question once a route to another
    // repeater was tried, or ranks second (their latest packet was heard
    // there): that one goes between the best route's two tries, once.
    final triedElsewhere = ends.length > 1;
    final second = !triedElsewhere &&
            others.isNotEmpty &&
            !ends.contains(lastHop(others.first))
        ? others.removeAt(0)
        : null;
    if (second != null) ends.add(lastHop(second));
    // A likely route to a repeater not tried yet is worth more than a
    // repeat or another way to a repeater already tried: what is known to
    // reach them is used before a flood. Anything less waits behind the
    // best route's second try (simulator's scripted set, 2026-11-24: an
    // 82% route lost its second try to a 16% second route to the other
    // repeater, and the message with it; and a 61% route to a third
    // repeater lost its turn to the best route's repeat, so a flood
    // delivered what that route would have).
    final fresh = [
      for (final g in others)
        if ((g.estDelivery ?? 1) >= repeatMinDelivery && ends.add(lastHop(g)))
          g,
    ];
    final elsewhere = second != null || triedElsewhere;
    routes = [
      if (bestLeft == 2) best,
      ?second,
      // Back to back while nothing says they are elsewhere.
      if (bestLeft >= 1 && !elsewhere) best,
      ...fresh,
      if (bestLeft >= 1 && elsewhere) best,
      ...others.where((g) => !fresh.contains(g)),
    ];
  }

  // Floods cost the whole mesh a transmission each: with three tries and
  // the best route tried twice, one closes the ladder.
  final floodCount = (floods ??
          (budget <= 2
              ? budget - 1
              : twice && budget == 3
                  ? 1
                  : 2))
      .clamp(0, budget);
  final slots = budget - floodCount;
  return [
    ...routes.take(slots),
    for (var i = routes.length.clamp(0, slots); i < budget; i++) flood,
  ];
}
