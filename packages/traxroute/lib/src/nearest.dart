import 'engine.dart';
import 'route.dart';

/// Routes with [request]'s path type. When the destination can't be reached
/// that way, the route goes to the nearest point it can reach on the way
/// there and [RouteResult.kmShortOfDestination] says how far short it
/// stops (Martin, 2026-10-25: one path type per route, no drive-then-walk).
///
/// The nearest point is found along a route with a looser path type (dirt
/// roads, then trails): the last point of it the chosen type still reaches.
Future<RouteResult> routeOrNearest(
  RoutingEngine engine,
  RouteRequest request,
) async {
  late RouteError failure;
  try {
    return await engine.route(request);
  } on RouteError catch (e) {
    failure = e;
  }
  final via = request.points.sublist(0, request.points.length - 1);
  RouteRequest to(LatLon end, PathType type) =>
      RouteRequest([...via, end], type, language: request.language);

  for (final looser in _looser[request.pathType]!) {
    final RouteResult guide;
    try {
      guide = await engine.route(to(request.destination, looser));
    } on RouteError {
      continue;
    }
    final points = guide.points;
    RouteResult? best;
    var lo = 0, hi = points.length - 1;
    while (hi - lo > 1 && kmBetween(points[lo], points[hi]) > 0.05) {
      final mid = (lo + hi) ~/ 2;
      try {
        best = await engine.route(to(points[mid], request.pathType));
        lo = mid;
      } on RouteError {
        hi = mid;
      }
    }
    if (best != null) return best.withDestination(request.destination);
  }
  throw failure;
}

const _looser = {
  PathType.paved: [PathType.dirt, PathType.hiking],
  PathType.dirt: [PathType.hiking],
  PathType.hiking: <PathType>[],
};
