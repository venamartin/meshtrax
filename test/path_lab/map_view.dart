// Directed-topology map for path_lab.
//
// Repeaters appear as the radio hears them: advert positions place a
// node geographically, everything else lands in the "no position" strip
// along the bottom — a hash bucket seen only as a path hop is still a
// real node, it just has no coordinates yet.
//
// Tapping a node draws its links as ARROWS, one per direction. A277 →
// 1312 and 1312 → A277 are separate arrows with separate colours,
// because they are separate measurements: the colour of an arrow is how
// well the node it points AT heard the node it points FROM.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:path_graph/path_graph.dart';

import 'main.dart' show graph;

const _nodeRadius = 6.0;
const _pairOffset = 5.0; // splits A→B from B→A so both stay readable

bool _hasPosition(NodeState n) =>
    n.lat != null && n.lon != null && !(n.lat == 0 && n.lon == 0);

/// dB → colour, via the estimator's own SNR→quality curve so the map
/// and the router agree on what "good" means. Null = never measured.
Color snrColor(double? db) {
  if (db == null) return const Color(0xFF78909C);
  final q = graph.estimator.snrQuality(db);
  return q < 0.5
      ? Color.lerp(const Color(0xFFD32F2F), const Color(0xFFFFB300), q * 2)!
      : Color.lerp(
          const Color(0xFFFFB300), const Color(0xFF43A047), (q - 0.5) * 2)!;
}

double? _edgeSnr(EdgeState e) => e.measuredSnr ?? e.importedSnr;

/// Screen placement for every node: geographic where known, a grid
/// strip where not.
class GraphLayout {
  GraphLayout(Map<String, NodeState> nodes, this.size) {
    final geo = <String, NodeState>{};
    final loose = <String>[];
    nodes.forEach((hash, n) {
      if (_hasPosition(n)) {
        geo[hash] = n;
      } else {
        loose.add(hash);
      }
    });
    loose.sort();
    unplaced.addAll(loose);

    stripTop = loose.isEmpty
        ? size.height
        : (geo.isEmpty ? 4.0 : size.height * 0.62);

    if (geo.isNotEmpty) _projectGeo(geo);

    const cellW = 76.0, cellH = 42.0;
    final cols = max(1, ((size.width - 32) / cellW).floor());
    for (var i = 0; i < loose.length; i++) {
      positions[loose[i]] = Offset(
        32 + (i % cols) * cellW,
        stripTop + 34 + (i ~/ cols) * cellH,
      );
    }
  }

  final Size size;
  final Map<String, Offset> positions = {};
  final Set<String> unplaced = {};
  late final double stripTop;

  /// Equirectangular with a cos(lat) correction, aspect preserved.
  void _projectGeo(Map<String, NodeState> geo) {
    const pad = 44.0;
    final meanLat = geo.values.map((n) => n.lat!).reduce((a, b) => a + b) /
        geo.length;
    final k = cos(meanLat * pi / 180);
    final xs = {for (final e in geo.entries) e.key: e.value.lon! * k};
    final ys = {for (final e in geo.entries) e.key: -e.value.lat!};

    final minX = xs.values.reduce(min), maxX = xs.values.reduce(max);
    final minY = ys.values.reduce(min), maxY = ys.values.reduce(max);
    final spanX = max(maxX - minX, 1e-9), spanY = max(maxY - minY, 1e-9);

    final boxW = size.width - pad * 2, boxH = stripTop - pad * 2;
    // A single node (or a degenerate line) has no scale of its own —
    // centre it rather than inventing one.
    final scale = geo.length < 2 ? 0.0 : min(boxW / spanX, boxH / spanY);
    final cx = pad + boxW / 2, cy = pad + boxH / 2;
    for (final hash in geo.keys) {
      positions[hash] = Offset(
        cx + (xs[hash]! - (minX + maxX) / 2) * scale,
        cy + (ys[hash]! - (minY + maxY) / 2) * scale,
      );
    }
  }

