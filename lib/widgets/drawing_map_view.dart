import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:traxmap/traxmap.dart';

import '../helpers/drawing_map.dart';
import '../helpers/svg_drawing.dart';
import '../l10n/l10n.dart';
import '../screens/offline_maps_screen.dart';
import '../services/app_settings_service.dart';
import '../services/map_packs_service.dart';
import '../utils/format_bytes.dart';
import '../utils/platform_info.dart';
import 'app_map.dart';
import 'drawing_canvas.dart';

extension DrawingMapTypeMap on DrawingMapType {
  MapType get mapType => switch (this) {
        DrawingMapType.standard => MapType.osm,
        DrawingMapType.usgs => MapType.usgs,
        DrawingMapType.charts => MapType.charts,
      };
}

/// The camera zoom that shows a [zoom] frame [width] wide: traxmap zooms
/// count 512-pixel tiles, one level below a drawing map's.
double drawingCameraZoom(int zoom, double width) =>
    zoom - 1 + math.log(width / DrawingMap.width) / math.ln2;

/// The map [map] is shown over here: the one it was sent with where it's
/// downloaded, otherwise Standard, which is the base map where nothing is.
MapType drawingMapTypeHere(MapPacksService maps, DrawingMap map) {
  final sent = map.type.mapType;
  final center = LatLng(map.lat, map.lon);
  return sent == MapType.osm || maps.downloadedAt(sent, center)
      ? sent
      : MapType.osm;
}

/// A drawing's lines over a map: the pen color with a thin dark edge, so
/// they read on light and dark maps alike. No glow or scanlines here.
class MapInkPainter extends CustomPainter {
  final List<List<Offset>> lines;
  final DrawingLook look;

  const MapInkPainter({required this.lines, required this.look});

  static Paint _stroke(Color color, double width) => Paint()
    ..style = PaintingStyle.stroke
    ..color = color
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    for (final line in lines) {
      if (line.isEmpty) continue;
      path.moveTo(line.first.dx, line.first.dy);
      for (final p in line.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
    }
    final width = look.lineWidth * 1.5;
    canvas.drawPath(path, _stroke(const Color(0xB3000000), width + 2.5));
    canvas.drawPath(path, _stroke(look.pen, width));
  }

  @override
  bool shouldRepaint(MapInkPainter old) =>
      !identical(old.lines, lines) || old.look != look;
}

/// A drawing over its map, as a chat card or the viewer shows it: the map
/// at exactly the drawing's frame, the lines on top, the map's credits under
/// it, and a note when this phone has no detail for the place.
class DrawingMapView extends StatefulWidget {
  final SvgDrawing drawing;
  final DrawingLook look;
  final double width;
  final VoidCallback? onTap;

  /// The note's colors; the theme's by default.
  final Color? noteColor, onNoteColor;

  const DrawingMapView({
    super.key,
    required this.drawing,
    required this.look,
    required this.width,
    this.onTap,
    this.noteColor,
    this.onNoteColor,
  });

  /// Whether this app can draw maps: not on the web, which has no map packs.
  static bool available(BuildContext context) =>
      !PlatformInfo.isWeb &&
      Provider.of<MapPacksService?>(context, listen: false) != null;

  @override
  State<DrawingMapView> createState() => _DrawingMapViewState();
}

class _DrawingMapViewState extends State<DrawingMapView> {
  /// Where the base map's detail ends; past it, no download means no map.
  static const _baseMapDetail = 11;

  List<String> _credits = const [];
  late List<List<SvgPoint>> _lines;

  @override
  void initState() {
    super.initState();
    _lines = widget.drawing.polylines() ?? const [];
  }

  @override
  void didUpdateWidget(DrawingMapView old) {
    super.didUpdateWidget(old);
    if (old.drawing.pathData != widget.drawing.pathData) {
      _lines = widget.drawing.polylines() ?? const [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final map = widget.drawing.map!;
    final maps = context.watch<MapPacksService>();
    final dark = context.select<AppSettingsService, bool>(
      (s) => s.settings.mapTheme == 'dark',
    );
    final type = drawingMapTypeHere(maps, map);
    final center = LatLng(map.lat, map.lon);
    final width = widget.width;
    final zoom = drawingCameraZoom(map.zoom, width);
    final k = width / 100;
    final missing =
        map.zoom > _baseMapDetail && !maps.downloadedAt(type, center);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: width,
            height: width * DrawingMap.height / DrawingMap.width,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ExcludeSemantics(
                  child: IgnorePointer(
                    child: AppMap(
                      key: ValueKey((map, width, type)),
                      compact: true,
                      exact: true,
                      mapType: type,
                      initialCamera: MapCamera(center: center, zoom: zoom),
                      minZoom: math.min(2, zoom),
                      maxZoom: math.max(17, zoom),
                      onCreditsChanged: (credits) {
                        if (mounted && !listEquals(credits, _credits)) {
                          setState(() => _credits = credits);
                        }
                      },
                    ),
                  ),
                ),
                CustomPaint(
                  painter: MapInkPainter(
                    lines: [
                      for (final line in _lines)
                        [for (final p in line) Offset(p.x * k, p.y * k)],
                    ],
                    look: widget.look,
                  ),
                ),
                if (widget.onTap != null)
                  Material(
                    color: Colors.transparent,
                    child: InkWell(onTap: widget.onTap),
                  ),
              ],
            ),
          ),
        ),
        if (_credits.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: AttributionChip(credits: _credits, dark: dark),
          ),
        if (missing)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _NotDownloaded(
              center: center,
              color: widget.noteColor,
              onColor: widget.onNoteColor,
            ),
          ),
      ],
    );
  }
}

/// No detail here for the drawing's place: what to download.
class _NotDownloaded extends StatelessWidget {
  final LatLng center;
  final Color? color, onColor;

  const _NotDownloaded({required this.center, this.color, this.onColor});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final maps = context.watch<MapPacksService>();
    final region = maps.regions?.regionAt(center);
    final packs = region == null
        ? const <PackIndexEntry>[]
        : maps.defaultSelection(region.path);
    final size = packs.fold(0, (sum, e) => sum + e.bytes);
    final ink = onColor ?? scheme.onSecondaryContainer;
    return Material(
      color: color ?? scheme.secondaryContainer,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        dense: true,
        leading: Icon(Icons.download_for_offline_outlined, color: ink),
        title: Text(
          l10n.drawing_mapNotDownloaded,
          style: TextStyle(color: ink, fontSize: 14),
        ),
        subtitle: Text(
          packs.isEmpty
              ? l10n.map_downloadForDetail
              : l10n.map_downloadRegion(region!.name, formatBytes(size)),
          style: TextStyle(color: ink, fontSize: 12),
        ),
        trailing: Icon(Icons.chevron_right, color: ink),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => OfflineMapsScreen(
              initialRegionPath: packs.isEmpty ? null : region!.path,
            ),
          ),
        ),
      ),
    );
  }
}
