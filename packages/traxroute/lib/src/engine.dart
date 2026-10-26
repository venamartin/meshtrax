import 'dart:io';

import 'route.dart';

/// Finds routes offline in the installed routing data. Linux uses
/// Valhalla's own service program; phones will use valhalla-mobile.
abstract interface class RoutingEngine {
  /// Opens [tiles], the combined tile file the routing store writes.
  /// Opening again switches to another file (a new build).
  Future<void> open(File tiles);

  /// Throws [RouteError] when there is no route.
  Future<RouteResult> route(RouteRequest request);

  Future<void> close();
}
