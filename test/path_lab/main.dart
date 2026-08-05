// path_lab — Phase 1 verification harness for the path_graph module.
// Run: flutter run -d windows -t test/path_lab/main.dart
// Zero lib/ modifications: the connector is used as-is; all parsing
// lives in adapter/frame_adapter.dart.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/helpers/path_helper.dart';
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
  String _traceResult = '';
  List<String> _usbPorts = const [];
  Uint8List? _lastPath;
  List<RouteResult> _routes = const [];
  int _selectedRoute = 0;
  double _beta = 0.95;

  @override
  void initState() {
    super.initState();
    adapter.onTrace = () {
      final t = adapter.lastTrace;
      if (t == null || !mounted) return;
      setState(() {
        _traceResult = [
          for (var i = 0; i < t.hops.length; i++)
            '${t.hops[i]}${i < t.snrs.length ? ' ${t.snrs[i].toStringAsFixed(1)}dB' : ''}'
        ].join('  →  ');
        _status = 'trace: ${t.hops.length} hop(s) measured';
      });
    };
  }

  /// Round-trip so the trace measures BOTH directions of every link.
  Future<void> _trace() async {
    final path = _lastPath;
    if (path == null || path.isEmpty) {
      setState(() => _status = 'find a path first');
      return;
    }
    final stride = connector.pathHashByteWidth;
    final roundTrip = PathHelper.roundTripPath(path, stride: stride);
    setState(() {
      _traceResult = '';
      _status = 'tracing ${_fmtPath(roundTrip)}…';
    });
    await connector.sendFrame(buildTraceReq(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      0,
      encodeTraceFlags(stride),
      payload: roundTrip,
    ));
  }

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
    // Use the connector's own discovery: random uint32 tag + the 30 s
    // window the firmware's anti-collision delay actually needs.
    await connector.sendRepeaterDiscovery();
    setState(() => _status = 'discover sent, 30 s window…');
    for (var i = 0; i < 30; i++) {
      await Future<void>.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      setState(() => _status =
          'discover: ${adapter.pendingDiscover.length} so far (${29 - i}s)');
    }
    final n = adapter.pendingDiscover.length;
    adapter.commitDiscover(failureEpisode: false);
    setState(() => _status = n == 0
        ? 'discover: no responders (rate-limited? out of range?)'
        : 'discover: $n responder(s) committed as proven egress');
  }

  void _findPath() {
    final pk = _contactPk.text.trim();
    if (pk.isEmpty) return;
    // 4 hex chars = repeater 2-byte hash; otherwise a contact pubkey.
    final isRepeater = pk.length == 4;
    final result =
        isRepeater ? graph.findPathToRepeater(pk) : graph.findPath(pk);
    final alternatives = isRepeater
        ? graph.findAlternativesToRepeater(pk, count: 4)
        : graph.findAlternatives(pk, count: 4);
    setState(() {
      _routes = alternatives.isNotEmpty
          ? alternatives
          : (result is RouteResult ? [result] : const []);
      _selectedRoute = 0;
      _lastPath = _routes.isNotEmpty ? _routes.first.pathBytes : null;
      _traceResult = '';
      _pathResult = switch (result) {
        DirectResult() => 'DIRECT (zero-hop)',
        RouteResult() => '${_routes.length} route(s) — pick one to trace',
        FloodResult(:final reason) => 'FLOOD (${reason.name})\n${_why(pk, isRepeater)}',
      };
    });
  }

  /// Turns a flood verdict into an actionable diagnosis.
  String _why(String target, bool isRepeater) {
    final self = graph.selfPubkey;
    if (self == null || self.isEmpty) {
      return '· no radio identity yet — connect first';
    }
    final egress = graph.egressCandidates();
    final ingress =
        isRepeater ? const <Candidate>[] : graph.ingressCandidates(target);
    final lines = <String>[];
    if (egress.isEmpty) {
      lines.add('· egress EMPTY — nobody known to hear me. '
          'Run Discover, or wait for multi-hop traffic.');
    } else {
      lines.add('· egress ${egress.length}: '
          '${egress.take(3).map((c) => c.repeaterHash).join(",")}');
    }
    if (!isRepeater) {
      if (ingress.isEmpty) {
        lines.add('· ingress EMPTY for this contact — no attributed '
            'traffic from them yet (adverts/DMs attribute; channel '
            'chatter is anonymous).');
      } else {
        lines.add('· ingress ${ingress.length}: '
            '${ingress.take(3).map((c) => c.repeaterHash).join(",")}');
      }
    }
    final snap = graph.snapshot();
    final bidi = snap.edges.keys
        .where((k) => snap.edges.containsKey((k.$2, k.$1)))
        .length;
    lines.add('· graph ${snap.nodes.length}n/${snap.edges.length}e '
        '($bidi directed edges have a reverse twin)');
    return lines.join('\n');
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
              // Targets that actually have ingress evidence — tap to load.
              Builder(builder: (context) {
                final targets = graph.contactsWithIngress();
                if (targets.isEmpty) {
                  return const Text(
                      'no contact has ingress yet — adverts/DMs attribute; '
                      'try a repeater hash (4 hex) instead',
                      style: TextStyle(fontSize: 11, color: Colors.orange));
                }
                return Wrap(
                  spacing: 6,
                  children: [
                    for (final t in targets.take(8))
                      ActionChip(
                        label: Text(t.length > 8 ? '${t.substring(0, 8)}…' : t,
                            style: const TextStyle(fontSize: 11)),
                        onPressed: () {
                          _contactPk.text = t;
                          _findPath();
                        },
                      ),
                  ],
                );
              }),
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
                            labelText:
                                'contact pubkey (64 hex) or repeater hash (4 hex)'))),
                TextButton(onPressed: _findPath, child: const Text('findPath')),
              ]),
              if (_pathResult.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_pathResult,
                      style: const TextStyle(fontFamily: 'monospace')),
                ),
              // ── alternatives: pick which route to use/trace ───────
              for (var i = 0; i < _routes.length; i++)
                ListTile(
                  dense: true,
                  selected: i == _selectedRoute,
                  leading: Icon(i == _selectedRoute
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked),
                  onTap: () => setState(() {
                    _selectedRoute = i;
                    _lastPath = _routes[i].pathBytes;
                    _traceResult = '';
                  }),
                  title: Text('#${i + 1}  ${_fmtPath(_routes[i].pathBytes)}',
                      style: const TextStyle(fontFamily: 'monospace')),
                  subtitle: Text(
                      '${_routes[i].pathBytes.length ~/ 2} hop(s) · est '
                      '${(_routes[i].estDelivery * 100).toStringAsFixed(0)}%'),
                ),
              if (_routes.length == 1)
                Builder(builder: (context) {
                  final snap = graph.snapshot();
                  final bidi = snap.edges.keys
                      .where((k) => snap.edges.containsKey((k.$2, k.$1)))
                      .length;
                  return Text(
                      'only one bidirectional corridor known '
                      '($bidi of ${snap.edges.length} edges have a reverse '
                      'twin) — trace more, or wait for two-way traffic',
                      style: const TextStyle(
                          fontSize: 11, color: Colors.orange));
                }),
              // ── hop tax β ─────────────────────────────────────────
              Row(children: [
                Text('hop tax β: ${_beta.toStringAsFixed(2)}'),
                Expanded(
                  child: Slider(
                    value: _beta,
                    min: 0.5,
                    max: 1.0,
                    divisions: 50,
                    label: _beta.toStringAsFixed(2),
                    onChanged: (v) => setState(() {
                      _beta = v;
                      graph.updateConfig(graph.config.copyWith(beta: v));
                    }),
                    onChangeEnd: (_) => _findPath(),
                  ),
                ),
              ]),
              const Text(
                  'β→1: hops free, route by signal · β→0.5: min-hop',
                  style: TextStyle(fontSize: 11, color: Colors.grey)),
              Row(children: [
                FilledButton.tonal(
                  onPressed: _lastPath != null &&
                          connector.state == MeshCoreConnectionState.connected
                      ? _trace
                      : null,
                  child: const Text('Trace (round-trip)'),
                ),
                const SizedBox(width: 8),
                const Expanded(
                    child: Text('measures per-hop SNR both ways',
                        style: TextStyle(fontSize: 11, color: Colors.grey))),
              ]),
              if (_traceResult.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_traceResult,
                      style: const TextStyle(
                          fontFamily: 'monospace', color: Colors.teal)),
                ),
            ],
          );
        },
      ),
    );
  }
}
