import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:flutter_map_vector_tiles/flutter_map_vector_tiles.dart' as vt;
import 'package:latlong2/latlong.dart' as ll;

import '../packs/geo.dart';
import '../view/camera.dart';
import '../view/map_controller.dart';
import '../view/overlays.dart';
import 'local_pmtiles_provider.dart';

/// Renders a resolved style with flutter_map + flutter_map_vector_tiles.
///
/// Chosen for now because it runs on every platform including Linux desktop.
/// The Phase 2 measurements on phones still decide whether it stays.
///
/// All zooms in and out of this widget are package zooms (MapLibre
/// convention); [_FlutterMapRendererState._zoomOffset] is the only place
/// they meet flutter_map's.
class FlutterMapRenderer extends StatefulWidget {
  /// A style already resolved by `StyleRegistry`: vector sources point at
  /// `pmtiles://file:///…` URLs.
  final Map<String, Object?> style;
  final MapCamera? initialCamera;
  final MapFit? initialFit;
  final double minZoom;
  final double maxZoom;
  final List<MapOverlay> overlays;
  final MapLabelStyle labelStyle;
  final List<Widget> extraLayers;

  /// Raw flutter_map layers drawn above the vector tiles and below the
  /// overlays, e.g. online raster tiles where no pack covers the view.
  final List<Widget> baseLayers;

  /// Style sources whose tiles count as "the map is covered here".
  final Set<String> coverageSources;

  /// Reports, once the camera settles, whether [coverageSources] have a tile
  /// at the view centre. Called only when the answer changes.
  final ValueChanged<bool>? onCoverageChanged;
  final OfflineMapController? controller;
  final ValueChanged<MapCamera>? onCameraChanged;
  final ValueChanged<LatLng>? onTap;
  final ValueChanged<LatLng>? onLongPress;

  /// Device pixels per logical pixel for tile bitmaps; null = auto.
  ///
  /// flutter_map_vector_tiles draws each tile once into a bitmap at a whole
  /// zoom level and stretches it up to 2x until the next level, which looks
  /// soft just below each whole zoom. Drawing the bitmaps denser than the
  /// screen keeps lines sharp; the auto value is twice the screen density,
  /// capped at 4. Costs memory and raster time in proportion to its square.
  final double? tileResolution;

  const FlutterMapRenderer({
    super.key,
    required this.style,
    this.initialCamera,
    this.initialFit,
    this.minZoom = 0,
    this.maxZoom = 18,
    this.overlays = const [],
    this.labelStyle = const MapLabelStyle(),
    this.extraLayers = const [],
    this.baseLayers = const [],
    this.coverageSources = const {},
    this.onCoverageChanged,
    this.controller,
    this.onCameraChanged,
    this.onTap,
    this.onLongPress,
    this.tileResolution,
  });

  /// The tile bitmap density used for a screen of [devicePixelRatio].
  static double effectiveTileResolution(
    double devicePixelRatio,
    double? requested,
  ) =>
      requested ??
      math.max(devicePixelRatio, math.min(devicePixelRatio * 2, 4));

  @override
  State<FlutterMapRenderer> createState() => _FlutterMapRendererState();
}

