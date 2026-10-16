import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:traxmap/traxmap.dart';
import 'package:path_provider/path_provider.dart';

import 'map_chrome.dart';
import 'meshtrax_demo.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'TraxMap Example',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(colorSchemeSeed: Colors.brown, useMaterial3: true),
    home: const MapScreen(),
  );
}

/// Watsonville to Monterey, the Phase 0 test area.
const _testArea = MapCamera(center: LatLng(36.76, -121.83), zoom: 10);

/// OVM_CAMERA="lat,lon,zoom" picks the starting view (handy for desktop testing).
MapCamera _startCamera() {
  final v = Platform.environment['OVM_CAMERA']
      ?.split(',')
      .map(double.tryParse)
      .toList();
  if (v == null || v.length != 3 || v.contains(null)) return _testArea;
  return MapCamera(center: LatLng(v[0]!, v[1]!), zoom: v[2]!);
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _styles = bundledStyles();
  PackManager? _manager;
  List<Pack> _packs = const [];
  List<String> _styleIds = const [];
  // OVM_STYLE=chart picks the starting style (handy for desktop testing).
  String _styleId = Platform.environment['OVM_STYLE'] ?? 'topo';
  String? _error;
  bool _loading = true;
  bool _stressOverlays = false;

  // OVM_CONTOURS=off and OVM_UNITS=metric set the starting state (desktop testing).
  bool _contours = Platform.environment['OVM_CONTOURS'] != 'off';
  Units _units =
      Units.parse(Platform.environment['OVM_UNITS']) ?? Units.imperial;

  /// Packs handed to the map: all installed, minus contours when switched off.
  /// Rebuilt only when that changes; a new list would reload the style.
  List<Pack> _mapPacks = const [];

  void _updateMapPacks() => _mapPacks = [
    for (final p in _packs)
      if (_contours || p.kind != PackKind.contours) p,
  ];
  MapCamera _camera = _startCamera();
  Size _viewSize = Size.zero;
  Duration _frameTime = Duration.zero;
  final _controller = OfflineMapController();

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
    _init();
  }

  @override
  void dispose() {
    SchedulerBinding.instance.removeTimingsCallback(_onTimings);
    super.dispose();
  }

  void _onTimings(List<FrameTiming> timings) {
    if (!mounted || timings.isEmpty) return;
    setState(() => _frameTime = timings.last.totalSpan);
  }

  Future<void> _init() async {
    try {
      final docs = await getApplicationDocumentsDirectory();
      final manager = PackManager(Directory('${docs.path}/traxmap/packs'));
      await _installBundledPacks(manager);
      final styleIds = await _styles.available();
      setState(() {
        _manager = manager;
        _styleIds = styleIds;
        if (!styleIds.contains(_styleId) && styleIds.isNotEmpty) {
          _styleId = styleIds.first;
        }
      });
      await _refresh();
      await _selectStyle(_styleId);
      // OVM_SCREEN=meshtrax opens the demo straight away (desktop testing).
      if (Platform.environment['OVM_SCREEN'] == 'meshtrax' &&
          _packs.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _openMeshTraxDemo(),
        );
      }
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      setState(() => _loading = false);
    }
  }

  /// Copies any `assets/packs/*.pmtiles` into the pack directory, so the
  /// example works without a download step. A pack is (re)installed when it
  /// is missing or differs from the bundled copy, e.g. after a pipeline rebuild.
  Future<void> _installBundledPacks(PackManager manager) async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final installed = {for (final p in await manager.listInstalled()) p.id: p};
    for (final asset in manifest.listAssets()) {
      if (!asset.startsWith('assets/packs/') || !asset.endsWith('.pmtiles')) {
        continue;
      }
      final id = asset.split('/').last.replaceAll('.pmtiles', '');
      final data = await rootBundle.load(asset);
      final current = installed[id];
      if (current != null && await _sameArchive(current.file, data)) continue;
      final tmp = File('${Directory.systemTemp.path}/$id.pmtiles');
      await tmp.writeAsBytes(data.buffer.asUint8List(), flush: true);
      try {
        await manager.install(tmp);
      } finally {
        await tmp.delete();
      }
    }
  }

  /// Same length and same header plus root directory (the first 16 KiB),
  /// which change whenever the archive's contents do.
  static Future<bool> _sameArchive(File file, ByteData bundled) async {
    if (await file.length() != bundled.lengthInBytes) return false;
    final n = math.min(16384, bundled.lengthInBytes);
    final raf = await file.open();
    try {
      final head = await raf.read(n);
      final want = bundled.buffer.asUint8List(bundled.offsetInBytes, n);
      for (var i = 0; i < n; i++) {
        if (head[i] != want[i]) return false;
      }
      return true;
    } finally {
      await raf.close();
    }
  }

  Future<void> _refresh() async {
    final packs = await _manager!.listInstalled(
      onError: (f, e) => _toast('Skipped ${f.path}: $e'),
    );
    setState(() {
      _packs = packs;
      _updateMapPacks();
    });
  }

  Future<void> _installFromPath() async {
    final controller = TextEditingController();
    final path = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Install pack'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Path to a .pmtiles file on this device',
          ),
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Install'),
          ),
        ],
      ),
    );
    if (path == null || path.trim().isEmpty) return;
    try {
      final pack = await _manager!.install(File(path.trim()));
      await _refresh();
      _toast('Installed ${pack.name}');
      _jumpTo(pack);
    } catch (e) {
      _toast('$e');
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    // Styles can declare metadata["ovm:dark"]; match the app chrome to them.
    return Theme(
      data: _darkStyle
          ? ThemeData(
              colorSchemeSeed: Colors.brown,
              brightness: Brightness.dark,
            )
          : Theme.of(context),
      child: _scaffold(),
    );
  }

  bool _darkStyle = false;
  MapStyleState? _styleState;

  Future<void> _selectStyle(String id) async {
    setState(() => _styleId = id);
    final dark = (await _styles.info(id)).isDark;
    if (mounted && _styleId == id) setState(() => _darkStyle = dark);
  }

  void _openMeshTraxDemo() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) =>
          MeshTraxDemo(packs: _mapPacks, styles: _styles, units: _units),
    ),
  );

  Widget _scaffold() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TraxMap'),
        actions: [
          if (_styleIds.isNotEmpty)
            DropdownButton<String>(
              value: _styleId,
              underline: const SizedBox(),
              items: [
                for (final id in _styleIds)
                  DropdownMenuItem(value: id, child: Text(id)),
              ],
              onChanged: (id) => _selectStyle(id!),
            ),
          IconButton(
            tooltip: _contours ? 'Hide contours' : 'Show contours',
            icon: Icon(_contours ? Icons.terrain : Icons.terrain_outlined),
            color: _contours ? null : Colors.black38,
            onPressed: () => setState(() {
              _contours = !_contours;
              _updateMapPacks();
            }),
          ),
          TextButton(
            onPressed: () => setState(
              () => _units = _units == Units.imperial
                  ? Units.metric
                  : Units.imperial,
            ),
            child: Text(_units == Units.imperial ? 'ft' : 'm'),
          ),
          IconButton(
            tooltip: 'MeshTrax-style demo',
            icon: const Icon(Icons.hub),
            onPressed: _packs.isEmpty ? null : _openMeshTraxDemo,
          ),
          IconButton(
            tooltip: 'Overlay stress test (500 markers, 50 lines)',
            icon: Icon(
              _stressOverlays
                  ? Icons.scatter_plot
                  : Icons.scatter_plot_outlined,
            ),
            onPressed: () => setState(() => _stressOverlays = !_stressOverlays),
          ),
          Builder(
            builder: (context) => IconButton(
              tooltip: 'Packs',
              icon: const Icon(Icons.layers),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),
      endDrawer: _PackDrawer(
        packs: _packs,
        directory: _manager?.root.path,
        onInstall: _manager == null ? null : _installFromPath,
        onDelete: (pack) async {
          await _manager!.delete(pack);
          await _refresh();
        },
        onSelect: (pack) {
          Navigator.pop(context);
          _jumpTo(pack);
        },
      ),
      body: _body(),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));
    if (_packs.isEmpty) return _EmptyState(onInstall: _installFromPath);
    return LayoutBuilder(
      builder: (context, constraints) {
        _viewSize = constraints.biggest;
        return Stack(
          children: [
            MapChrome(
              state: _styleState,
              map: OfflineMapView(
                controller: _controller,
                styleId: _styleId,
                packs: _mapPacks,
                units: _units,
                initialCamera: _camera,
                styleRegistry: _styles,
                overlays: _stressOverlays ? _stressTest : _demoOverlays,
                onCameraChanged: (c) => setState(() => _camera = c),
                onStyleLoaded: (s) => setState(() => _styleState = s),
              ),
            ),
            if (_packs.isNotEmpty)
              Positioned(left: 8, top: 8, child: _debugPanel()),
          ],
        );
      },
    );
  }

  void _jumpTo(Pack pack) => _controller.move(
    pack.bounds.center,
    zoom: pack.header.centerZoom.toDouble(),
  );

  Widget _debugPanel() {
    final viewport = _camera.visibleBounds(_viewSize);
    final serving = PackManager.bestFor(viewport, _packs);
    final ms = _frameTime.inMicroseconds / 1000;
    return DefaultTextStyle(
      style: const TextStyle(
        fontSize: 12,
        color: Colors.white,
        fontFeatures: [FontFeature.tabularFigures()],
      ),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('zoom ${_camera.zoom.toStringAsFixed(2)}'),
            Text(
              '${_camera.center.latitude.toStringAsFixed(4)}, '
              '${_camera.center.longitude.toStringAsFixed(4)}',
            ),
            Text(
              'frame ${ms.toStringAsFixed(1)} ms',
              style: TextStyle(color: ms > 16 ? Colors.orangeAccent : null),
            ),
            Text('pack ${serving?.id ?? '—'}'),
          ],
        ),
      ),
    );
  }

  List<MapOverlay> get _demoOverlays => [
    MapPolygon(
      id: 'coverage',
      points: const [
        LatLng(36.90, -121.95),
        LatLng(36.95, -121.75),
        LatLng(36.80, -121.68),
        LatLng(36.72, -121.88),
      ],
      onTap: () => _toast('Coverage polygon'),
    ),
    MapLine(
      id: 'path',
      points: const [
        LatLng(36.91, -121.76),
        LatLng(36.80, -121.79),
        LatLng(36.60, -121.89),
      ],
      onTap: () => _toast('Path Watsonville → Monterey'),
    ),
    MapMarker(
      id: 'watsonville',
      position: const LatLng(36.9102, -121.7569),
      label: 'Watsonville',
      onTap: () => _toast('Node: Watsonville'),
    ),
    MapMarker(
      id: 'monterey',
      position: const LatLng(36.6002, -121.8947),
      label: 'Monterey',
      onTap: () => _toast('Node: Monterey'),
    ),
  ];

  late final List<MapOverlay> _stressTest = () {
    final rnd = math.Random(42);
    LatLng randomPoint() => LatLng(
      36.55 + rnd.nextDouble() * 0.45,
      -122.05 + rnd.nextDouble() * 0.40,
    );
    return <MapOverlay>[
      for (var i = 0; i < 50; i++)
        MapLine(
          id: 'line$i',
          points: [randomPoint(), randomPoint(), randomPoint()],
          color: Colors.indigo.withValues(alpha: 0.6),
          width: 2,
          onTap: () => _toast('Line $i'),
        ),
      for (var i = 0; i < 500; i++)
        MapMarker(
          id: 'node$i',
          position: randomPoint(),
          radius: 4,
          label: 'n$i',
          labelMinZoom: 13,
          onTap: () => _toast('Node $i'),
        ),
    ];
  }();
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onInstall;

  const _EmptyState({required this.onInstall});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.map_outlined, size: 64),
          const SizedBox(height: 12),
          Text(
            'No map packs installed',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'Maps work fully offline from region packs. Put a .pmtiles file in '
            'example/assets/packs/ and rebuild, or install one from a file path.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onInstall,
            icon: const Icon(Icons.download),
            label: const Text('Install from file'),
          ),
        ],
      ),
    ),
  );
}

