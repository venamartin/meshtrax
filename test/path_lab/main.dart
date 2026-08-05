// path_lab — Phase 1 verification harness for the path_graph module.
// Run: flutter run -d windows -t test/path_lab/main.dart
// Zero lib/ modifications: the connector is used as-is; all parsing
// lives in adapter/frame_adapter.dart.

import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/services/message_retry_service.dart';
import 'package:meshtrax/services/path_history_service.dart';
import 'package:meshtrax/services/storage_service.dart';
import 'package:path_graph/path_graph.dart';

import 'adapter/frame_adapter.dart';

late final MeshCoreConnector connector;
late final PathGraph graph;
late final PathLabAdapter adapter;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = StorageService();
  connector = MeshCoreConnector();
  connector.initialize(
    retryService: MessageRetryService(),
    pathHistoryService: PathHistoryService(storage),
  );

  graph = PathGraph(NativeDatabase(File('path_lab.db')));
  await graph.init();
  adapter = PathLabAdapter(graph);
  connector.receivedFrames.listen(adapter.handleFrame);

  // Push radio identity into the module once device info arrives.
  connector.addListener(() {
    final pk = connector.selfPublicKeyHex;
    if (pk.isNotEmpty) {
      graph.setRadioIdentity(pk, connector.pathHashByteWidth);
    }
  });

  runApp(const PathLabApp());
}

class PathLabApp extends StatelessWidget {
  const PathLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PathLab',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
      home: const PathLabScreen(),
    );
  }
}

class PathLabScreen extends StatefulWidget {
  const PathLabScreen({super.key});

  @override
  State<PathLabScreen> createState() => _PathLabScreenState();
}

class _PathLabScreenState extends State<PathLabScreen> {
  final _importPath =
      TextEditingController(text: 'meshtrax-graph-bayarea.json');
  final _contactPk = TextEditingController();
  String _status = '';
  String _pathResult = '';
  List<String> _usbPorts = const [];

  Future<void> _listPorts() async {
    final ports = await connector.listUsbPorts();
    setState(() {
      _usbPorts = ports;
      _status = ports.isEmpty ? 'no USB ports found' : '';
    });
  }

  Future<void> _import() async {
    try {
      final doc = jsonDecode(await File(_importPath.text).readAsString())
          as Map<String, dynamic>;
      await graph.importGraph(doc);
      setState(() => _status = 'imported ${_importPath.text}');
    } catch (e) {
      setState(() => _status = 'import failed: $e');
    }
  }

  Future<void> _discover() async {
    adapter.pendingDiscover.clear();
    await connector.sendFrame(
        buildRepeaterDiscoveryFrame(DateTime.now().millisecondsSinceEpoch));
    setState(() => _status = 'discover sent, 10 s window…');
    await Future<void>.delayed(const Duration(seconds: 10));
    final n = adapter.pendingDiscover.length;
    adapter.commitDiscover(failureEpisode: false);
    setState(() => _status = 'discover: $n responder(s)');
  }

  void _findPath() {
    final pk = _contactPk.text.trim();
    if (pk.isEmpty) return;
    final result = graph.findPath(pk);
    final alternatives = graph.findAlternatives(pk);
    setState(() {
      _pathResult = switch (result) {
        DirectResult() => 'DIRECT (zero-hop)',
        RouteResult(:final pathBytes, :final estDelivery) =>
          'ROUTE ${_fmtPath(pathBytes)} · est ${(estDelivery * 100).toStringAsFixed(0)}%',
        FloodResult(:final reason) => 'FLOOD (${reason.name})',
      };
      if (alternatives.length > 1) {
        _pathResult +=
            '\nalt: ${alternatives.skip(1).map((r) => _fmtPath(r.pathBytes)).join(' | ')}';
      }
    });
  }

  String _fmtPath(List<int> bytes) => [
        for (var i = 0; i + 1 < bytes.length; i += 2)
          '${bytes[i].toRadixString(16).padLeft(2, '0')}${bytes[i + 1].toRadixString(16).padLeft(2, '0')}'.toUpperCase()
      ].join(',');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PathLab — path_graph harness')),
      body: AnimatedBuilder(
        animation: connector,
        builder: (context, _) {
          final snap = graph.snapshot();
          final counters = graph.counters;
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              // ── connection (USB serial — bench transport) ─────────
              Row(children: [
                FilledButton(
                  onPressed: _listPorts,
                  child: const Text('USB Ports'),
                ),
                const SizedBox(width: 12),
                Text('state: ${connector.state.name}'
                    '${connector.selfPublicKeyHex.length >= 8 ? ' · ${connector.selfPublicKeyHex.substring(0, 8)}…' : ''}'),
              ]),
              for (final port in _usbPorts)
                ListTile(
                  dense: true,
                  title: Text(port),
                  onTap: () async {
                    setState(() => _status = 'connecting $port…');
                    try {
                      await connector.connectUsb(portName: port);
                      setState(() => _status = 'connected $port');
                    } catch (e) {
                      setState(() => _status = 'USB connect failed: $e');
                    }
                  },
                ),
              const Divider(),
              // ── live feed ─────────────────────────────────────────
              Text('frames: ${adapter.framesSeen} · '
                  'observed: ${counters.observationsApplied} · '
                  'dropped 1-byte: ${counters.dropped1Byte} · '
                  'traces skipped: ${adapter.tracesSkipped}'),
              Text('graph: ${snap.nodes.length} nodes · '
                  '${snap.edges.length} edges'),
              Text('egress: ${graph.egressCandidates().take(5).map((c) => '${c.repeaterHash}(${c.weight.toStringAsFixed(1)}${c.tier == EvidenceTier.proven ? '✓' : '?'})').join(' ')}'),
              const Divider(),
              // ── controls ──────────────────────────────────────────
              Row(children: [
                Expanded(
                    child: TextField(
                        controller: _importPath,
                        decoration:
                            const InputDecoration(labelText: 'seed file'))),
                TextButton(onPressed: _import, child: const Text('Import')),
              ]),
              Row(children: [
                FilledButton.tonal(
                    onPressed:
                        connector.state == MeshCoreConnectionState.connected
                            ? _discover
                            : null,
                    child: const Text('Discover')),
                const SizedBox(width: 8),
                Expanded(child: Text(_status)),
              ]),
              Row(children: [
                Expanded(
                    child: TextField(
                        controller: _contactPk,
                        decoration: const InputDecoration(
                            labelText: 'contact pubkey (hex)'))),
                TextButton(onPressed: _findPath, child: const Text('findPath')),
              ]),
              if (_pathResult.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_pathResult,
                      style: const TextStyle(fontFamily: 'monospace')),
                ),
            ],
          );
        },
      ),
    );
  }
}
