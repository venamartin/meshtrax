import 'wrm.dart';

/// A place, in degrees.
typedef LatLon = ({double lat, double lon});

/// The boat and the trip's limits. The defaults are the starting values:
/// 6 kn, 6 ft draft with 2 ft under the keel, 0.25 nm off land (1 nm was
/// too far off for most water, owner 2026-11-25).
class WaterRouteOptions {
  const WaterRouteOptions({
    this.speedKn = 6,
    this.draftM = 6 * 0.3048,
    this.underKeelM = 2 * 0.3048,
    this.preferDepthM,
    this.offLandNm = 0.25,
    this.mastHeightM,
    this.avoidTrafficLanes = true,
    this.avoidSecurityZones = true,
    this.avoidOpeningBridges = false,
  });

  final double speedKn;
  final double draftM;

  /// Room kept under the keel, added to the draft.
  final double underKeelM;

  /// Water shallower than this costs more where there's a choice.
  final double? preferDepthM;

  /// The distance off land kept where the water allows: one of [ringsNm],
  /// or null for none. Only the harbour approach at each end comes closer.
  final double? offLandNm;

  /// With a mast height, a bridge, cable, pipe or conveyor lower than it
  /// blocks, and so does one with no charted clearance.
  final double? mastHeightM;
  final bool avoidTrafficLanes;
  final bool avoidSecurityZones;

  /// A bridge that opens counts at its closed clearance; otherwise at its
  /// open clearance, listed "needs opening".
  final bool avoidOpeningBridges;

  /// As [toJson] writes it; what it lacks takes the starting value.
  factory WaterRouteOptions.fromJson(Map<String, Object?> json) {
    double? number(String key) => (json[key] as num?)?.toDouble();
    const start = WaterRouteOptions();
    return WaterRouteOptions(
      speedKn: number('speed_kn') ?? start.speedKn,
      draftM: number('draft_m') ?? start.draftM,
      underKeelM: number('under_keel_m') ?? start.underKeelM,
      preferDepthM: number('prefer_depth_m'),
      offLandNm: json.containsKey('off_land_nm')
          ? number('off_land_nm')
          : start.offLandNm,
      mastHeightM: number('mast_height_m'),
      avoidTrafficLanes:
          json['avoid_traffic_lanes'] as bool? ?? start.avoidTrafficLanes,
      avoidSecurityZones:
          json['avoid_security_zones'] as bool? ?? start.avoidSecurityZones,
      avoidOpeningBridges:
          json['avoid_opening_bridges'] as bool? ?? start.avoidOpeningBridges,
    );
  }

  Map<String, Object?> toJson() => {
    'speed_kn': speedKn,
    'draft_m': draftM,
    'under_keel_m': underKeelM,
    'prefer_depth_m': ?preferDepthM,
    // Null is a choice here: no distance off land.
    'off_land_nm': offLandNm,
    'mast_height_m': ?mastHeightM,
    'avoid_traffic_lanes': avoidTrafficLanes,
    'avoid_security_zones': avoidSecurityZones,
    'avoid_opening_bridges': avoidOpeningBridges,
  };

  @override
  bool operator ==(Object other) =>
      other is WaterRouteOptions &&
      other.speedKn == speedKn &&
      other.draftM == draftM &&
      other.underKeelM == underKeelM &&
      other.preferDepthM == preferDepthM &&
      other.offLandNm == offLandNm &&
      other.mastHeightM == mastHeightM &&
      other.avoidTrafficLanes == avoidTrafficLanes &&
      other.avoidSecurityZones == avoidSecurityZones &&
      other.avoidOpeningBridges == avoidOpeningBridges;

  @override
  int get hashCode => Object.hash(
    speedKn,
    draftM,
    underKeelM,
    preferDepthM,
    offLandNm,
    mastHeightM,
    avoidTrafficLanes,
    avoidSecurityZones,
    avoidOpeningBridges,
  );
}

enum WaterRoutingProblem {
  /// No tiles at an end of the trip, or within two tiles of it.
  noTiles,

  /// Tiles of two builds: the installed areas need updating together.
  mixedBuilds,

  /// No water around the trip the boat can use.
  noWater,
}

class WaterRoutingException implements Exception {
  const WaterRoutingException(this.problem);

  final WaterRoutingProblem problem;

  @override
  String toString() => 'WaterRoutingException: ${problem.name}';
}

/// A trip on the water: straight legs between waypoints, and what it runs
/// through.
class WaterTrip {
  WaterTrip({
    required this.legs,
    required this.from,
    required this.to,
    required this.endsShort,
    required this.areas,
    required this.securityZoneM,
    required this.trafficLaneM,
    required this.leastDepthM,
    required this.leastDepthToM,
    required this.shallowerThanPreferredM,
    required this.surveyM,
    required this.offLand,
    required this.lowestClearance,
    required this.outsideM,
    required this.magneticModelExpired,
    required this.stats,
  });

  final List<WaterLeg> legs;
  final WaterEnd from;
  final WaterEnd to;

  /// Set when the trip can't reach [to].
  final EndsShort? endsShort;

  /// Every area and overhead object the trip runs through or under, most
  /// metres first.
  final List<AreaPassed> areas;
  final double securityZoneM;

  /// Metres in traffic lanes and separation zones.
  final double trafficLaneM;

  /// The least charted depth on the way, or null where none is charted.
  final double? leastDepthM;

  /// The deep end of the depth band charted at [leastDepthM] (6–12 ft is
  /// 1.8–3.6 m), or null where none is charted.
  final double? leastDepthToM;

  /// With a preferred depth: the metres shallower than it.
  final double? shallowerThanPreferredM;