class _FlutterMapRendererState extends State<FlutterMapRenderer>
    implements OfflineMapDelegate {
  // flutter_map zooms use 256px tiles; MapCamera and the styles use
  // MapLibre's 512px convention, one level lower for the same view.
  static const double _zoomOffset = 1;

  final _map = fm.MapController();
  bool _ready = false;

  vt.TileProviders? _providers;
  var _local = <String, LocalPmTilesVectorTileProvider>{};
  Widget? _vectorLayer; // kept so parent rebuilds don't rebuild it
  Object? _error;

  bool? _covered;
  Timer? _coverageTimer;

  final _lineHits = fm.LayerHitNotifier<MapOverlay>(null);
  final _polygonHits = fm.LayerHitNotifier<MapOverlay>(null);
  late _Overlays _overlays = _Overlays.from(widget.overlays);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(FlutterMapRenderer old) {
    super.didUpdateWidget(old);
    if (!identical(old.style, widget.style)) _load();
    if (!setEquals(old.coverageSources, widget.coverageSources)) {
      _scheduleCoverage();
    }
    if (!identical(old.overlays, widget.overlays)) {
      _overlays = _Overlays.from(widget.overlays);
    }
    if (!identical(old.controller, widget.controller)) {
      old.controller?.detach(this);
      if (_ready) widget.controller?.attach(this);
    }
  }

  Future<void> _load() async {
    final style = widget.style;
    final providers = <String, LocalPmTilesVectorTileProvider>{};
    try {
      final sources = (style['sources'] as Map<String, Object?>?) ?? {};
      for (final MapEntry(:key, :value) in sources.entries) {
        final source = value as Map<String, Object?>;
        final url = source['url'];
        if (source['type'] != 'vector' || url is! String) continue;
        if (!url.startsWith('pmtiles://')) {
          throw UnsupportedError('Source "$key" is not a local pack: $url');
        }
        final path = Uri.parse(url.substring('pmtiles://'.length)).toFilePath();
        providers[key] = await LocalPmTilesVectorTileProvider.open(File(path));
      }
      final theme = vt.ThemeReader(
        logger: kDebugMode ? const vt.Logger.console() : const vt.Logger.noop(),
      ).read(style);
      if (!mounted || !identical(style, widget.style)) {
        vt.TileProviders(providers).dispose();
        return;
      }
      _providers?.dispose();
      final tileProviders = vt.TileProviders(providers);
      setState(() {
        _providers = tileProviders;
        _local = providers;
        _vectorLayer = vt.VectorTileLayer(
          theme: theme,
          tileProviders: tileProviders,
        );
        _error = null;
      });
      _scheduleCoverage();
    } catch (e) {
      vt.TileProviders(providers).dispose();
      if (mounted) setState(() => _error = e);
    }
  }

  /// Checks coverage once the camera has been still for a moment.
  void _scheduleCoverage() {
    if (widget.onCoverageChanged == null) return;
    _coverageTimer?.cancel();
    _coverageTimer = Timer(const Duration(milliseconds: 250), _checkCoverage);
  }

  Future<void> _checkCoverage() async {
    if (!_ready || !mounted) return;
    final view = camera;
    final zoom = view.zoom.floor();
    var covered = false;
    for (final source in widget.coverageSources) {
      final provider = _local[source];
      // Below a pack's lowest zoom it draws nothing; above its highest the
      // renderer stretches its top-zoom tiles.
      if (provider == null || zoom < provider.minimumZoom) continue;
      final z = math.min(zoom, provider.maximumZoom);
      if (await provider.contains(_tileAt(view.center, z))) {
        covered = true;
        break;
      }
    }
    if (!mounted || covered == _covered) return;
    _covered = covered;
    widget.onCoverageChanged?.call(covered);
  }

  static vt.TileKey _tileAt(LatLng p, int z) {
    final n = 1 << z;
    final lat = p.latitude.clamp(-85.0511, 85.0511) * math.pi / 180;
    final x = ((p.longitude + 180) / 360 * n).floor().clamp(0, n - 1);
    final y =
        ((1 - math.log(math.tan(lat) + 1 / math.cos(lat)) / math.pi) / 2 * n)
            .floor()
            .clamp(0, n - 1);
    return vt.TileKey(z, x, y);
  }

  @override
  void dispose() {
    _coverageTimer?.cancel();
    widget.controller?.detach(this);
    _map.dispose();
    _providers?.dispose();
    _lineHits.dispose();
    _polygonHits.dispose();
    super.dispose();
  }

  // --- OfflineMapDelegate -------------------------------------------------

  @override
  MapCamera get camera => MapCamera(
    center: _ovm(_map.camera.center),
    zoom: _map.camera.zoom - _zoomOffset,
  );

  @override
  LatLngBounds get visibleBounds {
    final b = _map.camera.visibleBounds;
    return LatLngBounds(
      south: b.south,
      west: b.west,
      north: b.north,
      east: b.east,
    );
  }

  @override
  void move(LatLng center, double? zoom) => _map.move(
    _ll(center),
    zoom == null ? _map.camera.zoom : zoom + _zoomOffset,
  );

  @override
  void fit(MapFit fit) {
    if (fit.isSinglePoint) {
      // A fit without extent would zoom to the limit; clamp it instead.
      move(fit.coordinates.first, fit.maxZoom ?? widget.maxZoom);
    } else {
      _map.fitCamera(_cameraFit(fit));
    }
  }

  fm.CameraFit _cameraFit(MapFit fit) => fm.CameraFit.coordinates(
    coordinates: [for (final p in fit.coordinates) _ll(p)],
    padding: fit.padding,
    maxZoom: fit.maxZoom == null ? null : fit.maxZoom! + _zoomOffset,
  );

  void _onMapReady() {
    _ready = true;
    widget.controller?.attach(this);
    _scheduleCoverage();
    // Report the starting camera too (apps derive label visibility etc. from
    // it); after the frame, as listeners usually call setState.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onCameraChanged?.call(camera);
    });
  }

  // --- Gestures -------------------------------------------------------------

  void _handleTap(fm.TapPosition _, ll.LatLng p) => widget.onTap?.call(_ovm(p));

  void _handleLongPress(fm.TapPosition _, ll.LatLng p) =>
      widget.onLongPress?.call(_ovm(p));

  void _handlePosition(fm.MapCamera c, bool _) {
    widget.onCameraChanged?.call(
      MapCamera(center: _ovm(c.center), zoom: c.zoom - _zoomOffset),
    );
    if (_ready) widget.controller?.cameraChanged();
    _scheduleCoverage();
  }

  /// Wraps an interactive line/polygon layer: a tap or long-press on an
  /// overlay goes to its handler; if it has none for that gesture, the map's
  /// handler gets it instead, so overlays never swallow map gestures.
  Widget _interactive(fm.LayerHitNotifier<MapOverlay> hits, Widget layer) =>
      GestureDetector(
        behavior: HitTestBehavior.deferToChild,
        onTap: () {
          final hit = hits.value;
          final o = hit?.hitValues.firstOrNull;
          if (o?.onTap != null) {
            o!.onTap!();
          } else if (hit != null) {
            widget.onTap?.call(_ovm(hit.coordinate));
          }
        },
        onLongPress: () {
          final hit = hits.value;
          final o = hit?.hitValues.firstOrNull;
          if (o?.onLongPress != null) {
            o!.onLongPress!();
          } else if (hit != null) {
            widget.onLongPress?.call(_ovm(hit.coordinate));
          }
        },
        child: layer,
      );

  // --- Build ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(child: Text('Map failed to load: $_error'));
    }
    final vectorLayer = _vectorLayer;
    if (vectorLayer == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final fit = widget.initialFit;
    final camera =
        widget.initialCamera ?? const MapCamera(center: LatLng(20, 0), zoom: 1);
    final singlePointFit = fit != null && fit.isSinglePoint;
    final o = _overlays;
    return fm.FlutterMap(
      mapController: _map,
      options: fm.MapOptions(
        initialCenter: _ll(
          singlePointFit ? fit.coordinates.first : camera.center,
        ),
        initialZoom:
            (singlePointFit ? (fit.maxZoom ?? widget.maxZoom) : camera.zoom) +
            _zoomOffset,
        initialCameraFit: fit != null && !singlePointFit
            ? _cameraFit(fit)
            : null,
        minZoom: widget.minZoom + _zoomOffset,
        maxZoom: widget.maxZoom + _zoomOffset,
        interactionOptions: const fm.InteractionOptions(
          flags: fm.InteractiveFlag.all & ~fm.InteractiveFlag.rotate,
        ),
        onMapReady: _onMapReady,
        onTap: _handleTap,
        onLongPress: _handleLongPress,
        onPositionChanged: _handlePosition,
      ),
      children: [
        // The tile layer reads the screen density from MediaQuery to size
        // its bitmaps; give it the (higher) tile resolution instead.
        Builder(
          builder: (context) {
            final media = MediaQuery.of(context);
            return MediaQuery(
              data: media.copyWith(
                devicePixelRatio: FlutterMapRenderer.effectiveTileResolution(
                  media.devicePixelRatio,
                  widget.tileResolution,
                ),
              ),
              child: vectorLayer,
            );
          },
        ),
        ...widget.baseLayers,
        if (o.passivePolygons.isNotEmpty)
          fm.PolygonLayer(polygons: o.passivePolygons),
        if (o.activePolygons.isNotEmpty)
          _interactive(
            _polygonHits,
            fm.PolygonLayer<MapOverlay>(
              hitNotifier: _polygonHits,
              polygons: o.activePolygons,
            ),
          ),
        if (o.passiveLines.isNotEmpty)
          fm.PolylineLayer(polylines: o.passiveLines),
        if (o.activeLines.isNotEmpty)
          _interactive(
            _lineHits,
            fm.PolylineLayer<MapOverlay>(
              hitNotifier: _lineHits,
              polylines: o.activeLines,
            ),
          ),
        if (o.markers.isNotEmpty) fm.MarkerLayer(markers: o.markers),
        if (o.labelled.isNotEmpty)
          _MarkerLabelLayer(markers: o.labelled, style: widget.labelStyle),
        ...widget.extraLayers,
      ],
    );
  }

  static ll.LatLng _ll(LatLng p) => ll.LatLng(p.latitude, p.longitude);
  static LatLng _ovm(ll.LatLng p) => LatLng(p.latitude, p.longitude);
}

