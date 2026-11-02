import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:traxmap/traxmap.dart';

/// Renders map pictures without a screen, for judging the base map and the
/// styles before they ship. From packages/traxmap:
///
///     flutter --show-test-device run -d flutter-tester \
///       -t tool/world_preview.dart \
///       --dart-define=PACKS=/maps/world.pmtiles,/maps/us-rhode-island-osm.pmtiles \
///       --dart-define='SHOTS=ri-z9|osm-light|41.37,-71.83|9;mini|osm-dark|44.06,-121.31|13|300,180' \
///       --dart-define=OUT=../../build/world-preview
///
/// Each shot (`name|style|lat,lon|zoom`, optionally `|width,height`, 600×400
/// by default) is written to OUT/name.png at twice its size. STYLES reads
/// the styles from another folder than assets/styles; WAIT_MS is how long
/// each shot gets to load (4000).
///
/// `flutter run` rather than `flutter test`: the test fonts draw text as
/// boxes, the tester's run mode uses the system's.
const _packs = String.fromEnvironment('PACKS');
const _shots = String.fromEnvironment('SHOTS');
const _styles = String.fromEnvironment('STYLES', defaultValue: 'assets/styles');
const _out = String.fromEnvironment('OUT', defaultValue: 'build/preview');
const _waitMs = int.fromEnvironment('WAIT_MS', defaultValue: 4000);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final packs = [
    for (final path in _packs.split(','))
      if (path.isNotEmpty) await PackManager.open(File(path)),
  ];
  final styles = StyleRegistry(_FolderStyles(Directory(_styles)));
  final shot = ValueNotifier<_Shot?>(null);
  final boundary = GlobalKey();
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ValueListenableBuilder(
        valueListenable: shot,
        builder: (context, s, _) => s == null
            ? const SizedBox.shrink()
            : Align(
                alignment: Alignment.topLeft,
                child: RepaintBoundary(
                  key: boundary,
                  child: SizedBox(
                    width: s.width,
                    height: s.height,
                    child: OfflineMapView(
                      key: ValueKey(s.name),
                      styleId: s.style,
                      styleRegistry: styles,
                      packs: packs,
                      initialCamera: MapCamera(center: s.center, zoom: s.zoom),
                    ),
                  ),
                ),
              ),
      ),
    ),
  );
  for (final s in _Shot.parse(_shots)) {
    shot.value = s;
    // The test device has no display to pace frames: draw them by hand while
    // the tiles load.
    for (var waited = 0; waited < _waitMs; waited += 50) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      WidgetsBinding.instance.scheduleWarmUpFrame();
    }
    final render =
        boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await render.toImage(pixelRatio: 2);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('$_out/${s.name}.png')..createSync(recursive: true);
    file.writeAsBytesSync(png!.buffer.asUint8List());
    stdout.writeln('wrote ${file.path}');
  }
  exit(0);
}

class _Shot {
  final String name;
  final String style;
  final LatLng center;
  final double zoom;
  final double width;
  final double height;

  _Shot(
    this.name,
    this.style,
    this.center,
    this.zoom, {
    this.width = 600,
    this.height = 400,
  });

  static List<_Shot> parse(String shots) => [
    for (final shot in shots.split(';'))
      if (shot.trim().isNotEmpty) _parse(shot.trim().split('|')),
  ];

  static _Shot _parse(List<String> f) {
    final [lat, lon] = f[2].split(',').map(double.parse).toList();
    final size = f.length > 4
        ? f[4].split(',').map(double.parse).toList()
        : const [600.0, 400.0];
    return _Shot(
      f[0],
      f[1],
      LatLng(lat, lon),
      double.parse(f[3]),
      width: size[0],
      height: size[1],
    );
  }
}

/// The styles in a folder, read fresh: lets a preview try style variants
/// without rebuilding the asset bundle.
class _FolderStyles implements StyleSource {
  final Directory dir;
  _FolderStyles(this.dir);

  @override
  Future<List<String>> ids() async => [
    for (final f in dir.listSync())
      if (f.path.endsWith('.json'))
        f.uri.pathSegments.last.replaceAll('.json', ''),
  ]..sort();

  @override
  Future<Map<String, Object?>> load(String id) async =>
      jsonDecode(await File('${dir.path}/$id.json').readAsString())
          as Map<String, Object?>;
}