  String? hitTest(Offset p) {
    String? best;
    var bestDistance = 26.0;
    positions.forEach((hash, at) {
      final d = (at - p).distance;
      if (d < bestDistance) {
        bestDistance = d;
        best = hash;
      }
    });
    return best;
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final snap = graph.snapshot();
    final placed = snap.nodes.values.where(_hasPosition).length;
    return Scaffold(
      appBar: AppBar(
        title: Text('Map — ${snap.nodes.length} nodes '
            '($placed placed) · ${snap.edges.length} directed links'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => setState(() => _selected = null),
            icon: const Icon(Icons.clear),
            tooltip: 'clear selection',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = Size(constraints.maxWidth, constraints.maxHeight);
                final layout = GraphLayout(snap.nodes, size);
                return InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 10,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (d) => setState(
                        () => _selected = layout.hitTest(d.localPosition)),
                    child: CustomPaint(
                      key: const ValueKey('topology'),
                      size: size,
                      painter: _TopologyPainter(
                        layout: layout,
                        edges: snap.edges,
                        nodes: snap.nodes,
                        selected: _selected,
                        onSurface: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          SizedBox(height: 190, child: _detail(snap)),
        ],
      ),
    );
  }

  Widget _detail(
      ({Map<String, NodeState> nodes, Map<(String, String), EdgeState> edges})
          snap) {
    final selected = _selected;
    if (selected == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Tap a node to see its directed links.\n'
              'Arrow colour = how well the node it points AT heard the '
              'node it points FROM.\nGrey = never measured, only '
              'overheard in a path.',
              textAlign: TextAlign.center),
        ),
      );
    }
    final node = snap.nodes[selected];
    final out = <(String, EdgeState)>[];
    final into = <(String, EdgeState)>[];
    snap.edges.forEach((key, e) {
      if (key.$1 == selected) out.add((key.$2, e));
      if (key.$2 == selected) into.add((key.$1, e));
    });