/// flutter_map versions of the app's overlays, rebuilt only when the
/// overlay list changes. Overlays without handlers go in passive layers,
/// which take no part in hit testing.
class _Overlays {
  final passivePolygons = <fm.Polygon<Object>>[];
  final activePolygons = <fm.Polygon<MapOverlay>>[];
  final passiveLines = <fm.Polyline<Object>>[];
  final activeLines = <fm.Polyline<MapOverlay>>[];
  final markers = <fm.Marker>[];
  final labelled = <MapMarker>[];

  _Overlays.from(List<MapOverlay> overlays) {
    for (final o in overlays) {
      switch (o) {
        case MapPolygon():
          final points = [for (final p in o.points) _pt(p)];
          final holes = [
            for (final hole in o.holes) [for (final p in hole) _pt(p)],
          ];
          if (o.hasHandlers) {
            activePolygons.add(
              fm.Polygon<MapOverlay>(
                points: points,
                holePointsList: holes,
                color: o.fillColor,
                borderColor: o.strokeColor,
                borderStrokeWidth: o.strokeWidth,
                hitValue: o,
              ),
            );
          } else {
            passivePolygons.add(
              fm.Polygon<Object>(
                points: points,
                holePointsList: holes,
                color: o.fillColor,
                borderColor: o.strokeColor,
                borderStrokeWidth: o.strokeWidth,
              ),
            );
          }
        case MapLine():
          final points = [for (final p in o.points) _pt(p)];
          final pattern = switch (o.pattern) {
            MapLinePattern.solid => const fm.StrokePattern.solid(),
            MapLinePattern.dashed => fm.StrokePattern.dashed(
              segments: [o.width * 3, o.width * 2],
            ),
            MapLinePattern.dotted => const fm.StrokePattern.dotted(),
          };
          if (o.hasHandlers) {
            activeLines.add(
              fm.Polyline<MapOverlay>(
                points: points,
                color: o.color,
                strokeWidth: o.width,
                pattern: pattern,
                hitValue: o,
              ),
            );
          } else {
            passiveLines.add(
              fm.Polyline<Object>(
                points: points,
                color: o.color,
                strokeWidth: o.width,
                pattern: pattern,
              ),
            );
          }
        case MapMarker():
          markers.add(_marker(o));
          if (o.label != null) labelled.add(o);
      }
    }
  }