  /// Metres by the survey's zone of confidence (CATZOC: 1 A1, 2 A2, 3 B,
  /// 4 C, 5 D, 6 unassessed, 0 none given).
  final Map<int, double> surveyM;

  /// With a distance off land: where the trip keeps it.
  final OffLand? offLand;

  /// The lowest charted clearance the trip passes under, or null when it
  /// passes under nothing.
  final LowestClearance? lowestClearance;

  /// Metres outside charted water: 0 for every trip the router makes.
  final double outsideM;

  /// The magnetic model (WMM2025) is valid to 2030: after that bearings
  /// still show, from the old model.
  final bool magneticModelExpired;
  final WaterSearchStats stats;

  List<LatLon> get waypoints => [
    if (legs.isNotEmpty) legs.first.from,
    for (final l in legs) l.to,
  ];

  double get distanceM => legs.fold(0, (d, l) => d + l.distanceM);

  Duration get time => legs.fold(Duration.zero, (d, l) => d + l.time);
}

/// A straight leg, as it's drawn on a Mercator chart: one course all the
/// way (a rhumb line).
class WaterLeg {
  const WaterLeg({
    required this.from,
    required this.to,
    required this.distanceM,
    required this.courseTrue,
    required this.courseMagnetic,
    required this.time,
  });

  final LatLon from;
  final LatLon to;
  final double distanceM;

  /// Degrees, 0 to 360.
  final double courseTrue;

  /// Degrees magnetic, at the leg's start.
  final double courseMagnetic;
  final Duration time;
}

enum EndMoved {
  /// On land or outside charted water.
  notInWater,

  /// Shallower than the draft and the room under the keel.
  depth,

  /// Within 15 m of a hazard too shallow for the boat.
  hazard,

  /// In an area where entry is prohibited.
  noEntry,

  /// Under something lower than the mast.
  mastHeight,
}

/// A trip's end: where it was asked for, and where the trip starts or ends
/// when that isn't in water the boat can use.
class WaterEnd {
  const WaterEnd({
    required this.asked,
    required this.at,
    required this.movedM,
    required this.moved,
    required this.depthM,
  });

  final LatLon asked;
  final LatLon at;
  final double movedM;

  /// Why the end moved, or null when it didn't.
  final EndMoved? moved;

  /// The charted depth where it was asked, or null where none is charted.
  final double? depthM;
}

enum EndsShortReason {
  /// Every way on passes under something lower than the mast.
  mastHeight,

  /// Every way on is too shallow.
  depth,

  /// No water joins the two ends.
  noConnection,

  /// The way on takes more tiles than one route can: plan it in parts.
  tooLong,
}

class EndsShort {
  const EndsShort({
    required this.reason,
    required this.remainingM,
    required this.lowObjects,
    required this.deepestWayM,
    this.deepestWayToM,
    this.deepestDraftM,
  });

  final EndsShortReason reason;

  /// From where the trip ends to the place asked for, straight.
  final double remainingM;

  /// For [EndsShortReason.mastHeight]: what is too low on the way on.
  final List<WaterArea> lowObjects;

  /// For [EndsShortReason.depth]: how deep the deepest way on is at its
  /// shallowest (the charted depth, or a hazard's within 15 m).
  final double? deepestWayM;

  /// For [EndsShortReason.depth]: the deep end of the depth band charted
  /// there (6–12 ft is 1.8–3.6 m), or null where a hazard sets the depth or
  /// no band is charted.
  final double? deepestWayToM;

  /// For [EndsShortReason.depth]: the deepest draft that gets through with
  /// the trip's room under the keel; 0 where none does.
  final double? deepestDraftM;
}

enum BridgeNote {
  /// The boat gets under only with the bridge open.
  needsOpening,

  /// A bridge that opens, which the boat clears closed.
  clearsClosed,
}

class AreaPassed {
  const AreaPassed({
    required this.area,
    required this.metres,
    required this.fromM,
    required this.note,
  });

  final WaterArea area;
  final double metres;

  /// Where along the trip it starts.
  final double fromM;

  /// With a mast height: a bridge that opens.
  final BridgeNote? note;
}

class OffLand {
  const OffLand({
    required this.distanceNm,
    required this.reachesDistance,
    required this.insideInApproachesM,
    required this.insideElsewhereM,
    required this.couldntKeep,
  });

  final double distanceNm;

  /// Whether the trip is ever that far off.
  final bool reachesDistance;

  /// Metres closer to land within the harbour approach at either end.
  final double insideInApproachesM;

  /// Metres closer to land anywhere else: water too narrow to keep it.
  final double insideElsewhereM;

  /// Where those are, along the trip.
  final List<Stretch> couldntKeep;
}

class Stretch {
  const Stretch({
    required this.fromM,
    required this.metres,
    required this.start,
    required this.end,
  });

  final double fromM;
  final double metres;
  final LatLon start;
  final LatLon end;
}

class LowestClearance {
  const LowestClearance({
    required this.clearanceM,
    required this.object,
    required this.fromM,
    required this.uncharted,
  });

  /// Null when nothing passed under has a charted clearance.
  final double? clearanceM;
  final WaterArea? object;
  final double? fromM;

  /// How many objects (gates aside) the trip passes under with no charted
  /// clearance.
  final int uncharted;
}

class WaterSearchStats {
  const WaterSearchStats({
    required this.tiles,
    required this.triangles,
    required this.searches,
    required this.expanded,
    required this.loadMs,
    required this.searchMs,
    required this.straightenMs,
    required this.totalMs,
  });

  final int tiles;
  final int triangles;

  /// How many times the search ran: more than once where the water ran on
  /// past the tiles it had.
  final int searches;

  /// Triangles the last main search took off its queue.
  final int expanded;
  final int loadMs;
  final int searchMs;
  final int straightenMs;
  final int totalMs;
}
