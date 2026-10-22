import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:flutter_test/flutter_test.dart';
import 'package:traxmap/traxmap.dart';
import 'package:traxmap/src/renderer/flutter_map_renderer.dart';

/// A style with no sources: the renderer needs no packs.
const _style = <String, Object?>{
  'version': 8,
  'sources': <String, Object?>{},
  'layers': [
    {
      'id': 'bg',
      'type': 'background',
      'paint': {'background-color': '#ffffff'},
    },
  ],
};

const _center = LatLng(36.8, -121.8);
const _camera = MapCamera(center: _center, zoom: 10);

void main() {
  late List<LatLng> taps;
  late List<LatLng> longPresses;
  late OfflineMapController controller;

  setUp(() {
    taps = [];
    longPresses = [];
    controller = OfflineMapController();
  });

  Future<void> pumpMap(
    WidgetTester tester, {
    List<MapOverlay> overlays = const [],
    List<Widget> extraLayers = const [],
    List<Widget> baseLayers = const [],
    ValueChanged<bool>? onCoverageChanged,
    MapCamera? camera = _camera,
    MapFit? fit,
  }) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: FlutterMapRenderer(
          style: _style,
          initialCamera: camera,
          initialFit: fit,
          overlays: overlays,
          extraLayers: extraLayers,
          baseLayers: baseLayers,
          onCoverageChanged: onCoverageChanged,
          controller: controller,
          onTap: taps.add,
          onLongPress: longPresses.add,
        ),
      ),
    );
    // Style load is async; then let the map lay out.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Offset mapCenter(WidgetTester tester) =>
      tester.getCenter(find.byType(fm.FlutterMap));

  testWidgets('map tap and long-press report a position', (tester) async {
    await pumpMap(tester);
    await tester.tapAt(mapCenter(tester));
    await tester.pump(const Duration(milliseconds: 400));
    expect(taps, hasLength(1));
    expect(taps.single.latitude, closeTo(_center.latitude, 0.01));
    expect(taps.single.longitude, closeTo(_center.longitude, 0.01));

    await tester.longPressAt(mapCenter(tester));
    await tester.pump(const Duration(milliseconds: 400));
    expect(longPresses, hasLength(1));
  });

  testWidgets('a marker tap goes to the marker, not the map', (tester) async {
    var hits = 0;
    await pumpMap(
      tester,
      overlays: [MapMarker(id: 'm', position: _center, onTap: () => hits++)],
    );
    await tester.tapAt(mapCenter(tester));
    await tester.pump(const Duration(milliseconds: 400));
    expect(hits, 1);
    expect(taps, isEmpty);
  });

  testWidgets('non-interactive markers and plain lines let taps through', (
    tester,
  ) async {
    var markerHits = 0;
    await pumpMap(
      tester,
      overlays: [
        const MapLine(
          id: 'l',
          points: [LatLng(36.7, -121.9), LatLng(36.9, -121.7)],
          width: 10,
        ),
        MapMarker(
          id: 'pin',
          position: _center,
          interactive: false,
          onTap: () => markerHits++,
        ),
      ],
    );
    await tester.tapAt(mapCenter(tester));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.longPressAt(mapCenter(tester));
    await tester.pump(const Duration(milliseconds: 400));
    expect(markerHits, 0);
    expect(taps, hasLength(1));
    expect(longPresses, hasLength(1));
  });

  testWidgets('a line with only onTap passes long-presses to the map', (
    tester,
  ) async {
    var lineTaps = 0;
    await pumpMap(
      tester,
      overlays: [
        MapLine(
          id: 'l',
          points: const [LatLng(36.7, -121.9), LatLng(36.9, -121.7)],
          width: 10,
          onTap: () => lineTaps++,
        ),
      ],
    );
    await tester.tapAt(mapCenter(tester));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.longPressAt(mapCenter(tester));
    await tester.pump(const Duration(milliseconds: 400));
    expect(lineTaps, 1);
    expect(taps, isEmpty);
    expect(longPresses, hasLength(1));
  });

  testWidgets('labels appear from their labelMinZoom', (tester) async {
    await pumpMap(
      tester,
      overlays: const [
        MapMarker(
          id: 'n',
          position: _center,
          label: 'Node A',
          labelMinZoom: 12,
        ),
      ],
    );
    expect(find.text('Node A'), findsNothing);
    controller.move(_center, zoom: 13);
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Node A'), findsOneWidget);
  });

  testWidgets('controller moves and fits in package zoom', (tester) async {
    // A command issued before the map is ready is applied once it is.
    controller.move(const LatLng(36.6, -121.9), zoom: 12);
    expect(controller.isReady, isFalse);
    await pumpMap(tester);
    expect(controller.isReady, isTrue);
    expect(controller.camera!.zoom, closeTo(12, 1e-6));
    expect(controller.camera!.center.latitude, closeTo(36.6, 1e-6));

    // A fit on one point clamps to maxZoom instead of zooming to the limit.
    controller.fitPoints(const [_center], maxZoom: 11);
    await tester.pump();
    expect(controller.camera!.zoom, closeTo(11, 1e-6));

    // A tight box respects maxZoom too.
    controller.fitBounds(
      const LatLngBounds(
        south: 36.8,
        west: -121.8,
        north: 36.8001,
        east: -121.7999,
      ),
      maxZoom: 14,
    );
    await tester.pump();
    expect(controller.camera!.zoom, lessThanOrEqualTo(14 + 1e-6));
    expect(controller.visibleBounds, isNotNull);

    // A box too big for the view stops at minZoom, around its centre.
    controller.fitBounds(
      const LatLngBounds(south: 45, west: -80, north: 62, east: -57),
      minZoom: 6,
    );
    await tester.pump();
    expect(controller.camera!.zoom, closeTo(6, 1e-6));
    expect(controller.camera!.center.longitude, closeTo(-68.5, 0.01));
  });

  testWidgets('initialFit frames the points', (tester) async {
    await pumpMap(
      tester,
      camera: null,
      fit: const MapFit.points([
        LatLng(36.6, -121.9),
        LatLng(36.9, -121.7),
      ], maxZoom: 15),
    );
    final c = controller.camera!;
    expect(c.center.latitude, closeTo(36.75, 0.05));
    expect(c.zoom, inInclusiveRange(7, 12));
  });

  testWidgets('extraLayers are drawn inside the map', (tester) async {
    await pumpMap(tester, extraLayers: const [Center(child: Text('EXTRA'))]);
    expect(find.text('EXTRA'), findsOneWidget);
  });

  testWidgets('updating overlays keeps the map and its vector layer', (
    tester,
  ) async {
    await pumpMap(tester);
    final mapState = tester.state(find.byType(fm.FlutterMap));
    await pumpMap(
      tester,
      overlays: const [MapMarker(id: 'x', position: _center)],
    );
    expect(
      identical(tester.state(find.byType(fm.FlutterMap)), mapState),
      isTrue,
    );
  });

  testWidgets('baseLayers sit between the map tiles and the overlays', (
    tester,
  ) async {
    const base = SizedBox(key: Key('base'));
    await pumpMap(
      tester,
      baseLayers: const [base],
      overlays: const [
        MapPolygon(
          id: 'p',
          points: [_center, LatLng(36.9, -121.8), LatLng(36.9, -121.7)],
        ),
        MapMarker(id: 'm', position: _center),
      ],
    );
    final children = tester
        .widget<fm.FlutterMap>(find.byType(fm.FlutterMap))
        .children;
    final baseAt = children.indexWhere((w) => w.key == const Key('base'));
    expect(baseAt, 1, reason: 'right after the vector tile layer');
    expect(
      children.indexWhere((w) => w is fm.PolygonLayer),
      greaterThan(baseAt),
    );
    expect(
      children.indexWhere((w) => w is fm.MarkerLayer),
      greaterThan(baseAt),
    );
  });

  testWidgets('polygons keep their holes', (tester) async {
    await pumpMap(
      tester,
      overlays: const [
        MapPolygon(
          id: 'p',
          points: [
            LatLng(36.7, -121.9),
            LatLng(36.9, -121.9),
            LatLng(36.9, -121.7),
            LatLng(36.7, -121.7),
          ],
          holes: [
            [
              LatLng(36.75, -121.85),
              LatLng(36.85, -121.85),
              LatLng(36.8, -121.75),
            ],
          ],
        ),
      ],
    );
    final layer = tester.widget<fm.PolygonLayer>(find.byType(fm.PolygonLayer));
    expect(layer.polygons.single.holePointsList, hasLength(1));
  });

  testWidgets('coverage is reported once, false without packs', (tester) async {
    final reports = <bool>[];
    await pumpMap(tester, onCoverageChanged: reports.add);
    await tester.pump(const Duration(milliseconds: 300));
    expect(reports, [false]);

    controller.move(const LatLng(37.2, -122.0), zoom: 12);
    await tester.pump(const Duration(milliseconds: 300));
    expect(reports, [false], reason: 'only changes are reported');
  });

  test('tile bitmaps default to twice the screen density, capped at 4', () {
    expect(FlutterMapRenderer.effectiveTileResolution(1, null), 2);
    expect(FlutterMapRenderer.effectiveTileResolution(1.5, null), 3);
    expect(FlutterMapRenderer.effectiveTileResolution(3, null), 4);
    expect(FlutterMapRenderer.effectiveTileResolution(4, null), 4);
    expect(FlutterMapRenderer.effectiveTileResolution(3, 1.5), 1.5);
  });

  test('zoom helpers convert both ways', () {
    expect(MapCamera.toFlutterMapZoom(13), 14);
    expect(MapCamera.fromFlutterMapZoom(14), 13);
  });
}
