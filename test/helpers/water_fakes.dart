import 'dart:io';

import 'package:meshtrax/services/map_packs_service.dart';
import 'package:meshtrax/services/water_routing_service.dart';
import 'package:traxmap/traxmap.dart' show ChartArea, LatLng;
import 'package:traxwater/traxwater.dart';

/// A trip on the water from [from] to [to] in one straight leg, at 6 kn,
/// with what it [passes].
WaterTrip waterTrip(
  LatLon from,
  LatLon to, {
  double distanceM = 9260,
  double startMovedM = 0,
  EndMoved? startMoved,
  EndsShort? endsShort,
  List<AreaPassed> passes = const [],
  double? leastDepthM = 3.6,
  double? leastDepthToM = 5.4,
  LowestClearance? lowestClearance,
  OffLand? offLand,
}) => WaterTrip(
  legs: [
    WaterLeg(
      from: from,
      to: to,
      distanceM: distanceM,
      courseTrue: 80,
      courseMagnetic: 67,
      time: Duration(seconds: (distanceM / 1852 / 6 * 3600).round()),
    ),
  ],
  from: WaterEnd(
    asked: from,
    at: from,
    movedM: startMovedM,
    moved: startMoved,
    depthM: null,
  ),
  to: WaterEnd(asked: to, at: to, movedM: 0, moved: null, depthM: 4),
  endsShort: endsShort,
  areas: passes,
  securityZoneM: 0,
  trafficLaneM: 0,
  leastDepthM: leastDepthM,
  leastDepthToM: leastDepthToM,
  shallowerThanPreferredM: null,
  surveyM: const {},
  offLand: offLand,
  lowestClearance: lowestClearance,
  outsideM: 0,
  magneticModelExpired: false,
  stats: const WaterSearchStats(
    tiles: 1,
    triangles: 1,
    searches: 1,
    expanded: 1,
    loadMs: 0,
    searchMs: 0,
    straightenMs: 0,
    totalMs: 0,
  ),
);

/// Water routing on hand everywhere, and a straight trip for every route
/// on the water, or [problem] where there's none.
class FakeWaterRouting extends WaterRoutingService {
  FakeWaterRouting(
    MapPacksService maps, {
    this.problem,
    this.endsShort,
    this.area,
  }) : super(
         maps: maps,
         store: WaterStore(Directory('${maps.cacheDir.path}/water-routing')),
       );

  final WaterRoutingProblem? problem;
  final EndsShort? endsShort;

  /// The chart area everywhere, if any.
  final ChartArea? area;

  /// The boat each trip was asked for.
  final requests = <WaterRouteOptions>[];

  @override
  bool get hasRoutingData => true;

  @override
  bool offeredAt(LatLng point) => true;

  @override
  ChartArea? areaAt(LatLng point) => area;

  @override
  Future<WaterTrip> route(
    LatLon from,
    LatLon to, {
    WaterRouteOptions options = const WaterRouteOptions(),
  }) async {
    requests.add(options);
    if (problem case final p?) throw WaterRoutingException(p);
    return waterTrip(from, to, endsShort: endsShort);
  }
}
