import 'dart:math' as math;

typedef LatLon = ({double lat, double lon});

/// What a route may use (Martin, 2026-10-25). Each route uses one type
/// only; there is no drive-then-walk.
enum PathType {
  /// Paved roads only.
  paved,

  /// Dirt roads (jeep roads too) allowed, paved roads too.
  dirtRoad,

  /// Trails and paths on foot, with tracks and roads where needed.
  hiking,
}

class RouteRequest {
  final List<LatLon> points;
  final PathType pathType;

  /// The language of the turn instructions, e.g. `en-US`.
  final String language;

  /// [points] has the start, any stops, and the destination last.
  const RouteRequest(this.points, this.pathType, {this.language = 'en-US'});

  LatLon get destination => points.last;
}

class Maneuver {
  final String instruction;
  final double km;
  final double seconds;

  /// Index into [RouteResult.points] where the maneuver starts.
  final int startIndex;

  const Maneuver(this.instruction, this.km, this.seconds, this.startIndex);
}

class RouteResult {
  final PathType pathType;
  final List<LatLon> points;

  /// Heights in metres every [elevationIntervalM] along the route.
  final List<double> elevations;
  final double elevationIntervalM;
  final double km;
  final double seconds;
  final List<Maneuver> maneuvers;

  /// How far the route's end is from the requested destination. More than a
  /// few hundred metres means the destination can't be reached with this
  /// path type and the route stops at the nearest point it can reach.
  final double kmShortOfDestination;

  const RouteResult({
    required this.pathType,
    required this.points,
    required this.elevations,
    required this.elevationIntervalM,
    required this.km,
    required this.seconds,
    required this.maneuvers,
    required this.kmShortOfDestination,
  });

  bool get reachesDestination => kmShortOfDestination <= 0.3;

  /// This route, measured against [destination] instead.
  RouteResult withDestination(LatLon destination) => RouteResult(
    pathType: pathType,
    points: points,
    elevations: elevations,
    elevationIntervalM: elevationIntervalM,
    km: km,
    seconds: seconds,
    maneuvers: maneuvers,
    kmShortOfDestination: kmBetween(points.last, destination),
  );

  /// Total climb and descent in metres. Changes under 5 m are ignored, so
  /// noise in the heights doesn't add up over a long route.
  ({double up, double down}) get climb {
    if (elevations.isEmpty) return (up: 0, down: 0);
    var up = 0.0, down = 0.0, last = elevations.first;
    for (final h in elevations) {
      if (h - last >= 5) {
        up += h - last;
        last = h;
      } else if (last - h >= 5) {
        down += last - h;
        last = h;
      }
    }
    return (up: up, down: down);
  }
}

/// No route: nothing usable near a point, or no connection between them.
class RouteError implements Exception {
  final String message;

  const RouteError(this.message);

  @override
  String toString() => 'RouteError: $message';
}

double kmBetween(LatLon a, LatLon b) {
  double rad(double d) => d * math.pi / 180;
  final dLat = rad(b.lat - a.lat);
  final dLon = rad(b.lon - a.lon);
  final h =
      math.pow(math.sin(dLat / 2), 2) +
      math.cos(rad(a.lat)) *
          math.cos(rad(b.lat)) *
          math.pow(math.sin(dLon / 2), 2);
  return 6371 * 2 * math.asin(math.sqrt(h));
}
