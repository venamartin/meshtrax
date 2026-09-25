import 'dart:convert';

import 'package:file_saver/file_saver.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:path_graph/path_graph.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../connector/meshcore_protocol.dart';
import '../helpers/path_helper.dart';
import '../helpers/snack_bar_builder.dart';
import '../l10n/l10n.dart';
import '../models/contact.dart';
import '../services/app_settings_service.dart';
import 'path_trace_map.dart';
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
        // Clear the system navigation bar so the action buttons at the
        // bottom stay tappable.
        padding: EdgeInsets.fromLTRB(
            12, 12, 12, 24 + MediaQuery.paddingOf(context).bottom),
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
              graph,
              'Repeaters that hear me',
              'where my messages leave the mesh — the first hop',
              graph.egressCandidates(),
              isSelf: true,
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

  /// One doorstep list, in the router's own order (confidence: tally
  /// blended with the measured link). My own rows are a guess until
  /// confirmed (I may hear a mountaintop that cannot hear me); a
  /// contact's heard-from row is already a route end (a repeater that
  /// hears a handheld reaches it). Plain words only — ingress/egress
  /// stay in the code.
  Widget _candidates(PathGraph graph, String title, String subtitle,
      List<Candidate> list,
      {required bool isSelf, String who = 'them'}) {
    String verdict(Candidate c) {
      if (c.proven) {
        return isSelf
            ? 'confirmed — it answered a trace, discover or delivery'
            : 'confirmed — a message reached $who this way';
      }
      if (!isSelf && c.heard) return 'heard $who — can reach $who';
      return isSelf ? 'I hear it — not yet confirmed it hears me' : 'unconfirmed';
    }

    Color? tint(Candidate c) {
      if (c.proven) return Colors.green;
      if (!isSelf && c.heard) return Colors.amber;
      return Colors.grey;
    }

    String db(double? v) => v == null ? '' : ' ${v.toStringAsFixed(1)} dB';
    final ranked = list.toList()
      ..sort((a, b) => graph
          .doorstepConfidence(b)
          .compareTo(graph.doorstepConfidence(a)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: Text(subtitle,
              style: Theme.of(context).textTheme.bodySmall),
        ),
        if (ranked.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('nothing yet'),
          ),
        for (final c in ranked.take(8))
          ListTile(
            dense: true,
            leading: Icon(
              c.proven ? Icons.verified : Icons.hearing,
              color: tint(c),
            ),
            title: Text(c.repeaterHash,
                style: const TextStyle(fontFamily: 'monospace')),
            subtitle: Text(
              '${verdict(c)} · conf '
              '${graph.doorstepConfidence(c).toStringAsFixed(2)} · weight '
              '${c.weight.toStringAsFixed(1)}'
              '${c.uplinkSnr != null ? " · up${db(c.uplinkSnr)}" : ""}'
              '${c.downlinkSnr != null ? " · down${db(c.downlinkSnr)}" : ""}',
            ),
          ),
      ],
    );
  }

  Widget _targetPicker(MeshCoreConnector connector, PathGraph graph) {
    // Discovered nodes too: a repeater need not be saved to be routed to.
    final contacts = connector.allContacts.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final target = _target;
    // Anything that is not a chat contact is a node in its own right —
    // and so is any hash the graph has already learned as a repeater,
    // whatever the contact record says (field: a repeater filed under
    // another type was asked the contact question and answered
    // "nothing yet" right after a round-trip trace had proven it).
    final knownNode = target != null &&
        graph.snapshot().nodes.containsKey(PathHelper.hopHex(
            PathHelper.pubKeyPrefix(target.publicKey,
                stride: graph.hashWidthBytes)));
    final isNode =
        target != null && (target.type != advTypeChat || knownNode);
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
          if (!isNode)
            _candidates(
              graph,
              'Repeaters that hear ${target.name}',
              'where a message to them arrives — the last hop',
              graph.ingressCandidates(target.publicKeyHex),
              isSelf: false,
              who: target.name,
            ),
          _answer(graph, target,
              isNode: isNode,
              treatedAsNode: isNode && target.type == advTypeChat),
        ],
      ],
    );
  }

  /// What the graph knows about the way back: from a repeater heard
  /// carrying their packets to one this radio heard last.
  Widget _returnAnswer(PathGraph graph, Contact target) {
    final result = graph.findReturnPath(target.publicKeyHex);
    final width = graph.hashWidthBytes;
    return ListTile(
      leading: const Icon(Icons.keyboard_return),
      title: Text(switch (result) {
        RouteResult(:final pathBytes) =>
          'Back from ${target.name}: ${_fmtPath(pathBytes, width)}',
        FloodResult(:final reason) =>
          'Back from ${target.name}: unknown — ${switch (reason) {
            FloodReason.noEvidence =>
              'no message of theirs has arrived here yet',
            FloodReason.noBidirectionalRoute =>
              'a repeater hears them and one hears me, but no two-way corridor joins them',
            _ => reason.name,
          }}',
        DirectResult() => 'Back from ${target.name}: direct',
      }),
      subtitle: switch (result) {
        RouteResult(:final estDelivery) =>
          Text('est ${(estDelivery * 100).toStringAsFixed(0)}% · '
              'what their radio actually uses is its own choice'),
        _ => null,
      },
    );
  }

  Widget _answer(PathGraph graph, Contact target,
      {required bool isNode, bool treatedAsNode = false}) {
    final width = graph.hashWidthBytes;
    // A repeater or room is itself the destination node; a chat contact
    // is reached through its doorsteps.
    final hash = PathHelper.hopHex(
        PathHelper.pubKeyPrefix(target.publicKey, stride: width));
    final result = isNode
        ? graph.findPathToRepeater(hash)
        : graph.findPath(target.publicKeyHex);
    final alternatives = isNode
        ? graph.findAlternativesToRepeater(hash, count: 3)
        : graph.findAlternatives(target.publicKeyHex, count: 3);
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
                  'none of the repeaters that hear me is confirmed yet — '
                      'one delivery, trace or discover confirms it',
                FloodReason.noBidirectionalRoute =>
                  'no two-way corridor joins a repeater that hears me to '
                      'one that hears ${isNode ? "it" : "them"}',
                FloodReason.belowThreshold => 'links too weak',
                FloodReason.overBudget => 'route too long',
              }),
            _ => null,
          },
        ),
        if (treatedAsNode)
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
                'treated as a repeater — the graph knows this hash as a node'),
          ),
        if (!isNode) _returnAnswer(graph, target),
        // A delivered message proves the forward direction only; a
        // round-trip trace along the same route proves the way back.
        if (!isNode && target.pathLength > 0 && target.path.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PathTraceMapScreen(
                    title: '${context.l10n.contacts_pathTrace} ${target.name}',
                    path: target.path,
                    flipPathAround: true,
                    targetContact: target,
                    pathHashByteWidth: target.pathHashSize,
                    pathContacts: context.read<MeshCoreConnector>().allContacts,
                  ),
                ),
              ),
              icon: const Icon(Icons.radar),
              label: Text(
                  'Trace this route (${target.pathLength} hops, ${target.pathHashSize}-byte hashes) — proves the way back'),
            ),
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
