import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:traxmap/traxmap.dart';

import '../connector/meshcore_connector.dart';
import '../helpers/drawing_map.dart';
import '../helpers/geo_format.dart';
import '../helpers/svg_drawing.dart';
import '../helpers/svg_paste.dart';
import '../l10n/l10n.dart';
import '../models/app_settings.dart';
import '../services/app_settings_service.dart';
import '../services/map_packs_service.dart';
import '../services/ui_view_state_service.dart';
import '../widgets/adaptive_app_bar_title.dart';
import '../widgets/app_map.dart';
import '../widgets/drawing_canvas.dart';
import '../widgets/drawing_map_view.dart';

enum _Tool { pen, route, line, arrow, cross, rect, circle, ellipse }

enum _MapChoice {
  none(null),
  standard(DrawingMapType.standard),
  usgs(DrawingMapType.usgs),
  charts(DrawingMapType.charts);

  final DrawingMapType? type;
  const _MapChoice(this.type);
}

/// Draw with a finger or paste an SVG, and see what will be sent: the pad
/// shows the message's own drawing over what you drew, simplified to the
/// finest detail that fits. A drawing can go over a map: move the map to
/// the place, tap Draw here, and draw. Pops the message text, or null.
class DrawingComposeScreen extends StatefulWidget {
  /// What the message box has left, after any reply's quote.
  final int maxBytes;

  const DrawingComposeScreen({super.key, required this.maxBytes});

  static Future<String?> open(BuildContext context, {required int maxBytes}) =>
      Navigator.push<String>(
        context,
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => DrawingComposeScreen(maxBytes: maxBytes),
        ),
      );

  @override
  State<DrawingComposeScreen> createState() => _DrawingComposeScreenState();
}

