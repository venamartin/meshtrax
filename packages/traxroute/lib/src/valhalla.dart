import 'route.dart';

/// Valhalla's costing and options for each path type: the app defaults
/// MeshTrax and traxmapmaker agreed (FINDINGS §9).
(String, Map<String, Object>) valhallaCosting(PathType type) => switch (type) {
  PathType.paved => ('auto', {'exclude_unpaved': true}),
  PathType.dirtRoad => ('auto', {'use_tracks': 1.0}),
  PathType.hiking => (
    'pedestrian',
    {
      'use_hills': 1.0,
      'use_tracks': 1.0,
      'max_hiking_difficulty': 3,
      'destination_only_penalty': 0,
      'use_ferry': 0.0,
    },
  ),
};

/// The `/route` request for [request].
Map<String, Object> valhallaRouteRequest(RouteRequest request) {
  final (costing, options) = valhallaCosting(request.pathType);
  return {
    'locations': [
      for (final p in request.points) {'lat': p.lat, 'lon': p.lon},
    ],
    'costing': costing,
    'costing_options': {costing: options},
    'elevation_interval': 30,
    'directions_options': {'units': 'kilometers', 'language': request.language},
  };
}

/// The route from Valhalla's `/route` answer. Throws [RouteError] for an
/// error answer.
RouteResult parseValhallaRoute(
  RouteRequest request,
  Map<String, dynamic> json,
) {
  final trip = json['trip'] as Map<String, dynamic>?;
  if (trip == null) {
    throw RouteError(
      json['error'] as String? ?? json['status'] as String? ?? 'No route',
    );
  }
  final points = <LatLon>[];
  final elevations = <double>[];
  final maneuvers = <Maneuver>[];
  var interval = 30.0;
  for (final leg in (trip['legs'] as List).cast<Map<String, dynamic>>()) {
    final offset = points.isEmpty ? 0 : points.length - 1;
    final shape = decodePolyline6(leg['shape'] as String);
    points.addAll(points.isEmpty ? shape : shape.skip(1));
    elevations.addAll(
      ((leg['elevation'] as List?) ?? const [])
          .cast<num>()
          .map((h) => h.toDouble())
          .where((h) => h > -500),
    );
    interval = (leg['elevation_interval'] as num?)?.toDouble() ?? interval;
    for (final m in (leg['maneuvers'] as List).cast<Map<String, dynamic>>()) {
      maneuvers.add(
        Maneuver(
          m['instruction'] as String,
          (m['length'] as num).toDouble(),
          (m['time'] as num).toDouble(),
          offset + (m['begin_shape_index'] as int),
        ),
      );
    }
  }
  final summary = trip['summary'] as Map<String, dynamic>;
  return RouteResult(
    pathType: request.pathType,
    points: points,
    elevations: elevations,
    elevationIntervalM: interval,
    km: (summary['length'] as num).toDouble(),
    seconds: (summary['time'] as num).toDouble(),
    maneuvers: maneuvers,
    kmShortOfDestination: kmBetween(points.last, request.destination),
  );
}

/// Valhalla's shapes: Google's encoded polyline with 6 decimals.
List<LatLon> decodePolyline6(String encoded) {
  final out = <LatLon>[];
  var index = 0, lat = 0, lon = 0;
  int next() {
    var result = 0, shift = 0, b = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    return (result & 1) != 0 ? ~(result >> 1) : result >> 1;
  }

  while (index < encoded.length) {
    lat += next();
    lon += next();
    out.add((lat: lat / 1e6, lon: lon / 1e6));
  }
  return out;
}