  static fm.Marker _marker(MapMarker o) {
    final size = o.effectiveSize;
    final Widget body =
        o.child ??
        Center(
          child: Container(
            width: o.radius * 2,
            height: o.radius * 2,
            decoration: BoxDecoration(
              color: o.color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
          ),
        );
    return fm.Marker(
      point: _pt(o.position),
      width: size.width,
      height: size.height,
      // flutter_map aligns the marker box relative to the point; an anchor
      // says which point of the box sits on it, i.e. the opposite.
      alignment: Alignment(-o.anchor.x, -o.anchor.y),
      child: o.receivesGestures
          ? GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: o.onTap,
              onLongPress: o.onLongPress,
              child: body,
            )
          : IgnorePointer(child: body),
    );
  }

  static ll.LatLng _pt(LatLng p) => ll.LatLng(p.latitude, p.longitude);
}

/// Marker labels as pills above their markers, shown only from each
/// marker's `labelMinZoom`. Rebuilds with the camera; flutter_map's
/// MarkerLayer culls the off-screen ones.
class _MarkerLabelLayer extends StatelessWidget {
  final List<MapMarker> markers;
  final MapLabelStyle style;

  const _MarkerLabelLayer({required this.markers, required this.style});

  @override
  Widget build(BuildContext context) {
    final zoom = fm.MapCamera.of(context).zoom - 1;
    return fm.MarkerLayer(
      markers: [
        for (final m in markers)
          if (m.labelMinZoom == null || zoom >= m.labelMinZoom!)
            fm.Marker(
              point: ll.LatLng(m.position.latitude, m.position.longitude),
              width: style.maxWidth,
              height: 24,
              alignment: Alignment.topCenter, // label box sits above the point
              child: IgnorePointer(
                child: Transform.translate(
                  // Lift it above the marker: the marker's height above its
                  // anchor point, plus a small gap.
                  offset: Offset(
                    0,
                    -(m.effectiveSize.height * (1 + m.anchor.y) / 2) - 2,
                  ),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: style.background,
                        borderRadius: BorderRadius.circular(style.radius),
                      ),
                      child: Text(
                        m.label!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: style.textStyle,
                      ),
                    ),
                  ),
                ),
              ),
            ),
      ],
    );
  }
}
