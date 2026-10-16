import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:traxmap/latlong2.dart';
import 'package:traxmap/traxmap.dart';

import 'map_chrome.dart';

/// Mimics MeshTrax's main map on top of `OfflineMapView`, to show how its
/// pieces map onto the package API (see FINDINGS.md, "MeshTrax integration"):
/// node markers by type with labels from z13, the "You" marker, shared flag
/// pins, a highlight pin, path building, line-of-sight segments, an area
/// rectangle, long-press menu, fit-to-nodes, dark mode, and a flutter_map
/// layer through `extraLayers`.
class MeshTraxDemo extends StatefulWidget {
  final List<Pack> packs;
  final StyleRegistry styles;
  final Units units;

  const MeshTraxDemo({
    super.key,
    required this.packs,
    required this.styles,
    required this.units,
  });

  @override
  State<MeshTraxDemo> createState() => _MeshTraxDemoState();
}

enum _NodeType { chat, repeater, room, sensor, other }

class _Contact {
  final String name;
  final _NodeType type;
  final LatLng position;

  const _Contact(this.name, this.type, this.position);
}

// MeshTrax's _getNodeColor / _getNodeIcon.
Color _nodeColor(_NodeType t) => switch (t) {
  _NodeType.chat => Colors.blue,
  _NodeType.repeater => Colors.green,
  _NodeType.room => Colors.purple,
  _NodeType.sensor => Colors.orange,
  _NodeType.other => Colors.grey,
};

IconData _nodeIcon(_NodeType t) => switch (t) {
  _NodeType.chat => Icons.person,
  _NodeType.repeater => Icons.router,
  _NodeType.room => Icons.meeting_room,
  _NodeType.sensor => Icons.sensors,
  _NodeType.other => Icons.device_unknown,
};

/// Labels show from this package zoom (MeshTrax: flutter_map zoom 14).
const _labelMinZoom = 13.0;

class _MeshTraxDemoState extends State<MeshTraxDemo> {
  final _controller = OfflineMapController();
  late final List<_Contact> _contacts = _fakeContacts();
  LatLng _self = const LatLng(36.9102, -121.7569); // Watsonville
  final _pins = <LatLng>[
    const LatLng(36.968, -121.902),
    const LatLng(36.803, -121.787),
  ];
  LatLng? _highlight = const LatLng(36.6002, -121.8947); // Monterey
  bool _pathMode = false;
  final _path = <_Contact>[];

  String _styleId = Platform.environment['OVM_STYLE'] ?? 'outdoor';
  bool _dark = false;
  double _zoom = 0;
  MapStyleState? _styleState;
  late List<MapOverlay> _overlays = _buildOverlays();

  static List<_Contact> _fakeContacts() {
    final rnd = math.Random(7);
    const names = [
      'Ridge',
      'Harbor',
      'Pajaro',
      'Aptos',
      'Corralitos',
      'Elkhorn',
      'Marina',
      'Seaside',
      'Soquel',
      'Freedom',
      'Prunedale',
      'Castroville',
      'Sunset',
      'Manresa',
      'Larkin',
      'Amesti',
      'Interlaken',
      'Vega',
      'Springfield',
      'Moss',
      'Salinas Rd',
      'Hilltop',
      'Bluff',
      'Valley',
      'Mesa',
    ];
    return [
      for (var i = 0; i < names.length; i++)
        _Contact(
          names[i],
          _NodeType.values[rnd.nextInt(_NodeType.values.length)],
          LatLng(
            36.62 + rnd.nextDouble() * 0.34,
            -121.92 + rnd.nextDouble() * 0.24,
          ),
        ),
    ];
  }

  @override
  void initState() {
    super.initState();
    widget.styles.info(_styleId).then((info) {
      if (mounted) setState(() => _dark = info.isDark);
    });
  }

  void _refresh() => setState(() => _overlays = _buildOverlays());

  /// OVM_CAMERA="lat,lon,zoom" overrides the fit (desktop screenshots).
  static final MapCamera? _envCamera = () {
    final v = Platform.environment['OVM_CAMERA']
        ?.split(',')
        .map(double.tryParse)
        .toList();
    if (v == null || v.length != 3 || v.contains(null)) return null;
    return MapCamera(center: LatLng(v[0]!, v[1]!), zoom: v[2]!);
  }();

  List<LatLng> get _nodePositions => [
    _self,
    for (final c in _contacts) c.position,
  ];

