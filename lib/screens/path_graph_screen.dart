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
import '../services/path_graph/frame_adapter.dart';
import '../services/path_graph/path_graph_service.dart';
import '../utils/contact_search.dart';
import '../widgets/mention_composer.dart';
import '../widgets/routing_dialog.dart';
import 'path_graph_diagnostics_screen.dart';
import 'path_trace_map.dart';

/// Pathfinder: the repeaters around this radio, and how it would reach
/// whoever is picked. Laid out like the room server screen. While the
/// switch is on, the routes shown here are the ones DMs, logins and
/// repeater commands try first; the screen itself only reads the graph
/// (Discover and the backup tools aside). Strings are deliberately not
/// localized; this is a lab screen.
class PathGraphScreen extends StatefulWidget {
  const PathGraphScreen({super.key, this.initialTargetKey});

  /// Open with this contact (pubkey hex) already picked — the routing
  /// dialog's "What Pathfinder knows" link.
  final String? initialTargetKey;

  @override
  State<PathGraphScreen> createState() => _PathGraphScreenState();
}

/// Read-only view of the graph, taken once per build.
typedef GraphSnapshot = ({
  Map<String, NodeState> nodes,
  Map<(String, String), EdgeState> edges
});

/// What the search box resolved to: a contact, or a bare repeater hash
/// the graph met only as a hop. [isNode] says the search routes TO it
/// (a repeater) rather than through its doorsteps (a person or room).
typedef _Target = ({
  Contact? contact,
  String? hash,
  bool isNode,
  bool treatedAsNode,
});

class _PathGraphScreenState extends State<PathGraphScreen> {
  /// A contact's pubkey hex, or a bare repeater hash the graph knows.
  /// Resolved on every build so a refreshed contact list or a cleared
  /// graph never leaves the picker pointing at a vanished object.
  String? _targetKey;
  String _query = '';
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _targetKey = widget.initialTargetKey;
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String _fmtPath(List<int> bytes, int width) => PathHelper.getHops(bytes,
          stride: width)
      .map(PathHelper.hopHex)
      .join(' › ');

  static String _pct(double p) => '${(p * 100).toStringAsFixed(0)}%';

  static String _db(double? v) => v == null ? '—' : v.toStringAsFixed(1);

  static String _timeOf(int millis) {
    if (millis == 0) return '—';
    final t = DateTime.fromMillisecondsSinceEpoch(millis);
    return '${t.month}/${t.day} '
        '${t.hour.toString().padLeft(2, '0')}:'
        '${t.minute.toString().padLeft(2, '0')}:'
        '${t.second.toString().padLeft(2, '0')}';
  }

  String _hashOf(PathGraph graph, Contact c) => PathHelper.hopHex(
      PathHelper.pubKeyPrefix(c.publicKey, stride: graph.hashWidthBytes));

