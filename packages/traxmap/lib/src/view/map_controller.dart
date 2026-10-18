import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import '../packs/geo.dart';
import 'camera.dart';

/// How to frame the map on a set of points or a box.
class MapFit {
  final LatLngBounds? bounds;
  final List<LatLng>? points;
  final EdgeInsets padding;

  /// Highest zoom the fit may use (package zoom). Keeps a single point or a
  /// tight cluster from zooming all the way in.
  final double? maxZoom;

  const MapFit.bounds(
    LatLngBounds this.bounds, {
    this.padding = const EdgeInsets.all(32),
    this.maxZoom,
  }) : points = null;

  const MapFit.points(
    List<LatLng> this.points, {
    this.padding = const EdgeInsets.all(32),
    this.maxZoom,
  }) : bounds = null;

  /// The points to frame, whichever form this fit was given in.
  List<LatLng> get coordinates =>
      points ??
      [
        LatLng(bounds!.south, bounds!.west),
        LatLng(bounds!.north, bounds!.east),
      ];

  /// True when every coordinate is the same place (a fit has no extent).
  bool get isSinglePoint {
    final c = coordinates;
    return c.isNotEmpty && c.every((p) => p == c.first);
  }
}

/// Implemented by the renderer; not for apps.
@internal
abstract interface class OfflineMapDelegate {
  MapCamera get camera;
  LatLngBounds get visibleBounds;
  void move(LatLng center, double? zoom);
  void fit(MapFit fit);
}

/// Moves and reads the camera of an `OfflineMapView`.
///
/// Calls made before the map is ready are kept (the most recent one) and
/// applied as soon as it is, so apps don't need post-frame workarounds.
/// Listeners are notified when the camera moves and when the map becomes
/// ready or goes away, so it plugs into Provider / ListenableBuilder.
/// All zooms are package zooms (MapLibre convention).
class OfflineMapController extends ChangeNotifier {
  OfflineMapDelegate? _delegate;
  void Function(OfflineMapDelegate)? _pending;
  MapCamera? _last;

  bool get isReady => _delegate != null;

  /// The current camera, or the last known one while the map isn't ready.
  MapCamera? get camera => _delegate?.camera ?? _last;

  /// The visible area; null until the map is ready.
  LatLngBounds? get visibleBounds => _delegate?.visibleBounds;

  void move(LatLng center, {double? zoom}) => _run((d) => d.move(center, zoom));

  void fitBounds(
    LatLngBounds bounds, {
    EdgeInsets padding = const EdgeInsets.all(32),
    double? maxZoom,
  }) => _run(
    (d) => d.fit(MapFit.bounds(bounds, padding: padding, maxZoom: maxZoom)),
  );

  /// Frames [points]; does nothing for an empty list.
  void fitPoints(
    List<LatLng> points, {
    EdgeInsets padding = const EdgeInsets.all(32),
    double? maxZoom,
  }) {
    if (points.isEmpty) return;
    _run(
      (d) => d.fit(MapFit.points(points, padding: padding, maxZoom: maxZoom)),
    );
  }

  void _run(void Function(OfflineMapDelegate) command) {
    final delegate = _delegate;
    if (delegate == null) {
      _pending = command;
    } else {
      command(delegate);
    }
  }

  @internal
  void attach(OfflineMapDelegate delegate) {
    _delegate = delegate;
    final pending = _pending;
    _pending = null;
    pending?.call(delegate);
    notifyListeners();
  }

  /// Called by the renderer whenever the camera changes.
  @internal
  void cameraChanged() => notifyListeners();

  @internal
  void detach(OfflineMapDelegate delegate) {
    if (!identical(_delegate, delegate)) return;
    _last = delegate.camera;
    _delegate = null;
    notifyListeners();
  }
}
