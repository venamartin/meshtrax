import 'package:flutter/material.dart';
import 'package:path_graph/path_graph.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../connector/meshcore_protocol.dart';
import '../services/path_graph/frame_adapter.dart';
import '../services/path_graph/path_graph_service.dart';

/// What the graph has seen, for when the main Pathfinder screen is not
/// enough: counters, the last packets heard and every repeater the graph
/// knows. Tapping a repeater pops back with its hash as the result so the
/// main screen can pick it as the target. Lab screen: strings not localized.
class PathGraphDiagnosticsScreen extends StatelessWidget {
  const PathGraphDiagnosticsScreen({super.key});

  static String _timeOf(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}:'
      '${t.second.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final service = context.watch<PathGraphService>();
    final connector = context.watch<MeshCoreConnector>();
    final graph = service.graph;

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Diagnostics'),
            Text('Pathfinder',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal)),
          ],
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        top: false,
        child: graph == null
            ? const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Graph is off. Turn it on and connect a radio.'),
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _counters(context, graph, connector, service.adapter),
                  const SizedBox(height: 24),
                  _sectionTitle('Last packets heard '
                      '(${service.adapter?.packetLog.length ?? 0})'),
                  _subtitle('newest first · what the graph did with each one'),
                  const SizedBox(height: 8),
                  _packetLog(context, service.adapter),
                  const SizedBox(height: 24),
                  ..._knownRepeaters(context, graph),
                ],
              ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold));

  Widget _subtitle(String text) =>
      Text(text, style: TextStyle(fontSize: 14, color: Colors.grey[600]));

  Widget _infoRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 130,
              child: Text(label,
                  style: TextStyle(
                      color: Colors.grey[600], fontWeight: FontWeight.w500)),
            ),
            Expanded(child: Text(value)),
          ],
        ),
      );

  Widget _counters(BuildContext context, PathGraph graph,
      MeshCoreConnector connector, PathLabAdapter? adapter) {
    final c = graph.counters;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(children: [
              Icon(Icons.numbers),
              SizedBox(width: 10),
              Text('Counters',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 8),
            _infoRow('Frames seen', '${adapter?.framesSeen ?? 0}'),
            _infoRow('Observations', '${c.observationsApplied}'),
            _infoRow('Links held until heard again', '${c.linksHeld}'),
            _infoRow('DMs matched', '${adapter?.messagesAttributed ?? 0}'),
            _infoRow('Radio', graph.selfPubkey == null ? 'unknown' : 'known'),
            _infoRow('Mesh',
                graph.mesh?.label ?? 'unknown until a radio connects'),
            // A path's hash width is set by the node that built the packet,
            // so other nodes' traffic can be 1-byte no matter what this
            // radio uses.
            if (c.droppedNarrow > 0)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Dropped ${c.droppedNarrow} paths with hashes narrower than '
                  '${graph.hashWidthBytes} bytes — the graph cannot use them '
                  '(this radio sends ${connector.pathHashByteWidth}-byte hashes).',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Every packet the radio logged and what the graph did with it — the
  /// only way to tell "not recorded" from "recorded but not shown".
  Widget _packetLog(BuildContext context, PathLabAdapter? adapter) {
    final log = adapter?.packetLog ?? const <PacketLogEntry>[];
    return Card(
      child: log.isEmpty
          ? const Padding(padding: EdgeInsets.all(16), child: Text('nothing yet'))
          : Column(
              children: [
                for (final e in log.take(20))
                  ListTile(
                    dense: true,
                    leading: Text(_timeOf(e.at),
                        style: Theme.of(context).textTheme.bodySmall),
                    title: Text(
                        '${e.kind} · ${e.path.isEmpty ? "(no path)" : e.path}',
                        style: const TextStyle(fontFamily: 'monospace')),
                    subtitle:
                        Text('${e.verdict} · ${e.rxSnr.toStringAsFixed(1)} dB'),
                  ),
              ],
            ),
    );
  }

  /// Every repeater vertex, whether or not it ever adverted to us. A
  /// repeater met only as a hop in someone's path is in the graph but in
  /// no contact list and on no map; this is where it shows up.
  List<Widget> _knownRepeaters(BuildContext context, PathGraph graph) {
    final snap = graph.snapshot();
    final outCount = <String, int>{};
    final inCount = <String, int>{};
    for (final k in snap.edges.keys) {
      outCount[k.$1] = (outCount[k.$1] ?? 0) + 1;
      inCount[k.$2] = (inCount[k.$2] ?? 0) + 1;
    }
    final bidi = snap.edges.keys
            .where((k) => snap.edges.containsKey((k.$2, k.$1)))
            .length ~/
        2;
    final nodes = snap.nodes.entries.toList()
      ..sort((a, b) =>
          (b.value.lastHeard ?? 0).compareTo(a.value.lastHeard ?? 0));
    final roomKeys = {
      for (final c in context.read<MeshCoreConnector>().allContacts)
        if (c.type == advTypeRoom) c.publicKeyHex.toLowerCase(),
    };
    const shown = 30;
    return [
      _sectionTitle('Repeaters the graph knows (${nodes.length})'),
      _subtitle('${snap.edges.length} links · $bidi two-way · '
          'tap one to pick it as the target'),
      const SizedBox(height: 8),
      Card(
        child: nodes.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(16), child: Text('nothing yet'))
            : Column(
                children: [
                  for (final n in nodes.take(shown))
                    ListTile(
                      dense: true,
                      // Rooms keep their purple door here too.
                      leading: roomKeys.contains(n.value.pubkey?.toLowerCase())
                          ? const Icon(Icons.meeting_room,
                              color: Colors.purple, size: 18)
                          : Icon(
                              n.value.source == NodeSource.advert
                                  ? Icons.cell_tower
                                  : Icons.alt_route,
                              size: 18),
                      title: Text.rich(TextSpan(children: [
                        TextSpan(
                            text: n.key,
                            style: const TextStyle(fontFamily: 'monospace')),
                        if (n.value.name != null)
                          TextSpan(text: '  ${n.value.name}'),
                      ])),
                      subtitle: Text(
                          'links out ${outCount[n.key] ?? 0} · in ${inCount[n.key] ?? 0}'
                          '${n.value.source == NodeSource.advert ? "" : " · heard only as a hop"}'),
                      onTap: () => Navigator.pop(context, n.key),
                    ),
                  if (nodes.length > shown)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('+${nodes.length - shown} more'),
                    ),
                ],
              ),
      ),
    ];
  }
}