  Future<void> _backup(PathGraph graph) async {
    final doc = const JsonEncoder.withIndent(' ').convert(graph.saveSession());
    // The system save dialog, like the log export: the silent save lands
    // in the app's private folder where nobody can find it.
    final saved = await FileSaver.instance.saveAs(
      name: 'path-graph-${DateTime.now().toIso8601String().substring(0, 10)}',
      bytes: utf8.encode(doc),
      fileExtension: 'json',
      mimeType: MimeType.json,
    );
    if (mounted && saved != null && saved.isNotEmpty) {
      showDismissibleSnackBar(context, content: Text('Backup saved to $saved'));
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

  /// The remote probe: a flooded request the contact answers with a
  /// flooded reply, so one exchange teaches both routes — including their
  /// doorstep, which listening only learns when they happen to flood.
  Future<void> _discover(Contact target) async {
    final adapter = context.read<PathGraphService>().adapter;
    final connector = context.read<MeshCoreConnector>();
    if (adapter == null) return;
    final key = target.publicKeyHex.toLowerCase();
    // The radio drops a pending request's answer when another request or
    // send starts, and a send's SENT could be read as this one's.
    if (!connector.isConnected || connector.hasSendsInFlight) {
      setState(() => adapter.discoveryStatus[key] =
          'busy — wait for messages in flight to finish, then ask again');
      return;
    }
    try {
      await connector.sendFrame(buildPathDiscoveryReq(target.publicKey));
      adapter.beginDiscovery(key, 'asking ${target.name} for both routes…');
    } catch (e) {
      adapter.cancelDiscovery();
      adapter.discoveryStatus[key] = 'could not send: $e';
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsService>();
    final service = context.watch<PathGraphService>();
    final connector = context.watch<MeshCoreConnector>();
    final graph = service.graph;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.l10n.settings_pathGraph),
            const Text('Routes learned from what the radio hears',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal)),
          ],
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SwitchListTile(
              title: Text(context.l10n.settings_pathGraph),
              subtitle: Text(context.l10n.settings_pathGraphSubtitle),
              value: settings.settings.pathGraphEnabled,
              onChanged: (v) => settings.setPathGraphEnabled(v),
            ),
            const SizedBox(height: 16),
            if (graph == null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(service.lastError == null
                      ? 'Graph is off. Turn it on and connect a radio.'
                      : 'Pathfinder could not open its database, so it is '
                          'off. Messages still send the normal way. '
                          'Details: ${service.lastError}'),
                ),
              )
            else
              ..._body(context, graph, service, connector),
          ],
        ),
      ),
    );
  }

  List<Widget> _body(BuildContext context, PathGraph graph,
      PathGraphService service, MeshCoreConnector connector) {
    final snap = graph.snapshot();
    final contacts = connector.allContacts.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final contactByHash = <String, Contact>{
      for (final c in contacts.reversed) _hashOf(graph, c): c,
    };
    final target = _resolveTarget(contacts, graph, snap);
    final contact = target.contact;
    final throughDoorsteps = contact != null && !target.isNode;
    final mine = _ranked(graph, graph.egressCandidates());

    return [
      _headerCard(context, connector, snap, service, mine),
      const SizedBox(height: 24),
      _sectionTitle('Direct repeaters (${mine.length})',
          subtitle: _tableSummary(mine)),
      const SizedBox(height: 8),
      _doorstepTable(graph, snap, contactByHash, mine, isSelf: true),
      const SizedBox(height: 24),
      _sectionTitle('Find a route'),
      const SizedBox(height: 8),
      TextField(
        controller: _search,
        decoration: InputDecoration(
          hintText: 'Contact, room or repeater — name or hash',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          isDense: true,
        ),
        onChanged: (v) => setState(() => _query = v),
      ),
      if (_query.trim().isNotEmpty)
        _picker(context, graph, snap, contacts, contactByHash)
      else if (target.hash == null)
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 12, 0, 0),
          child: Text('Pick someone to see how Pathfinder would reach them.',
              style: TextStyle(color: Colors.grey[600])),
        ),
      if (target.hash != null) ...[
        const SizedBox(height: 16),
        _targetHeader(target),
        if (throughDoorsteps) ...[
          const SizedBox(height: 16),
          ...() {
            final theirs =
                _ranked(graph, graph.ingressCandidates(contact.publicKeyHex));
            return [
              _sectionTitle('Repeaters that hear ${contact.name} (${theirs.length})',
                  subtitle: _tableSummary(theirs)),
              const SizedBox(height: 8),
              _doorstepTable(graph, snap, contactByHash, theirs,
                  isSelf: false, who: contact.name),
            ];
          }(),
        ],
        const SizedBox(height: 24),
        _sectionTitle('Routes to ${contact?.name ?? target.hash}'),
        const SizedBox(height: 8),
        _routeList(graph, _forwardRoutes(graph, target), back: false),
        if (throughDoorsteps) ...[
          const SizedBox(height: 8),
          _probeButtons(contact, service.adapter),
          const SizedBox(height: 24),
          _sectionTitle('Routes back from ${contact.name}'),
          const SizedBox(height: 8),
          _routeList(graph, _backRoutes(graph, contact), back: true),
        ] else ...[
          const SizedBox(height: 24),
          _sectionTitle('Routes back from ${contact?.name ?? target.hash}'),
          const SizedBox(height: 8),
          _routeList(graph, _backRoutesFromRepeater(graph, target.hash!),
              back: true, fromRepeater: true),
        ],
      ],
      const SizedBox(height: 24),
      const Text('More',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),
      _navCard(
        icon: Icons.monitor_heart,
        title: 'Diagnostics',
        subtitle: 'Packets heard, counters and every repeater the graph knows',
        color: Colors.teal,
        onTap: () async {
          final hash = await Navigator.push<String>(
            context,
            MaterialPageRoute(
                builder: (_) => const PathGraphDiagnosticsScreen()),
          );
          if (hash != null && mounted) setState(() => _targetKey = hash);
        },
      ),
      const SizedBox(height: 12),
      _navCard(
        icon: Icons.save_alt,
        title: 'Backup & restore',
        subtitle: 'Save, restore or clear what Pathfinder learned',
        color: Colors.indigo,
        onTap: () => _showBackupSheet(graph),
      ),
    ];
  }

  _Target _resolveTarget(
      List<Contact> contacts, PathGraph graph, GraphSnapshot snap) {
    final key = _targetKey;
    final contact = key == null
        ? null
        : contacts.cast<Contact?>().firstWhere(
            (c) => c!.publicKeyHex == key,
            orElse: () => null);
    final bareHash =
        contact == null && key != null && snap.nodes.containsKey(key)
            ? key
            : null;
    // Only a repeater forwards packets, so only a repeater is a node the
    // search can route TO. A room or sensor is reached through its
    // doorsteps like a chat contact (it never appears as a hop). A chat
    // contact the graph has already met as a hop is a repeater filed
    // under the wrong type (field: it answered "nothing yet" right after
    // a round-trip trace had proven it).
    final hash = contact != null ? _hashOf(graph, contact) : bareHash;
    final knownNode = contact != null && snap.nodes.containsKey(hash);
    final isNode = contact == null ||
        contact.type == advTypeRepeater ||
        (contact.type == advTypeChat && knownNode);
    return (
      contact: contact,
      hash: hash,
      isNode: isNode,
      treatedAsNode: contact != null && isNode && contact.type == advTypeChat,
    );
  }

  // ---------------------------------------------------------------- header

  Widget _headerCard(BuildContext context, MeshCoreConnector connector,
      GraphSnapshot snap,
      PathGraphService service, List<Candidate> mine) {
    final hearMe = mine.where((c) => c.proven).length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: RoutingIcon.pathfinderColor(context),
              child: const Icon(RoutingIcon.icon, size: 40, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(connector.selfName ?? 'Pathfinder',
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
                '$hearMe repeaters hear me · ${snap.nodes.length} repeaters known',
                style: TextStyle(fontSize: 14, color: Colors.grey[600])),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(RoutingIcon.icon,
                    size: 16, color: RoutingIcon.pathfinderColor(context)),
                const SizedBox(width: 4),
                Text(
                    'Pathfinder sends: ${service.graphDelivered} delivered · '
                    '${service.graphFailed} failed',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600])),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, {String? subtitle}) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          if (subtitle != null)
            Text(subtitle,
                style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        ],
      );

  /// The hub screen's navigation card (second copy in the app).
  Widget _navCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style:
                            TextStyle(fontSize: 14, color: Colors.grey[600])),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- tables

  /// Doorstep rows in the router's own order (confidence: tally blended
  /// with the measured link). DIRECT is a zero-hop link, not a repeater.
  List<Candidate> _ranked(PathGraph graph, List<Candidate> list) =>
      list.where((c) => c.repeaterHash != directHash).toList()
        ..sort((a, b) => graph
            .doorstepConfidence(b)
            .compareTo(graph.doorstepConfidence(a)));

  String? _tableSummary(List<Candidate> ranked) {
    if (ranked.isEmpty) return null;
    final twoWay = ranked.where((c) => c.proven && c.heard).length;
    return '$twoWay two-way · best ${ranked.first.repeaterHash}';
  }

  /// One table of doorsteps: who, the link both ways, and the score the
  /// router prices it at. My own rows are a guess until confirmed (I may
  /// hear a mountaintop that cannot hear me); a contact's heard-from row
  /// is already a route end (a repeater that hears a handheld reaches it).
  Widget _doorstepTable(PathGraph graph, GraphSnapshot snap,
      Map<String, Contact> contactByHash, List<Candidate> ranked,
      {required bool isSelf, String who = 'them'}) {
    final small = Theme.of(context)
        .textTheme
        .bodySmall
        ?.copyWith(color: Colors.grey[600], fontWeight: FontWeight.w500);
    Widget cell(String text, {double width = 64, TextAlign align = TextAlign.center,
            TextStyle? style}) =>
        SizedBox(width: width, child: Text(text, textAlign: align, style: style));

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Column(
          children: [
            Row(children: [
              const SizedBox(width: 28),
              Expanded(child: Text('Repeater', style: small)),
              cell('↑ Up', style: small),
              cell('↓ Down', style: small),
              cell('Score', width: 56, align: TextAlign.right, style: small),
            ]),
            const Divider(),
            if (ranked.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('nothing yet'),
              ),
            for (final c in ranked)
              InkWell(
                onTap: () => _showDoorstepSheet(graph, snap, contactByHash, c,
                    isSelf: isSelf, who: who),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(children: [
                    SizedBox(
                      width: 28,
                      child: Icon(
                        c.proven ? Icons.verified : Icons.hearing,
                        size: 18,
                        color: c.proven ? Colors.green : Colors.grey,
                      ),
                    ),
                    Expanded(
                      child: Text(c.repeaterHash,
                          style: const TextStyle(fontFamily: 'monospace')),
                    ),
                    cell(_db(c.uplinkSnr)),
                    cell(_db(c.downlinkSnr)),
                    cell(_pct(graph.doorstepConfidence(c)),
                        width: 56, align: TextAlign.right),
                  ]),
                ),
              ),
            const Divider(),
            Row(children: [
              const Icon(Icons.verified, size: 14, color: Colors.green),
              Text(isSelf ? ' they hear me · ' : ' reaches $who · ',
                  style: small),
              const Icon(Icons.hearing, size: 14, color: Colors.grey),
              Text(isSelf ? ' heard only · SNR in dB' : ' hears $who · SNR in dB',
                  style: small),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 150,
              child: Text(label,
                  style: TextStyle(
                      color: Colors.grey[600], fontWeight: FontWeight.w500)),
            ),
            Expanded(child: Text(value)),
          ],
        ),
      );

  void _showDoorstepSheet(PathGraph graph, GraphSnapshot snap,
      Map<String, Contact> contactByHash, Candidate c,
      {required bool isSelf, required String who}) {
    final hash = c.repeaterHash;
    final node = snap.nodes[hash];
    final known = contactByHash[hash];
    final name = node?.name ?? known?.name ?? hash;
    final pubkey = node?.pubkey ?? known?.publicKeyHex;
    final tier = switch (c.tier) {
      EvidenceTier.inferred => 'heard only',
      EvidenceTier.proven => 'confirmed',
      EvidenceTier.direct => 'direct',
    };
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
            16, 0, 16, 16 + MediaQuery.paddingOf(context).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(hash,
                style: TextStyle(
                    fontFamily: 'monospace', color: Colors.grey[600])),
            const Divider(),
            _infoRow('Public key',
                pubkey == null ? '—' : '${pubkey.substring(0, 12).toUpperCase()}…'),
            _infoRow('Confidence', _pct(graph.doorstepConfidence(c))),
            _infoRow('Weight', c.weight.toStringAsFixed(2)),
            _infoRow(isSelf ? 'Times I heard it' : 'Times it carried their packets',
                '${c.finalCount}'),
            _infoRow(isSelf ? 'Times it heard me' : 'Times it reached $who',
                '${c.provenCount}'),
            _infoRow('Uplink SNR', '${_db(c.uplinkSnr)} dB'),
            _infoRow('Downlink SNR', '${_db(c.downlinkSnr)} dB'),
            _infoRow('Last seen', _timeOf(c.lastSeen)),
            _infoRow('Last proof', c.provenAt == null ? 'never' : _timeOf(c.provenAt!)),
            _infoRow('Evidence', tier),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- picker

  /// The same icon and colour the contact list uses for a type.
  Widget _typeIcon(int type) {
    final (icon, color) = switch (type) {
      advTypeChat => (Icons.person, Colors.blue),
      advTypeRepeater => (Icons.cell_tower, Colors.orange),
      advTypeRoom => (Icons.meeting_room, Colors.purple),
      advTypeSensor => (Icons.sensors, Colors.green),
      _ => (Icons.device_unknown, Colors.grey),
    };
    return Icon(icon, color: color, size: 20);
  }

  void _pick(String key) {
    setState(() {
      _targetKey = key;
      _query = '';
      _search.clear();
    });
    FocusScope.of(context).unfocus();
  }

  Widget _picker(BuildContext context, PathGraph graph, GraphSnapshot snap,
      List<Contact> contacts, Map<String, Contact> contactByHash) {
    final query = _query.trim();
    final matches = contacts.where((c) => matchesContactQuery(c, query)).toList();
    // Repeaters the graph met only as hops: no contact record at all.
    final hashMatches = snap.nodes.keys
        .where((h) =>
            !contactByHash.containsKey(h) && h.startsWith(query.toUpperCase()))
        .toList()
      ..sort();
    const shown = 12;
    final total = matches.length + hashMatches.length;
    final rows = <Widget>[
      for (final c in matches.take(shown))
        ListTile(
          leading: mentionAvatar(c, Theme.of(context).colorScheme),
          title: Text(c.name,
              style: const TextStyle(fontWeight: FontWeight.w500)),
          subtitle: Text(_hashOf(graph, c),
              style: const TextStyle(fontFamily: 'monospace')),
          onTap: () => _pick(c.publicKeyHex),
        ),
      for (final h in hashMatches.take(shown - matches.length.clamp(0, shown)))
        ListTile(
          leading: const CircleAvatar(
              radius: 16, child: Icon(Icons.alt_route, size: 16)),
          title: Text(h, style: const TextStyle(fontFamily: 'monospace')),
          subtitle: Text(snap.nodes[h]?.name ?? 'heard as a hop'),
          onTap: () => _pick(h),
        ),
      if (total == 0)
        const ListTile(title: Text('no match'))
      else if (total > shown)
        ListTile(
            title: Text('+${total - shown} more — keep typing',
                style: TextStyle(color: Colors.grey[600]))),
    ];
    return MentionsPanel(
        itemCount: rows.length, itemBuilder: (_, i) => rows[i]);
  }

  Widget _targetHeader(_Target t) {
    final contact = t.contact;
    final notes = [
      if (t.treatedAsNode)
        'treated as a repeater — the graph knows this hash as a hop',
      if (contact == null)
        'known only as a hop in other people\'s paths — no contact record, '
            'so nothing to trace against; use Route & trace on the map once '
            'it has adverted',
    ];
    return Card(
      child: ListTile(
        leading: contact != null
            ? _typeIcon(contact.type)
            : const Icon(Icons.alt_route, size: 20),
        title: Text(contact?.name ?? t.hash!,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text([t.hash!, ...notes].join('\n'),
            style: const TextStyle(fontFamily: 'monospace')),
        trailing: IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => setState(() => _targetKey = null),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- routes

  List<PathResult> _forwardRoutes(PathGraph graph, _Target t) {
    final contact = t.contact;
    if (t.isNode || contact == null) {
      return [
        graph.findPathToRepeater(t.hash!),
        ...graph.findAlternativesToRepeater(t.hash!, count: 3),
      ];
    }
    return [
      graph.findPath(contact.publicKeyHex),
      ...graph.findAlternatives(contact.publicKeyHex, count: 3),
    ];
  }

  List<PathResult> _backRoutes(PathGraph graph, Contact contact) => [
        graph.findReturnPath(contact.publicKeyHex),
        ...graph.findReturnAlternatives(contact.publicKeyHex, count: 3),
      ];

  List<PathResult> _backRoutesFromRepeater(PathGraph graph, String hash) => [
        graph.findReturnPathFromRepeater(hash),
        ...graph.findReturnAlternativesFromRepeater(hash, count: 3),
      ];

  /// Up to three distinct routes; a direct or flood answer appears once.
  Widget _routeList(PathGraph graph, List<PathResult> results,
      {required bool back, bool fromRepeater = false}) {
    final width = graph.hashWidthBytes;
    final seen = <String>{};
    final rows = <Widget>[];
    for (final r in results) {
      if (rows.length == 3) break;
      switch (r) {
        case RouteResult(:final pathBytes, :final estDelivery):
          if (!seen.add(PathHelper.hopHex(pathBytes))) continue;
          rows.add(ListTile(
            dense: true,
            leading: const Icon(Icons.alt_route, size: 18),
            title: Text(_fmtPath(pathBytes, width),
                style: const TextStyle(fontFamily: 'monospace')),
            trailing: Text('${_pct(estDelivery)} likely'),
          ));
        case DirectResult():
          if (!seen.add('direct')) continue;
          rows.add(const ListTile(
            dense: true,
            leading: Icon(Icons.arrow_forward, size: 18),
            title: Text('Direct — no repeater needed'),
          ));
        case FloodResult(:final reason):
          if (!seen.add('flood')) continue;
          rows.add(ListTile(
            dense: true,
            leading: const Icon(Icons.waves, size: 18),
            title: Text('Flood — ${_floodReason(reason, back: back, fromRepeater: fromRepeater)}'),
          ));
      }
    }
    return Card(
      child: rows.isEmpty
          ? const Padding(padding: EdgeInsets.all(16), child: Text('nothing yet'))
          : Column(children: rows),
    );
  }

  String _floodReason(FloodReason reason,
      {required bool back, bool fromRepeater = false}) {
    if (back && fromRepeater) {
      return switch (reason) {
        FloodReason.noEvidence => 'no repeater this radio hears is known yet',
        FloodReason.noCorridor =>
          'no corridor joins it to a repeater this radio hears',
        _ => reason.name,
      };
    }
    if (back) {
      return switch (reason) {
        FloodReason.noEvidence =>
          'nothing flooded by them has been heard yet — direct replies carry no path',
        FloodReason.noCorridor =>
          'a repeater hears them and one hears me, but no corridor joins them',
        _ => reason.name,
      };
    }
    return switch (reason) {
      FloodReason.noEvidence => 'nothing known on one side yet',
      FloodReason.noProvenEndpoint =>
        'no repeater that hears me is confirmed yet — a delivery, trace or '
            'Discover confirms one',
      FloodReason.noCorridor =>
        'no corridor joins a repeater that hears me to one that hears them',
      FloodReason.belowThreshold => 'links too weak',
      FloodReason.overBudget => 'route too long',
    };
  }

  Widget _probeButtons(Contact contact, PathLabAdapter? adapter) {
    // A delivered message proves the forward direction only; a round-trip
    // trace along the same route proves the way back.
    final hasFirmwareRoute =
        contact.pathLength > 0 && contact.path.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(spacing: 8, children: [
          OutlinedButton.icon(
            onPressed: adapter?.pendingDiscoveryPubkey == null
                ? () => _discover(contact)
                : null,
            icon: const Icon(Icons.travel_explore),
            label: const Text('Discover'),
          ),
          if (hasFirmwareRoute)
            OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PathTraceMapScreen(
                    title: '${context.l10n.contacts_pathTrace} ${contact.name}',
                    path: contact.path,
                    flipPathAround: true,
                    targetContact: contact,
                    pathHashByteWidth: contact.pathHashSize,
                    pathContacts: context.read<MeshCoreConnector>().allContacts,
                  ),
                ),
              ),
              icon: const Icon(Icons.radar),
              label: Text('Trace (${contact.pathLength} hops)'),
            ),
        ]),
        if (adapter?.discoveryStatus[contact.publicKeyHex.toLowerCase()]
            case final status?)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(status, style: Theme.of(context).textTheme.bodySmall),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------- tools

  void _showBackupSheet(PathGraph graph) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.save_alt),
              title: const Text('Backup'),
              subtitle: const Text('Save what Pathfinder learned to a file'),
              onTap: () {
                Navigator.pop(sheet);
                _backup(graph);
              },
            ),
            ListTile(
              leading: const Icon(Icons.file_open),
              title: const Text('Restore'),
              subtitle: const Text('Replace it with a saved file'),
              onTap: () {
                Navigator.pop(sheet);
                _restore(graph);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Clear learned data'),
              subtitle: const Text('Start again from nothing'),
              onTap: () async {
                Navigator.pop(sheet);
                await graph.clearLearnedData();
                if (mounted) setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }
}