class _DrawingComposeScreenState extends State<DrawingComposeScreen>
    with SingleTickerProviderStateMixin {
  /// The pad's own units, so a drawing keeps its place when the pad changes
  /// size. They are a map frame's pixels, so over a map nothing converts.
  static const _pad = Size(DrawingMap.width, DrawingMap.height);

  /// A tapped X's reach from its centre, in pad units.
  static const _crossHalf = 16.0;

  /// How near the last point a tap finishes a route, in pad units.
  static const _routeEnd = 12.0;

  /// How near something already drawn a line, arrow or route point snaps
  /// onto it, in pad units: so an arrow can start right where a route ends.
  static const _snapReach = 20.0;

  /// The zoom a map opens at on the radio's position: about 760 m across.
  static const _openZoom = 16;

  late final _tabs = TabController(length: 2, vsync: this)
    ..addListener(() => setState(() {}));
  final _caption = TextEditingController();
  final _paste = TextEditingController();
  final _items = <SvgItem>[];
  var _tool = _Tool.pen;
  List<SvgPoint>? _stroke;
  SvgPoint? _start;
  var _routeOpen = false;

  /// The point the finger is snapped to, so it ticks once per snap.
  SvgPoint? _snappedTo;
  SvgFit? _fit;

  /// The message's drawing, in pad units, to draw over what you drew.
  List<List<SvgPoint>> _sent = const [];
  String? _pasteNote;
  var _pasteFailed = false;

  /// The map under the drawing; null for none.
  DrawingMapType? _mapType;

  /// The frame being drawn on, once Draw here has snapped the map to it.
  DrawingMap? _frame;

  /// While the map moves, the frame the drawing sits on, so it follows the
  /// ground. Null when the drawing was never on a map.
  DrawingMap? _anchor;
  final _mapController = OfflineMapController();
  MapCamera? _openCamera;
  Size _padSize = Size.zero;
  List<String> _credits = const [];

  /// Where the map has settled, for which maps are downloaded there.
  LatLng? _here;
  Timer? _settle;

  bool get _moving => _mapType != null && _frame == null;

  @override
  void initState() {
    super.initState();
    _mapController.addListener(_onCamera);
  }

  @override
  void dispose() {
    _settle?.cancel();
    _mapController
      ..removeListener(_onCamera)
      ..dispose();
    _tabs.dispose();
    _caption.dispose();
    _paste.dispose();
    super.dispose();
  }

  void _refit() {
    final caption = _caption.text.replaceAll(RegExp(r'\s*\n\s*'), ' ').trim();
    final fit = _items.isEmpty || _moving
        ? null
        : SvgWriter.fit(
            _items,
            budget: widget.maxBytes,
            caption: caption,
            map: _frame,
          );
    final lines =
        fit == null ? null : SvgDrawing.tryParse(fit.pathData)?.polylines();
    setState(() {
      _fit = fit;
      _sent = fit == null || lines == null
          ? const []
          : [
              for (final line in lines)
                [
                  for (final p in line)
                    (
                      x: fit.origin.x + p.x / fit.scale,
                      y: fit.origin.y + p.y / fit.scale,
                    ),
                ],
            ];
    });
  }

  // --- Drawing -------------------------------------------------------------

  SvgItem _shape(SvgPoint a, SvgPoint b) {
    final dx = b.x - a.x, dy = b.y - a.y;
    return switch (_tool) {
      _Tool.line || _Tool.pen || _Tool.route => SvgLineItem(a, b),
      _Tool.rect => SvgRect(a, b),
      _Tool.circle => () {
          final r = math.sqrt(dx * dx + dy * dy);
          return SvgEllipse(a, r, r);
        }(),
      _Tool.ellipse => SvgEllipse(
          (x: (a.x + b.x) / 2, y: (a.y + b.y) / 2),
          dx.abs() / 2,
          dy.abs() / 2,
        ),
      _Tool.arrow => SvgArrow(a, b),
      _Tool.cross => () {
          final reach = math.max(dx.abs(), dy.abs());
          return SvgCross(a, reach < 4 ? _crossHalf : reach);
        }(),
    };
  }

  static double _distance(SvgPoint a, SvgPoint b) =>
      math.sqrt((a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y));

  SvgPoint _toPad(Offset at, Size size) => (
        x: (at.dx / size.width * _pad.width).clamp(0, _pad.width),
        y: (at.dy / size.height * _pad.height).clamp(0, _pad.height),
      );

  /// Where other lines can join [item]: a route's points, and the ends of a
  /// stroke, line or arrow.
  static List<SvgPoint> _joints(SvgItem item) => switch (item) {
        SvgRoute(:final points) => points,
        SvgStroke(:final points) => [points.first, points.last],
        SvgLineItem(:final a, :final b) || SvgArrow(:final a, :final b) => [
            a,
            b,
          ],
        _ => const [],
      };

  /// [p], or the nearest joint within reach of anything drawn but [except].
  SvgPoint _snap(SvgPoint p, {SvgItem? except}) {
    SvgPoint? nearest;
    var reach = _snapReach;
    for (final item in _items) {
      if (identical(item, except)) continue;
      for (final joint in _joints(item)) {
        final d = _distance(joint, p);
        if (d < reach) {
          nearest = joint;
          reach = d;
        }
      }
    }
    if (nearest != _snappedTo) {
      _snappedTo = nearest;
      if (nearest != null) HapticFeedback.selectionClick();
    }
    return nearest ?? p;
  }

  void _down(Offset at, Size size) {
    final raw = _toPad(at, size);
    _start = raw;
    switch (_tool) {
      case _Tool.pen:
        _routeOpen = false;
        _stroke = [raw];
        _items.add(SvgStroke(_stroke!));
      case _Tool.route:
        final route = _routeOpen ? _items.last as SvgRoute : null;
        if (route != null && _distance(route.points.last, raw) < _routeEnd) {
          // Tapping the last point again finishes the route.
          _routeOpen = false;
          _start = null;
        } else if (route == null) {
          _items.add(SvgRoute([_snap(raw)]));
          _routeOpen = true;
        } else {
          _items.last = SvgRoute([...route.points, _snap(raw, except: route)]);
        }
      case _Tool.line || _Tool.arrow:
        final p = _snap(raw);
        _start = p;
        _routeOpen = false;
        _items.add(_shape(p, p));
      default:
        _routeOpen = false;
        _items.add(_shape(raw, raw));
    }
    setState(() {});
  }

  void _move(Offset at, Size size) {
    final start = _start;
    if (start == null) return;
    final p = _toPad(at, size);
    switch (_tool) {
      case _Tool.pen:
        final stroke = _stroke!;
        final last = stroke.last;
        if ((p.x - last.x).abs() + (p.y - last.y).abs() < 0.8) return;
        stroke.add(p);
      case _Tool.route:
        // A drag places the point just tapped.
        final route = _items.last as SvgRoute;
        _items.last = SvgRoute([
          ...route.points.take(route.points.length - 1),
          _snap(p, except: route),
        ]);
      case _Tool.line || _Tool.arrow:
        _items.last = _shape(start, _snap(p, except: _items.last));
      default:
        _items.last = _shape(start, p);
    }
    setState(() {});
  }

  void _up() {
    _snappedTo = null;
    if (_start == null) return;
    _start = null;
    _stroke = null;
    _refit();
  }

  void _undo() {
    // A route loses its last point first, as each tap placed one.
    final last = _items.last;
    if (last is SvgRoute && last.points.length > 1) {
      _items.last = SvgRoute(last.points.sublist(0, last.points.length - 1));
    } else {
      _items.removeLast();
      _routeOpen = false;
    }
    _refit();
  }

  void _clear() {
    _items.clear();
    _routeOpen = false;
    _refit();
  }

  void _usePaste() {
    final l10n = context.l10n;
    try {
      final strokes = SvgPaste.strokes(_paste.text);
      var minX = double.infinity, minY = double.infinity;
      var maxX = double.negativeInfinity, maxY = double.negativeInfinity;
      for (final s in strokes) {
        for (final p in s) {
          minX = math.min(minX, p.x);
          maxX = math.max(maxX, p.x);
          minY = math.min(minY, p.y);
          maxY = math.max(maxY, p.y);
        }
      }
      final k = math.min(
        _pad.width * 0.84 / math.max(maxX - minX, 1e-9),
        _pad.height * 0.84 / math.max(maxY - minY, 1e-9),
      );
      final ox = (_pad.width - (maxX - minX) * k) / 2;
      final oy = (_pad.height - (maxY - minY) * k) / 2;
      _items
        ..clear()
        ..addAll([
          for (final s in strokes)
            SvgStroke([
              for (final p in s)
                (x: ox + (p.x - minX) * k, y: oy + (p.y - minY) * k),
            ]),
        ]);
      _routeOpen = false;
      // Pasted onto the pad, not onto ground the map has moved away from.
      _anchor = null;
      _pasteNote = l10n.drawing_pasteNote;
      _pasteFailed = false;
      _refit();
    } on SvgPasteError catch (e) {
      setState(() {
        _pasteFailed = true;
        _pasteNote = switch (e.problem) {
          SvgPasteProblem.empty => l10n.drawing_pasteEmpty,
          SvgPasteProblem.tooBig => l10n.drawing_pasteTooBig,
          SvgPasteProblem.unreadable => l10n.drawing_pasteUnreadable,
          SvgPasteProblem.nothing => l10n.drawing_pasteNothing,
        };
      });
    }
  }

  // --- The map -------------------------------------------------------------

  /// The radio's own position, if it has one.
  LatLng? _myPosition() {
    final connector = Provider.of<MeshCoreConnector?>(context, listen: false);
    final lat = connector?.selfLatitude, lon = connector?.selfLongitude;
    return connector != null && connector.hasValidLocation(lat, lon)
        ? LatLng(lat!, lon!)
        : null;
  }

  double get _padWidth =>
      _padSize.width > 0 ? _padSize.width : DrawingMap.width;

  /// Where a map opens: on the radio, else where the Map tab last was.
  MapCamera _startCamera() {
    final me = _myPosition();
    if (me != null) {
      return MapCamera(
        center: me,
        zoom: drawingCameraZoom(_openZoom, _padWidth),
      );
    }
    return Provider.of<UiViewStateService?>(context, listen: false)
            ?.mapCamera ??
        const MapCamera(center: LatLng(0, 0), zoom: 2);
  }

  void _chooseMap(DrawingMapType? type) {
    setState(() {
      if (type == null) {
        _frame = null;
        _anchor = null;
      } else if (_mapType == null) {
        _openCamera = _startCamera();
        _frame = null;
        _anchor = null;
      } else {
        _frame = _frame?.withType(type);
        _anchor = _anchor?.withType(type);
      }
      _mapType = type;
      _routeOpen = false;
    });
    _refit();
  }

  void _onCamera() {
    _settle?.cancel();
    _settle = Timer(const Duration(milliseconds: 300), () {
      final camera = _mapController.camera;
      if (!mounted || camera == null) return;
      setState(() => _here = camera.center);
      // Moved past where that map is downloaded: Standard, which isn't
      // greyed out anywhere.
      final type = _mapType;
      if (_moving &&
          type != null &&
          type != DrawingMapType.standard &&
          !_downloadedHere(type)) {
        _chooseMap(DrawingMapType.standard);
      }
    });
  }

  bool _downloadedHere(DrawingMapType type) {
    if (type == DrawingMapType.standard) return true;
    final maps = Provider.of<MapPacksService?>(context, listen: false);
    final here = _here ?? _openCamera?.center ?? _startCamera().center;
    return maps?.downloadedAt(type.mapType, here) ?? false;
  }

  /// Snaps the map to the frame that will be sent, and draws on it.
  void _drawHere() {
    final camera = _mapController.camera ?? _openCamera;
    final type = _mapType;
    if (camera == null || type == null) return;
    final width = _padWidth;
    final frame = DrawingMap.snap(
      zoom: camera.zoom + 1 - math.log(width / DrawingMap.width) / math.ln2,
      lat: camera.center.latitude,
      lon: camera.center.longitude,
      type: type,
    );
    // What was drawn stays on the same ground.
    final anchor = _anchor;
    if (anchor != null) {
      final scale = math.pow(2, frame.zoom - anchor.zoom).toDouble();
      SvgPoint onFrame(SvgPoint p) => frame.fromWorld(anchor.toWorld(p));
      for (var i = 0; i < _items.length; i++) {
        _items[i] = _items[i].transformed(onFrame, scale);
      }
    }
    _anchor = null;
    _frame = frame;
    _mapController.move(
      LatLng(frame.lat, frame.lon),
      zoom: drawingCameraZoom(frame.zoom, width),
    );
    _refit();
  }

  void _moveMap() {
    setState(() {
      _anchor = _items.isEmpty ? null : _frame;
      _frame = null;
      _routeOpen = false;
    });
    _refit();
  }

  /// Keeps the map showing the same ground when the pad changes size, as
  /// it does when the keyboard opens.
  void _onPadSize(Size size) {
    final old = _padSize.width;
    _padSize = size;
    if (old == 0 || old == size.width || _mapType == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final frame = _frame;
      final camera = _mapController.camera;
      if (frame != null) {
        _mapController.move(
          LatLng(frame.lat, frame.lon),
          zoom: drawingCameraZoom(frame.zoom, size.width),
        );
      } else if (camera != null) {
        _mapController.move(
          camera.center,
          zoom: camera.zoom + math.log(size.width / old) / math.ln2,
        );
      }
    });
  }

  // --- Layout --------------------------------------------------------------

  Widget _tools() {
    final l10n = context.l10n;
    return SegmentedButton<_Tool>(
      showSelectedIcon: false,
      expandedInsets: EdgeInsets.zero,
      style: const ButtonStyle(
        visualDensity: VisualDensity.compact,
        padding: WidgetStatePropertyAll(EdgeInsets.zero),
      ),
      segments: [
        for (final (tool, icon, label) in [
          (_Tool.pen, const Icon(Icons.gesture), l10n.drawing_toolPen),
          (_Tool.route, const Icon(Icons.polyline_outlined), l10n.drawing_toolRoute),
          (_Tool.line, const Icon(Icons.horizontal_rule), l10n.drawing_toolLine),
          (_Tool.arrow, const Icon(Icons.arrow_right_alt), l10n.drawing_toolArrow),
          (_Tool.cross, const Icon(Icons.close), l10n.drawing_toolX),
          (_Tool.rect, const Icon(Icons.crop_square), l10n.drawing_toolRect),
          (_Tool.circle, const Icon(Icons.circle_outlined), l10n.drawing_toolCircle),
          (_Tool.ellipse, const _OvalIcon(), l10n.drawing_toolEllipse),
        ])
          ButtonSegment(value: tool, icon: icon, tooltip: label),
      ],
      selected: {_tool},
      onSelectionChanged: _moving
          ? null
          : (s) => setState(() {
                _tool = s.first;
                _routeOpen = false;
              }),
    );
  }

  Widget _pastePanel() {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _paste,
          minLines: 2,
          maxLines: 4,
          autocorrect: false,
          enableSuggestions: false,
          style: drawingCodeStyle.copyWith(fontSize: 13),
          decoration: InputDecoration(
            hintText: l10n.drawing_pasteHint,
            isDense: true,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            FilledButton.tonal(
              onPressed: _usePaste,
              child: Text(l10n.drawing_pasteUse),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _pasteNote ?? l10n.drawing_pasteNote,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _pasteFailed ? theme.colorScheme.error : null,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _mapChoice() {
    final l10n = context.l10n;
    return SegmentedButton<_MapChoice>(
      showSelectedIcon: false,
      expandedInsets: EdgeInsets.zero,
      style: const ButtonStyle(visualDensity: VisualDensity.compact),
      segments: [
        for (final (choice, label) in [
          (_MapChoice.none, l10n.drawing_mapNone),
          (_MapChoice.standard, l10n.mapLayers_standard),
          (_MapChoice.usgs, l10n.drawing_mapUsgs),
          (_MapChoice.charts, l10n.mapLayers_charts),
        ])
          ButtonSegment(
            value: choice,
            label: Text(label, maxLines: 1, softWrap: false),
            // Greyed out where it isn't downloaded, unless it's showing.
            enabled: choice.type == null ||
                choice.type == _mapType ||
                _downloadedHere(choice.type!),
          ),
      ],
      selected: {
        _MapChoice.values.firstWhere((c) => c.type == _mapType),
      },
      onSelectionChanged: (s) => _chooseMap(s.first.type),
    );
  }

  Widget _padView(DrawingLook look) {
    final l10n = context.l10n;
    final type = _mapType;
    final frame = _frame;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        _onPadSize(size);
        final me = _moving ? _myPosition() : null;
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (type != null)
                IgnorePointer(
                  ignoring: !_moving,
                  child: AppMap(
                    controller: _mapController,
                    compact: true,
                    exact: frame != null,
                    mapType: type.mapType,
                    initialCamera: _openCamera,
                    minZoom: math.min(
                      2,
                      drawingCameraZoom(DrawingMap.minZoom, size.width),
                    ),
                    maxZoom: math.max(
                      17,
                      drawingCameraZoom(DrawingMap.maxZoom, size.width),
                    ),
                    onCreditsChanged: (credits) {
                      if (mounted && !listEquals(credits, _credits)) {
                        setState(() => _credits = credits);
                      }
                    },
                  ),
                ),
              IgnorePointer(
                ignoring: _moving,
                child: Listener(
                  onPointerDown: (e) => _down(e.localPosition, size),
                  onPointerMove: (e) => _move(e.localPosition, size),
                  onPointerUp: (_) => _up(),
                  onPointerCancel: (_) => _up(),
                  child: CustomPaint(
                    size: size,
                    painter: _PadPainter(
                      items: List.of(_items),
                      sent: _sent,
                      look: look,
                      onMap: type != null,
                      routeDots: _routeOpen
                          ? (_items.last as SvgRoute).points
                          : const [],
                      anchor: _moving ? _anchor : null,
                      camera: _mapController,
                    ),
                  ),
                ),
              ),
              if (_moving) ...[
                if (me != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton.filledTonal(
                      tooltip: l10n.map_myLocation,
                      icon: const Icon(Icons.my_location),
                      onPressed: () => _mapController.move(
                        me,
                        zoom: drawingCameraZoom(_openZoom, size.width),
                      ),
                    ),
                  ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 12,
                  child: Center(
                    child: FilledButton.icon(
                      onPressed: _drawHere,
                      icon: const Icon(Icons.draw),
                      label: Text(l10n.drawing_drawHere),
                    ),
                  ),
                ),
              ] else if (type != null)
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton.filledTonal(
                    tooltip: l10n.drawing_moveMap,
                    icon: const Icon(Icons.open_with),
                    onPressed: _moveMap,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _status() {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    if (_moving) {
      return Text(l10n.drawing_mapHint, style: theme.textTheme.bodySmall);
    }
    final fit = _fit;
    if (fit == null) {
      return Text(
        _tool == _Tool.route ? l10n.drawing_routeHint : l10n.drawing_empty,
        style: theme.textTheme.bodySmall,
      );
    }
    final bytes = l10n.drawing_bytes(fit.bytes, widget.maxBytes);
    if (!fit.fits) {
      return Text(
        '$bytes. ${l10n.drawing_tooDetailed}',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.error,
        ),
      );
    }
    final detail = fit.tolerance == 0
        ? l10n.drawing_keptAll
        : l10n.drawing_simplified(fit.tolerance.toStringAsFixed(1));
    final frame = _frame;
    final units = context.select<AppSettingsService, UnitSystem>(
      (s) => s.settings.unitSystem,
    );
    final where = frame == null
        ? ''
        : ' · ${l10n.drawing_mapAcross(
            switch (frame.type) {
              DrawingMapType.standard => l10n.mapLayers_standard,
              DrawingMapType.usgs => l10n.mapLayers_usgs,
              DrawingMapType.charts => l10n.mapLayers_charts,
            },
            GeoFormat.distanceText(frame.metersAcross, units),
          )}';
    return Text(
      '$bytes · ${l10n.drawing_points(fit.points)}$where. $detail',
      style: theme.textTheme.bodySmall,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final look = context.select<AppSettingsService, DrawingLook>(
      (s) => DrawingLook.of(s.settings),
    );
    final mapTheme = context.select<AppSettingsService, String>(
      (s) => s.settings.mapTheme,
    );
    final maps = DrawingMapView.available(context);
    // Follows downloads, and has the service learn what each map needs, so
    // the map choice greys out the right ones before any map is shown.
    Provider.of<MapPacksService?>(context)?.styleId(MapType.osm, dark: false);
    final fit = _fit;
    return Scaffold(
      appBar: AppBar(
        title: AdaptiveAppBarTitle(l10n.tray_drawing),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: l10n.drawing_undo,
            onPressed: _items.isEmpty ? null : _undo,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: l10n.common_clear,
            onPressed: _items.isEmpty ? null : _clear,
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: l10n.drawing_tabDraw),
            Tab(text: l10n.drawing_tabPaste),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_tabs.index == 0) _tools() else _pastePanel(),
              const SizedBox(height: 12),
              // Not in a scroll view: a drag on the pad must draw, not
              // scroll. Its 4:3 is the card's shape and a map frame's; the
              // keyboard shrinks it.
              Flexible(
                child: Align(
                  alignment: Alignment.topCenter,
                  heightFactor: 1,
                  child: AspectRatio(
                    aspectRatio: _pad.width / _pad.height,
                    child: _padView(look),
                  ),
                ),
              ),
              // The map's credits stay off the drawing.
              if (_mapType != null && _credits.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: AttributionChip(
                      credits: _credits,
                      dark: mapTheme == 'dark',
                    ),
                  ),
                ),
              if (maps) ...[
                const SizedBox(height: 12),
                _mapChoice(),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: _caption,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: l10n.drawing_caption,
                  hintText: l10n.drawing_captionHint,
                  isDense: true,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) => _refit(),
              ),
              const SizedBox(height: 8),
              _status(),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: fit == null || !fit.fits
                      ? null
                      : () => Navigator.pop(context, fit.wire),
                  child: Text(l10n.dialog_insert),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// An ellipse outline the size and color of the icons around it. Neither
/// icon set has one; its egg reads as a teardrop.
class _OvalIcon extends StatelessWidget {
  const _OvalIcon();

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final size = theme.size ?? 24;
    return SizedBox.square(
      dimension: size,
      child: Center(
        child: Container(
          width: size * 0.92,
          height: size * 0.6,
          decoration: ShapeDecoration(
            shape: OvalBorder(
              side: BorderSide(
                color: theme.color ?? Theme.of(context).colorScheme.onSurface,
                width: size / 12,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// What you drew, faintly, and over it the drawing the message carries. On
/// a map the lines get a dark edge; while the map moves, what you drew
/// follows the ground under it.
class _PadPainter extends CustomPainter {
  final List<SvgItem> items;
  final List<List<SvgPoint>> sent;
  final DrawingLook look;
  final bool onMap;
  final List<SvgPoint> routeDots;

  /// The frame [items] sit on while the map moves, placed by [camera].
  final DrawingMap? anchor;
  final OfflineMapController camera;

  _PadPainter({
    required this.items,
    required this.sent,
    required this.look,
    required this.onMap,
    required this.routeDots,
    required this.anchor,
    required this.camera,
  }) : super(repaint: anchor == null ? null : camera);

  @override
  void paint(Canvas canvas, Size size) {
    if (!onMap) {
      canvas.drawRect(Offset.zero & size, Paint()..color = DrawingLook.screen);
    }
    final k = size.width / DrawingMap.width;
    var at = (SvgPoint p) => Offset(p.x * k, p.y * k);
    final anchor = this.anchor, view = camera.camera;
    if (anchor != null && view != null) {
      // traxmap zooms count 512-pixel tiles.
      final world = 512 * math.pow(2, view.zoom).toDouble();
      final c = DrawingMap.project(view.center.latitude, view.center.longitude);
      at = (p) {
        final w = anchor.toWorld(p);
        return Offset(
          (w.x - c.x) * world + size.width / 2,
          (w.y - c.y) * world + size.height / 2,
        );
      };
    }
    List<List<Offset>> place(Iterable<List<SvgPoint>> lines) => [
          for (final line in lines) [for (final p in line) at(p)],
        ];
    final drawn = place(items.expand((item) => item.outline));

    if (onMap && sent.isEmpty) {
      MapInkPainter(lines: drawn, look: look).paint(canvas, size);
    } else {
      final faint = Paint()
        ..style = PaintingStyle.stroke
        ..color = look.pen.withValues(alpha: onMap ? 0.5 : 0.3)
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      for (final line in drawn) {
        final path = Path()..moveTo(line.first.dx, line.first.dy);
        for (final p in line.skip(1)) {
          path.lineTo(p.dx, p.dy);
        }
        canvas.drawPath(path, faint);
      }
      if (onMap) {
        MapInkPainter(lines: place(sent), look: look).paint(canvas, size);
      } else {
        final ink = Paint()
          ..style = PaintingStyle.stroke
          ..color = look.pen
          ..strokeWidth = look.lineWidth
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
        final path = Path();
        for (final line in place(sent)) {
          path.moveTo(line.first.dx, line.first.dy);
          for (final p in line.skip(1)) {
            path.lineTo(p.dx, p.dy);
          }
        }
        canvas.drawPath(path, ink);
      }
    }

    // The open route's points, so you can see where the next tap joins.
    final dot = Paint()..color = look.pen;
    final ring = Paint()..color = const Color(0xB3000000);
    for (final p in routeDots) {
      if (onMap) canvas.drawCircle(at(p), 5, ring);
      canvas.drawCircle(at(p), 3.5, dot);
    }
  }

  @override
  bool shouldRepaint(_PadPainter old) => true;
}
