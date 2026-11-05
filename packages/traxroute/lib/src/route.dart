import 'dart:math' as math;

typedef LatLon = ({double lat, double lon});

/// What a route may use (Martin, 2026-10-25). Each route uses one type
/// only; there is no drive-then-walk.
enum PathType {
  /// Paved roads only.
  paved,

  /// Dirt and jeep roads allowed, paved roads too.
  dirt,

  /// Trails and paths on foot, with tracks and roads where needed.
  hiking,
}

/// How Dirt weighs distance against time.
enum DirtPreference {
  /// Dirt roads only where they're quicker.
  fastest,

  /// A dirt road when it saves real distance (the default).
  balanced,

  /// The shortest way, however slow its tracks.
  direct,
}

/// How much a hike may climb.
enum ClimbPreference { avoid, some, any }

/// How fast a hiker walks, for the times.
enum HikingPace { slow, normal, fast }

/// The route options a user can change. The defaults are the path types'
/// agreed costing (FINDINGS §9).
class RouteOptions {
  /// Paved and Dirt.
  final bool avoidHighways;
  final bool avoidTolls;
  final bool avoidFerries;

  final DirtPreference dirt;

  /// The hardest trail a hike may take on the SAC scale, 1 (T1) to 6 (T6).
  final int hardestTrail;
  final ClimbPreference climbs;
  final HikingPace pace;

  const RouteOptions({
    this.avoidHighways = false,
    this.avoidTolls = false,
    this.avoidFerries = false,
    this.dirt = DirtPreference.balanced,
    this.hardestTrail = 3,
    this.climbs = ClimbPreference.any,
    this.pace = HikingPace.normal,
  });

  /// From [toJson]'s map; anything missing or unknown is its default.
  factory RouteOptions.fromJson(Map<String, dynamic> json) {
    const d = RouteOptions();
    T pick<T extends Enum>(List<T> values, Object? name, T fallback) =>
        values.where((v) => v.name == name).firstOrNull ?? fallback;
    final trail = json['hardest_trail'];
    return RouteOptions(
      avoidHighways: json['avoid_highways'] == true,
      avoidTolls: json['avoid_tolls'] == true,
      avoidFerries: json['avoid_ferries'] == true,
      dirt: pick(DirtPreference.values, json['dirt'], d.dirt),
      hardestTrail: trail is int && trail >= 1 && trail <= 6
          ? trail
          : d.hardestTrail,
      climbs: pick(ClimbPreference.values, json['climbs'], d.climbs),
      pace: pick(HikingPace.values, json['pace'], d.pace),
    );
  }

  Map<String, Object> toJson() => {
    'avoid_highways': avoidHighways,
    'avoid_tolls': avoidTolls,
    'avoid_ferries': avoidFerries,
    'dirt': dirt.name,
    'hardest_trail': hardestTrail,
    'climbs': climbs.name,
    'pace': pace.name,
  };

  RouteOptions copyWith({
    bool? avoidHighways,
    bool? avoidTolls,
    bool? avoidFerries,
    DirtPreference? dirt,
    int? hardestTrail,
    ClimbPreference? climbs,
    HikingPace? pace,
  }) => RouteOptions(
    avoidHighways: avoidHighways ?? this.avoidHighways,
    avoidTolls: avoidTolls ?? this.avoidTolls,
    avoidFerries: avoidFerries ?? this.avoidFerries,
    dirt: dirt ?? this.dirt,
    hardestTrail: hardestTrail ?? this.hardestTrail,
    climbs: climbs ?? this.climbs,
    pace: pace ?? this.pace,
  );

  /// These options with the ones [type] uses back at their defaults.
  RouteOptions resetFor(PathType type) {
    const d = RouteOptions();
    return switch (type) {
      PathType.paved => copyWith(
        avoidHighways: d.avoidHighways,
        avoidTolls: d.avoidTolls,
        avoidFerries: d.avoidFerries,
      ),
      PathType.dirt => resetFor(PathType.paved).copyWith(dirt: d.dirt),
      PathType.hiking => copyWith(
        hardestTrail: d.hardestTrail,
        climbs: d.climbs,
        pace: d.pace,
      ),
    };
  }

  /// Whether the options [type] uses are all at their defaults.
  bool isDefaultFor(PathType type) {
    const d = RouteOptions();
    final avoids =
        avoidHighways == d.avoidHighways &&
        avoidTolls == d.avoidTolls &&
        avoidFerries == d.avoidFerries;
    return switch (type) {
      PathType.paved => avoids,
      PathType.dirt => avoids && dirt == d.dirt,
      PathType.hiking =>
        hardestTrail == d.hardestTrail && climbs == d.climbs && pace == d.pace,
    };
  }
}

class RouteRequest {
  final List<LatLon> points;
  final PathType pathType;
  final RouteOptions options;

  /// The language of the turn instructions, e.g. `en-US`.
  final String language;

  /// [points] has the start, any stops, and the destination last.
  const RouteRequest(
    this.points,
    this.pathType, {
    this.options = const RouteOptions(),
    this.language = 'en-US',
  });

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

  /// How far the route's end is from the requested destination. More than
  /// 100 m means the destination can't be reached with this path type and
  /// the route stops at the nearest point it can reach (Martin, 2026-10-26:
  /// say so past 100 m, even for a house far up an unmapped driveway).
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

  bool get reachesDestination => kmShortOfDestination <= 0.1;

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
