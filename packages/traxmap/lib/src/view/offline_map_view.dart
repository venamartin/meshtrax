import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/widgets.dart';

import '../packs/attribution.dart';
import '../packs/geo.dart';
import '../packs/pack.dart';
import '../renderer/flutter_map_renderer.dart';
import '../styles/asset_style_source.dart';
import '../styles/style_info.dart';
import '../styles/style_registry.dart';
import 'camera.dart';
import 'map_controller.dart';
import 'overlays.dart';

/// What the app needs to show around the map once a style has loaded.
///
/// The package draws no chrome: the app must display [credits] (required by
/// the OpenStreetMap licence and the other sources) and, when present,
/// [disclaimer] (e.g. "Not for navigation" on chart styles).
class MapStyleState {
  final StyleInfo info;

  /// Credits for the packs this style actually draws from, as plain text.
  final List<String> credits;

  /// Notices the data's licences require next to the credits (pack metadata
  /// `notice`), e.g. Copernicus' liability statement.
  final List<String> notices;

  /// From the style's `metadata["ovm:disclaimer"]`, if any.
  String? get disclaimer => info.disclaimer;

  /// The packs the resolved style uses.
  final List<Pack> packsInUse;

  const MapStyleState({
    required this.info,
    required this.credits,
    this.notices = const [],
    required this.packsInUse,
  });
}

/// The offline map surface: renders installed packs with a style and draws
/// the app's overlays. It has no other UI; screens, buttons, banners and
/// credits belong to the app (see [onStyleLoaded]).
///
/// Rendered with flutter_map + flutter_map_vector_tiles, reading the packs
/// straight from local files. Nothing touches the network. All zooms are
/// package zooms (MapLibre convention, one lower than flutter_map's; see
/// [MapCamera.fromFlutterMapZoom]).
class OfflineMapView extends StatefulWidget {
  final String styleId;
  final List<Pack> packs;

  /// Where the map starts; [initialFit] wins when both are given. Without
  /// either, the map starts on the whole world.
  final MapCamera? initialCamera;
  final MapFit? initialFit;

  final double minZoom;
  final double maxZoom;

  final OfflineMapController? controller;
  final List<MapOverlay> overlays;
  final MapLabelStyle labelStyle;

  /// Escape hatch: extra flutter_map 8.x layer widgets, drawn above
  /// everything else (e.g. layers not yet ported to [MapOverlay]s). This and
  /// [baseLayers] are the only parts of the API tied to flutter_map.
  final List<Widget> extraLayers;

  /// flutter_map 8.x layers drawn above the map's own tiles and below the
  /// overlays: e.g. online raster tiles in the gaps [onTileCoverage]
  /// reports.
  final List<Widget> baseLayers;

  /// Whether the style's required packs ([StyleInfo.requiredKinds]) have a
  /// tile at the view centre, reported when the camera settles and only
  /// when it changes. False below a pack's lowest zoom, and with no packs.
  final ValueChanged<bool>? onCoverageChanged;

  /// The tiles the style's required packs draw, whenever the style or the
  /// packs change: [TileCoverage.covers] lets [baseLayers] skip them.
  final ValueChanged<TileCoverage>? onTileCoverage;

  final ValueChanged<MapCamera>? onCameraChanged;

  /// Taps and long-presses on the map itself (not on an overlay that
  /// handles them).
  final ValueChanged<LatLng>? onTap;
  final ValueChanged<LatLng>? onLongPress;

  /// Called whenever a style has been loaded, with the credits and
  /// disclaimer the app must show, and whether the style is dark.
  final ValueChanged<MapStyleState>? onStyleLoaded;

  /// Defaults to the styles bundled with the package ([bundledStyles]).
  final StyleRegistry? styleRegistry;

  /// Units for labels (contour heights, soundings, peaks).
  final Units units;

  /// The app draws its own points of interest here: the style drops its
  /// icons for them (see [StyleContext.appPlaces]).
  final bool appPlaces;

  /// Style layer groups to leave out (see [StyleContext.hiddenGroups]).
  final Set<String> hiddenGroups;

  /// Named lists for the style's placeholders (see [StyleContext.lists]).
  final Map<String, List<String>> lists;

  /// Device pixels per logical pixel for map tile bitmaps; null picks
  /// twice the screen density (capped at 4) so lines stay sharp between
  /// whole zoom levels. Lower it to save memory on constrained devices.
  final double? tileResolution;

