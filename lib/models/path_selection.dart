import 'dart:typed_data';

import 'contact.dart';

const int recentAttemptDiversityWindow = 2;

/// Pathfinder routes below this delivery estimate are not tried.
const double minRouteDelivery = 0.2;

/// Who chose a route: the firmware's learned `out_path`, the path graph
/// (Pathfinder), or the user's override.
enum RouteSource { firmware, graph, custom }

class PathSelection {
  final List<int> pathBytes;
  final int hopCount;
  // Hash width of pathBytes; the radio's own width for a flood.
  final int hashSize;
  final bool useFlood;
  // Null for a flood.
  final RouteSource? source;
  // The graph's delivery estimate; only a graph route has one.
  final double? estDelivery;

  const PathSelection({
    required this.pathBytes,
    required this.hopCount,
    required this.hashSize,
    required this.useFlood,
    this.source,
    this.estDelivery,
  });

  const PathSelection.flood(int radioWidth)
      : pathBytes = const [],
        hopCount = -1,
        hashSize = radioWidth,
        useFlood = true,
        source = null,
        estDelivery = null;
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

  if (forceFlood || contact.pathLength < 0 || selection?.useFlood == true) {
    return PathSelection.flood(radioWidth);
  }

  if (selection != null && selection.pathBytes.isNotEmpty) {
    return PathSelection(
      pathBytes: selection.pathBytes,
      hopCount: selection.hopCount,
      hashSize: selection.hashSize,
      useFlood: false,
      source: selection.source,
      estDelivery: selection.estDelivery,
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
/// floods. The radio's stored route is never tried — Pathfinder exists
/// because firmware routing doesn't work (owner rule, 2026-10-14). An empty
/// [graphRoutes] means Pathfinder knows nothing: every attempt floods. When
/// Pathfinder cannot route at all the caller passes null instead.
///
/// Without Pathfinder, under a user override, or on a manual resend
/// ([floodFirst], which an override outranks) the ladder is the firmware
/// one: the known route for one try (two at a budget of 4 or more), then
/// floods.
List<PathSelection> planAttempts(
  Contact contact, {
  required int radioWidth,
  required int budget,
  List<PathSelection>? graphRoutes,
  bool floodFirst = false,
  double minDelivery = minRouteDelivery,
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

  String key(PathSelection s) => '${s.hashSize}:${s.pathBytes.join(',')}';
  final seen = <String>{};
  final routes = <PathSelection>[
    for (final g in graphRoutes)
      if ((g.estDelivery ?? 1) >= minDelivery && seen.add(key(g))) g,
  ];

  final floods = budget <= 2 ? budget - 1 : 2;
  final slots = budget - floods;
  return [
    ...routes.take(slots),
    for (var i = routes.length.clamp(0, slots); i < budget; i++) flood,
  ];
}
