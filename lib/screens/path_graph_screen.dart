import 'dart:convert';

import 'package:file_saver/file_saver.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:path_graph/path_graph.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../helpers/snack_bar_builder.dart';
import '../l10n/l10n.dart';
import '../models/contact.dart';
import '../services/app_settings_service.dart';
import '../services/path_graph/path_graph_service.dart';

/// Developer view of the path graph: what it has learned and what it
/// would answer. Observe only — nothing here changes how a message is
/// sent. Strings are deliberately not localized; this is a lab screen.
class PathGraphScreen extends StatefulWidget {
  const PathGraphScreen({super.key});

  @override
  State<PathGraphScreen> createState() => _PathGraphScreenState();
}

class _PathGraphScreenState extends State<PathGraphScreen> {
  Contact? _target;

  String _hex(List<int> bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join();

  String _fmtPath(List<int> bytes, int width) => [
        for (var i = 0; i + width <= bytes.length; i += width)
          _hex(bytes.sublist(i, i + width))
      ].join(' › ');

  Future<void> _backup(PathGraph graph) async {
    final doc = const JsonEncoder.withIndent(' ').convert(graph.saveSession());
    await FileSaver.instance.saveFile(
      name: 'path-graph-${DateTime.now().toIso8601String().substring(0, 10)}',
      bytes: utf8.encode(doc),
      fileExtension: 'json',
      mimeType: MimeType.json,
    );
    if (mounted) {
      showDismissibleSnackBar(context, content: const Text('Backup saved'));
    }
  }

  Future<void> _restore(PathGraph graph) async {
    final file = await openFile(acceptedTypeGroups: const [
      XTypeGroup(label: 'Path graph backup', extensions: ['json'])
    ]);
    if (file == null) return;
    try {
      final doc = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      await graph.loadSession(doc);
      if (mounted) {
        showDismissibleSnackBar(context,
            content: const Text('Backup restored'));
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        showDismissibleSnackBar(context, content: Text('Restore failed: $e'));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsService>();
    final service = context.watch<PathGraphService>();
    final connector = context.watch<MeshCoreConnector>();
    final graph = service.graph;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.settings_pathGraph),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          SwitchListTile(
            title: Text(context.l10n.settings_pathGraph),
            subtitle: Text(context.l10n.settings_pathGraphSubtitle),
            value: settings.settings.pathGraphEnabled,
            onChanged: (v) => settings.setPathGraphEnabled(v),
          ),
          if (graph == null)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Graph is off. Turn it on and connect a radio.'),
            )
          else ...[
            _counters(graph, connector),
            const Divider(),
            _candidates(
              'Who hears me (egress)',
              graph.egressCandidates(),
            ),
            const Divider(),
            _targetPicker(connector, graph),
            const Divider(),
            Wrap(spacing: 8, children: [
              OutlinedButton.icon(
                onPressed: () => _backup(graph),
                icon: const Icon(Icons.save_alt),
                label: const Text('Backup'),
              ),
              OutlinedButton.icon(
                onPressed: () => _restore(graph),
                icon: const Icon(Icons.file_open),
                label: const Text('Restore'),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  await graph.clearLearnedData();
                  setState(() {});
                },
                icon: const Icon(Icons.delete_outline),
                label: const Text('Clear learned data'),
              ),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _counters(PathGraph graph, MeshCoreConnector connector) {
    final snap = graph.snapshot();
    final c = graph.counters;
    final adapter = context.read<PathGraphService>().adapter;
    final bidi = snap.edges.keys
        .where((k) => snap.edges.containsKey((k.$2, k.$1)))
        .length ~/
        2;
    // A path's hash width is set by the node that built the packet, so
    // other nodes' traffic can be 1-byte no matter what this radio uses.
    final narrow = c.droppedNarrow > 0
        ? '\nDropped ${c.droppedNarrow} paths with hashes narrower than '
            '${graph.hashWidthBytes} bytes — the graph cannot use them '
            '(this radio sends ${connector.pathHashByteWidth}-byte hashes).'
        : '';
    return ListTile(
      title: Text('${snap.nodes.length} repeaters · ${snap.edges.length} '
          'directed links · $bidi two-way'),
      subtitle: Text(
        'Frames seen ${adapter?.framesSeen ?? 0} · observations '
        '${c.observationsApplied} · radio ${graph.selfPubkey == null ? "unknown" : "known"}'
        '$narrow',
        style: TextStyle(
            color: c.droppedNarrow > 0 ? Theme.of(context).colorScheme.error : null),
      ),
    );
  }

  Widget _candidates(String title, List<Candidate> list) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        if (list.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('nothing yet'),
          ),
        for (final c in list.take(8))
          ListTile(
            dense: true,
            leading: Icon(
              c.proven ? Icons.verified : Icons.hearing,
              color: c.proven ? Colors.green : Colors.grey,
            ),
            title: Text(c.repeaterHash,
                style: const TextStyle(fontFamily: 'monospace')),
            subtitle: Text(
              '${c.proven ? "proven" : "heard only"} · weight '
              '${c.weight.toStringAsFixed(1)}'
              '${c.uplinkSnr != null ? " · uplink ${c.uplinkSnr!.toStringAsFixed(1)} dB" : ""}',
            ),
          ),
      ],
    );
  }

  Widget _targetPicker(MeshCoreConnector connector, PathGraph graph) {
    final contacts = connector.contacts.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final target = _target;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: DropdownButton<Contact>(
            isExpanded: true,
            hint: const Text('Pick a contact to ask for a route'),
            value: target,
            items: [
              for (final c in contacts)
                DropdownMenuItem(value: c, child: Text(c.name)),
            ],
            onChanged: (c) => setState(() => _target = c),
          ),
        ),
        if (target != null) ...[
          _candidates(
            'Who reaches ${target.name} (ingress)',
            graph.ingressCandidates(target.publicKeyHex),
          ),
          _answer(graph, target),
        ],
      ],
    );
  }

  Widget _answer(PathGraph graph, Contact target) {
    final result = graph.findPath(target.publicKeyHex);
    final alternatives = graph.findAlternatives(target.publicKeyHex, count: 3);
    final width = graph.hashWidthBytes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: Icon(switch (result) {
            DirectResult() => Icons.arrow_forward,
            RouteResult() => Icons.route,
            FloodResult() => Icons.waves,
          }),
          title: Text(switch (result) {
            DirectResult() => 'Direct (zero hops)',
            RouteResult(:final pathBytes) => _fmtPath(pathBytes, width),
            FloodResult(:final reason) => 'Flood — ${reason.name}',
          }),
          subtitle: switch (result) {
            RouteResult(:final estDelivery, :final hopProbabilities) => Text(
                'est ${(estDelivery * 100).toStringAsFixed(0)}%'
                '${hopProbabilities.isEmpty ? "" : " · hops ${hopProbabilities.map((p) => p.toStringAsFixed(2)).join(" ")}"}'),
            FloodResult(:final reason) => Text(switch (reason) {
                FloodReason.noEvidence => 'nothing known on one side yet',
                FloodReason.noProvenEndpoint =>
                  'doorsteps heard but none proven — one delivered '
                      'message proves them',
                FloodReason.noBidirectionalRoute =>
                  'no corridor proven in both directions',
                FloodReason.belowThreshold => 'links too weak',
                FloodReason.overBudget => 'route too long',
              }),
            _ => null,
          },
        ),
        for (var i = 1; i < alternatives.length; i++)
          ListTile(
            dense: true,
            leading: const Icon(Icons.alt_route, size: 18),
            title: Text(_fmtPath(alternatives[i].pathBytes, width)),
            subtitle: Text(
                'alternative · est ${(alternatives[i].estDelivery * 100).toStringAsFixed(0)}%'),
          ),
      ],
    );
  }
}