  List<MapOverlay> _buildOverlays() {
    final repeater = _contacts.firstWhere(
      (c) => c.type == _NodeType.repeater,
      orElse: () => _contacts.first,
    );
    final mid1 = _lerp(_self, repeater.position, 0.4);
    final mid2 = _lerp(_self, repeater.position, 0.75);
    return [
      // Area rectangle (MeshTrax's cache-area picker).
      const MapPolygon(
        id: 'area',
        points: [
          LatLng(36.70, -121.80),
          LatLng(36.70, -121.72),
          LatLng(36.76, -121.72),
          LatLng(36.76, -121.80),
        ],
        fillColor: Color(0x332196F3),
        strokeColor: Color(0xFF2196F3),
      ),
      // Line of sight to a repeater: clear, blocked, no data.
      MapLine(
        id: 'los-1',
        points: [_self, mid1],
        color: Colors.green,
        width: 4,
      ),
      MapLine(id: 'los-2', points: [mid1, mid2], color: Colors.red, width: 4),
      MapLine(
        id: 'los-3',
        points: [mid2, repeater.position],
        color: Colors.grey,
        width: 4,
        pattern: MapLinePattern.dashed,
      ),
      // The path being built.
      if (_path.isNotEmpty)
        MapLine(
          id: 'path',
          points: [_self, for (final c in _path) c.position],
          color: Colors.blueAccent,
          width: 4,
        ),
      for (final (i, p) in _pins.indexed)
        MapMarker(
          id: 'pin-$i',
          position: p,
          size: const Size(48, 48),
          anchor: const Alignment(-0.55, 0.85), // the flag's pole foot
          child: const Icon(Icons.flag, color: Colors.orange, size: 48),
          label: 'Shared pin ${i + 1}',
          labelMinZoom: _labelMinZoom,
          onTap: () => _toast('Shared pin ${i + 1}'),
        ),
      for (final c in _contacts)
        MapMarker(
          id: 'node-${c.name}',
          position: c.position,
          size: const Size(35, 35),
          child: _NodeDot(color: _nodeColor(c.type), icon: _nodeIcon(c.type)),
          label: c.name,
          labelMinZoom: _labelMinZoom,
          onTap: () => _pathMode ? _addToPath(c) : _showNode(c),
          onLongPress: () => _showNode(c),
        ),
      MapMarker(
        id: 'you',
        position: _self,
        size: const Size(35, 35),
        child: const _NodeDot(
          color: Colors.teal,
          icon: Icons.person_pin_circle,
        ),
        label: 'You',
        onTap: () => _toast('Your radio'),
      ),
      if (_highlight != null)
        MapMarker(
          id: 'highlight',
          position: _highlight!,
          size: const Size(40, 40),
          anchor: Alignment.bottomCenter,
          interactive: false, // taps pass through to the map
          child: const Icon(
            Icons.location_on_outlined,
            color: Colors.red,
            size: 40,
          ),
        ),
    ];
  }

  void _addToPath(_Contact c) {
    _path.add(c);
    _refresh();
  }

  void _showNode(_Contact c) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(c.name),
      content: Text(
        '${c.type.name}\n'
        '${c.position.latitude.toStringAsFixed(5)}, '
        '${c.position.longitude.toStringAsFixed(5)}\n'
        '${_distance(_self, c.position)} from you',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );

  void _onLongPress(LatLng p) => showModalBottomSheet<void>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.flag),
            title: const Text('Share marker here'),
            subtitle: Text(
              '${p.latitude.toStringAsFixed(5)}, '
              '${p.longitude.toStringAsFixed(5)}',
            ),
            onTap: () {
              Navigator.pop(context);
              _pins.add(p);
              _refresh();
            },
          ),
          ListTile(
            leading: const Icon(Icons.my_location),
            title: const Text('Set as my location'),
            onTap: () {
              Navigator.pop(context);
              _self = p;
              _refresh();
            },
          ),
        ],
      ),
    ),
  );

  Future<void> _toggleDark() async {
    final id = await widget.styles.forBrightness(
      _dark ? Brightness.light : Brightness.dark,
      preferred: _dark ? 'outdoor' : 'dark',
    );
    if (mounted) setState(() => _styleId = id);
  }

  void _toast(String msg) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final theme = _dark
        ? ThemeData(colorSchemeSeed: Colors.teal, brightness: Brightness.dark)
        : ThemeData(colorSchemeSeed: Colors.teal);
    return Theme(
      data: theme,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('MeshTrax demo'),
          actions: [
            IconButton(
              tooltip: _pathMode ? 'Stop building path' : 'Build a path',
              icon: Icon(_pathMode ? Icons.radar : Icons.radar_outlined),
              onPressed: () => setState(() {
                _pathMode = !_pathMode;
                if (!_pathMode) _path.clear();
                _overlays = _buildOverlays();
              }),
            ),
            IconButton(
              tooltip: 'Fit nodes',
              icon: const Icon(Icons.fit_screen),
              onPressed: () => _controller.fitPoints(
                _nodePositions,
                padding: const EdgeInsets.all(64),
                maxZoom: 15,
              ),
            ),
            IconButton(
              tooltip: _dark ? 'Light map' : 'Dark map',
              icon: Icon(_dark ? Icons.light_mode : Icons.dark_mode),
              onPressed: _toggleDark,
            ),
          ],
        ),
        body: Stack(
          children: [
            MapChrome(
              state: _styleState,
              map: OfflineMapView(
                styleId: _styleId,
                packs: widget.packs,
                units: widget.units,
                styleRegistry: widget.styles,
                controller: _controller,
                // MeshTrax: CameraFit.bounds(padding 64, maxZoom 16) in
                // flutter_map zoom, i.e. package maxZoom 15.
                initialCamera: _envCamera,
                initialFit: _envCamera != null
                    ? null
                    : MapFit.points(
                        _nodePositions,
                        padding: const EdgeInsets.all(64),
                        maxZoom: 15,
                      ),
                minZoom: 1,
                maxZoom: 17,
                overlays: _overlays,
                onTap: (_) {
                  if (_highlight != null) {
                    _highlight = null;
                    _refresh();
                  }
                },
                onLongPress: _onLongPress,
                onCameraChanged: (c) => setState(() => _zoom = c.zoom),
                onStyleLoaded: (s) => setState(() {
                  _styleState = s;
                  _dark = s.info.isDark;
                }),
                extraLayers: [
                  // Escape hatch: a raw flutter_map layer (range ring).
                  fm.CircleLayer(
                    circles: [
                      fm.CircleMarker(
                        point: _self.toLatLong2(),
                        radius: 8000,
                        useRadiusInMeter: true,
                        color: Colors.teal.withValues(alpha: 0.08),
                        borderColor: Colors.teal,
                        borderStrokeWidth: 1.5,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(left: 8, top: 8, child: _readout()),
            if (_pathMode)
              Positioned(left: 8, right: 8, bottom: 32, child: _pathCard()),
          ],
        ),
      ),
    );
  }

  Widget _readout() => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        'zoom ${_zoom.toStringAsFixed(2)}\n'
        'labels ${_zoom >= _labelMinZoom ? 'on' : 'off'} (from z${_labelMinZoom.toStringAsFixed(0)})\n'
        'style $_styleId',
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    ),
  );

  Widget _pathCard() {
    var meters = 0.0;
    var prev = _self;
    for (final c in _path) {
      meters += _meters(prev, c.position);
      prev = c.position;
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _path.isEmpty
                    ? 'Tap nodes to build a path'
                    : 'You → ${_path.map((c) => c.name).join(' → ')}\n'
                          '${_formatDistance(meters)}',
              ),
            ),
            IconButton(
              tooltip: 'Undo',
              icon: const Icon(Icons.undo),
              onPressed: _path.isEmpty
                  ? null
                  : () {
                      _path.removeLast();
                      _refresh();
                    },
            ),
          ],
        ),
      ),
    );
  }

  String _distance(LatLng a, LatLng b) => _formatDistance(_meters(a, b));

  String _formatDistance(double m) => widget.units == Units.metric
      ? '${(m / 1000).toStringAsFixed(1)} km'
      : '${(m / 1609.344).toStringAsFixed(1)} mi';

  static double _meters(LatLng a, LatLng b) {
    const r = 6371000.0;
    final dLat = (b.latitude - a.latitude) * math.pi / 180;
    final dLon = (b.longitude - a.longitude) * math.pi / 180;
    final h =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(a.latitude * math.pi / 180) *
            math.cos(b.latitude * math.pi / 180) *
            math.pow(math.sin(dLon / 2), 2);
    return 2 * r * math.asin(math.sqrt(h));
  }

  static LatLng _lerp(LatLng a, LatLng b, double t) => LatLng(
    a.latitude + (b.latitude - a.latitude) * t,
    a.longitude + (b.longitude - a.longitude) * t,
  );
}

/// MeshTrax's 35×35 node marker: coloured circle, white border, shadow, icon.
class _NodeDot extends StatelessWidget {
  final Color color;
  final IconData icon;

  const _NodeDot({required this.color, required this.icon});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 2),
      boxShadow: const [
        BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2)),
      ],
    ),
    child: Icon(icon, color: Colors.white, size: 20),
  );
}