class _PackDrawer extends StatelessWidget {
  final List<Pack> packs;
  final String? directory;
  final VoidCallback? onInstall;
  final ValueChanged<Pack> onDelete;
  final ValueChanged<Pack> onSelect;

  const _PackDrawer({
    required this.packs,
    required this.directory,
    required this.onInstall,
    required this.onDelete,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) => Drawer(
    width: 360,
    child: SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            title: const Text('Installed packs'),
            subtitle: directory == null
                ? null
                : Text(directory!, style: const TextStyle(fontSize: 11)),
            trailing: IconButton(
              tooltip: 'Install from file',
              icon: const Icon(Icons.add),
              onPressed: onInstall,
            ),
          ),
          const Divider(height: 1),
          if (packs.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('None yet.'),
            ),
          Expanded(
            child: ListView(
              children: [for (final pack in packs) _packTile(context, pack)],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _packTile(BuildContext context, Pack pack) {
    final h = pack.header;
    final b = pack.bounds;
    final bytes = pack.file.lengthSync();
    return ExpansionTile(
      title: Text(pack.name),
      subtitle: Text(
        '${pack.kind.name} · z${h.minZoom}–${h.maxZoom} · ${_mb(bytes)}',
      ),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('id: ${pack.id}'),
        Text(
          'tiles: ${h.tileType.name}, ${h.tileCompression.name}; '
          '${h.addressedTiles} addressed, ${h.tileContents} unique',
        ),
        Text(
          'bbox: ${b.west.toStringAsFixed(3)}, ${b.south.toStringAsFixed(3)}, '
          '${b.east.toStringAsFixed(3)}, ${b.north.toStringAsFixed(3)}',
        ),
        if (pack.vectorLayers.isNotEmpty)
          Text('layers: ${pack.vectorLayers.join(', ')}'),
        if (pack.attribution != null) Text('attribution: ${pack.attribution}'),
        Row(
          children: [
            TextButton(
              onPressed: () => onSelect(pack),
              child: const Text('Go to'),
            ),
            TextButton(
              onPressed: () => onDelete(pack),
              child: const Text('Delete'),
            ),
          ],
        ),
      ],
    );
  }

  static String _mb(int bytes) => bytes < 1 << 20
      ? '${(bytes / 1024).toStringAsFixed(0)} KB'
      : '${(bytes / (1 << 20)).toStringAsFixed(1)} MB';
}