    Widget row(String other, EdgeState e, bool outgoing) {
      final snr = _edgeSnr(e);
      final reverse = outgoing
          ? snap.edges[(other, selected)]
          : snap.edges[(selected, other)];
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        child: Row(children: [
          Icon(outgoing ? Icons.arrow_forward : Icons.arrow_back,
              size: 14, color: snrColor(snr)),
          const SizedBox(width: 6),
          SizedBox(
              width: 52,
              child: Text(other,
                  style: const TextStyle(fontFamily: 'monospace'))),
          Expanded(
            child: Text([
              snr == null
                  ? 'snr —'
                  : 'snr ${snr.toStringAsFixed(1)}'
                      '${e.measuredSnr == null ? " (imported)" : ""}',
              'obs ${e.obsCount}',
              if (e.n > 0) '${e.s}/${e.n} delivered',
              if (reverse == null) 'ONE-WAY',
            ].join('  ·  '), style: const TextStyle(fontSize: 12)),
          ),
        ]),
      );
    }

    return ListView(
      children: [
        ListTile(
          dense: true,
          title: Text('$selected${node?.name != null ? " · ${node!.name}" : ""}'),
          subtitle: Text(node == null
              ? 'no metadata'
              : '${node.source.name}'
                  '${_hasPosition(node) ? " · ${node.lat!.toStringAsFixed(4)}, ${node.lon!.toStringAsFixed(4)}" : " · no position"}'),
        ),
        if (out.isNotEmpty)
          const Padding(
              padding: EdgeInsets.fromLTRB(12, 4, 12, 2),
              child: Text('reaches (they heard this node)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
        for (final (other, e) in out) row(other, e, true),
        if (into.isNotEmpty)
          const Padding(
              padding: EdgeInsets.fromLTRB(12, 8, 12, 2),
              child: Text('hears (this node heard them)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
        for (final (other, e) in into) row(other, e, false),
        if (out.isEmpty && into.isEmpty)
          const Padding(
              padding: EdgeInsets.all(12), child: Text('no links yet')),
      ],
    );
  }
}

class _TopologyPainter extends CustomPainter {
  _TopologyPainter({
    required this.layout,
    required this.edges,
    required this.nodes,
    required this.selected,
    required this.onSurface,
  });

  final GraphLayout layout;
  final Map<(String, String), EdgeState> edges;
  final Map<String, NodeState> nodes;
  final String? selected;
  final Color onSurface;

  @override
  void paint(Canvas canvas, Size size) {
    if (layout.unplaced.isNotEmpty && layout.stripTop > 8) {
      canvas.drawLine(
        Offset(0, layout.stripTop),
        Offset(size.width, layout.stripTop),
        Paint()..color = onSurface.withValues(alpha: 0.15),
      );
      _label(canvas, Offset(12, layout.stripTop + 6),
          'no position (${layout.unplaced.length})', 11,
          onSurface.withValues(alpha: 0.5));
    }

    edges.forEach((key, e) {
      final from = layout.positions[key.$1];
      final to = layout.positions[key.$2];
      if (from == null || to == null) return;
      final touched = selected == null || key.$1 == selected || key.$2 == selected;
      if (selected != null && !touched) {
        _arrow(canvas, from, to, onSurface.withValues(alpha: 0.06), 1.0,
            head: false);
        return;
      }
      final colour = snrColor(_edgeSnr(e));
      _arrow(canvas, from, to,
          selected == null ? colour.withValues(alpha: 0.35) : colour,
          selected == null ? 1.2 : 2.4,
          head: selected != null);
    });

    layout.positions.forEach((hash, at) {
      final isSelected = hash == selected;
      final placed = !layout.unplaced.contains(hash);
      canvas.drawCircle(
          at,
          isSelected ? _nodeRadius + 3 : _nodeRadius,
          Paint()
            ..color = isSelected
                ? const Color(0xFF00897B)
                : (placed
                    ? onSurface.withValues(alpha: 0.75)
                    : onSurface.withValues(alpha: 0.35))
            ..style = placed ? PaintingStyle.fill : PaintingStyle.stroke
            ..strokeWidth = 2);
      _label(canvas, at + const Offset(-16, 8), hash, 10,
          onSurface.withValues(alpha: isSelected ? 1 : 0.7));
      final name = nodes[hash]?.name;
      if (name != null && (isSelected || placed)) {
        _label(canvas, at + const Offset(-16, 19), name, 9,
            onSurface.withValues(alpha: 0.45));
      }
    });
  }

  void _arrow(Canvas canvas, Offset from, Offset to, Color colour, double width,
      {required bool head}) {
    final delta = to - from;
    final length = delta.distance;
    if (length < 1) return;
    final unit = delta / length;
    // Offset perpendicular so the two directions of a pair sit
    // side by side instead of on top of each other.
    final perp = Offset(-unit.dy, unit.dx) * _pairOffset;
    final start = from + unit * (_nodeRadius + 2) + perp;
    final end = to - unit * (_nodeRadius + 3) + perp;
    if ((end - start).distance < 2) return;
    final paint = Paint()
      ..color = colour
      ..strokeWidth = width
      ..style = PaintingStyle.stroke;
    canvas.drawLine(start, end, paint);
    if (!head) return;
    final back = end - unit * 9;
    final wing = Offset(-unit.dy, unit.dx) * 4;
    canvas.drawPath(
      Path()
        ..moveTo(end.dx, end.dy)
        ..lineTo(back.dx + wing.dx, back.dy + wing.dy)
        ..lineTo(back.dx - wing.dx, back.dy - wing.dy)
        ..close(),
      Paint()..color = colour,
    );
  }

  void _label(Canvas canvas, Offset at, String text, double size, Color color) {
    TextPainter(
      text: TextSpan(
          text: text, style: TextStyle(fontSize: size, color: color)),
      textDirection: TextDirection.ltr,
    )
      ..layout()
      ..paint(canvas, at);
  }

  @override
  bool shouldRepaint(_TopologyPainter old) => true;
}