  const OfflineMapView({
    super.key,
    required this.styleId,
    required this.packs,
    this.initialCamera,
    this.initialFit,
    this.minZoom = 0,
    this.maxZoom = 18,
    this.controller,
    this.overlays = const [],
    this.labelStyle = const MapLabelStyle(),
    this.extraLayers = const [],
    this.baseLayers = const [],
    this.onCoverageChanged,
    this.onTileCoverage,
    this.onCameraChanged,
    this.onTap,
    this.onLongPress,
    this.onStyleLoaded,
    this.styleRegistry,
    this.units = Units.imperial,
    this.appPlaces = false,
    this.hiddenGroups = const {},
    this.lists = const {},
    this.tileResolution,
  });

  @override
  State<OfflineMapView> createState() => _OfflineMapViewState();
}

class _OfflineMapViewState extends State<OfflineMapView> {
  late final StyleRegistry _registry = widget.styleRegistry ?? bundledStyles();
  Map<String, Object?>? _style;
  Object? _styleError;

  /// Style sources that count for [OfflineMapView.onCoverageChanged].
  Set<String> _coverageSources = const {};

  /// Kept so the camera survives the renderer being remounted.
  MapCamera? _lastCamera;

  @override
  void initState() {
    super.initState();
    _loadStyle();
  }

  @override
  void didUpdateWidget(OfflineMapView old) {
    super.didUpdateWidget(old);
    if (old.styleId != widget.styleId ||
        !_samePacks(old.packs, widget.packs) ||
        old.units != widget.units ||
        old.appPlaces != widget.appPlaces ||
        !setEquals(old.hiddenGroups, widget.hiddenGroups) ||
        !_sameLists(old.lists, widget.lists)) {
      _loadStyle();
    }
  }

  /// Lists compare by identity, so apps may rebuild the map around them.
  static bool _sameLists(
    Map<String, List<String>> a,
    Map<String, List<String>> b,
  ) =>
      a.length == b.length &&
      a.entries.every((e) => identical(b[e.key], e.value));

  /// Packs compare by identity on disk, so apps may rebuild the list freely.
  static bool _samePacks(List<Pack> a, List<Pack> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id || a[i].file.path != b[i].file.path) return false;
    }
    return true;
  }

  Future<void> _loadStyle() async {
    // All packs of a kind serve one source (neighbouring regions), the
    // requested units' variant first.
    final packsByKind = StyleContext.packsByKind(
      widget.packs,
      units: widget.units,
    );
    final id = widget.styleId;
    try {
      final context = StyleContext(
        packs: packsByKind,
        units: widget.units,
        sprite: bundledSprites,
        appPlaces: widget.appPlaces,
        hiddenGroups: widget.hiddenGroups,
        lists: widget.lists,
      );
      final style = await _registry.load(id, context);
      if (!mounted || id != widget.styleId) return;
      final used = packsUsedBy(
        style,
        packsByKind.values.expand((l) => l),
        context,
      );
      final info = StyleInfo.fromStyle(id, style);
      final requiredUrls = {
        for (final pack in used)
          if (info.requiredKinds.isEmpty ||
              info.requiredKinds.contains(pack.kind))
            context.pmtilesUrl(pack),
      };
      setState(() {
        _style = style;
        _styleError = null;
        _coverageSources = {
          for (final MapEntry(:key, :value)
              in ((style['sources'] as Map?) ?? const {}).entries)
            if (value is Map && sourceUrls(value).any(requiredUrls.contains))
              key as String,
        };
      });
      widget.onStyleLoaded?.call(
        MapStyleState(
          info: info,
          credits: attributionOf(used),
          notices: noticesOf(used),
          packsInUse: used,
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _styleError = e);
    }
  }

  void _onCamera(MapCamera camera) {
    _lastCamera = camera;
    widget.onCameraChanged?.call(camera);
  }

  @override
  Widget build(BuildContext context) {
    if (_styleError != null) {
      return Center(child: Text('Style "${widget.styleId}": $_styleError'));
    }
    final style = _style;
    if (style == null) return const SizedBox.expand();
    return FlutterMapRenderer(
      style: style,
      initialCamera: _lastCamera ?? widget.initialCamera,
      initialFit: _lastCamera == null ? widget.initialFit : null,
      minZoom: widget.minZoom,
      maxZoom: widget.maxZoom,
      controller: widget.controller,
      overlays: widget.overlays,
      labelStyle: widget.labelStyle,
      extraLayers: widget.extraLayers,
      baseLayers: widget.baseLayers,
      coverageSources: _coverageSources,
      onCoverageChanged: widget.onCoverageChanged,
      onTileCoverage: widget.onTileCoverage,
      onCameraChanged: _onCamera,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      tileResolution: widget.tileResolution,
    );
  }
}
