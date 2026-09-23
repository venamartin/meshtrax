import 'dart:async';

import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:path_graph/path_graph.dart';

import '../../connector/meshcore_connector.dart';
import '../../models/contact.dart';
import '../../models/message.dart';
import '../../utils/app_logger.dart';
import 'frame_adapter.dart';

/// The path graph's hook into the app: observe only.
///
/// When enabled it feeds the graph from the radio's raw frame stream (the
/// adapter parses every packet the radio logs), the radio identity, the
/// contact list, and every route the firmware proves — a contact's
/// `out_path` after a delivery, and a direct send that was ACKed. Nothing
/// here chooses a route for a message; the debug screen and the map read
/// the graph's answers and a trace proves them on the air.
class PathGraphService extends ChangeNotifier {
  PathGraphService();

  PathGraph? _graph;
  PathLabAdapter? _adapter;
  MeshCoreConnector? _connector;
  StreamSubscription<Uint8List>? _frames;
  Timer? _discoverWindow;

  /// The firmware route last fed per contact (hex), so a refresh that
  /// carries the same path is not counted twice.
  final Map<String, String> _lastProvenPath = {};

  PathGraph? get graph => _graph;
  PathLabAdapter? get adapter => _adapter;
  bool get isRunning => _graph != null;

  /// Opens the graph on `path_graph.db` and starts listening. Idempotent.
  Future<void> start(MeshCoreConnector connector) async {
    if (_graph != null) return;
    final graph = PathGraph(driftDatabase(name: 'path_graph'));
    await graph.init();
    _graph = graph;
    _adapter = PathLabAdapter(graph);
    _connector = connector;
    _frames = connector.receivedFrames.listen(_onFrame);
    connector.addListener(_onConnectorChanged);
    connector.onOutgoingMessageUpdated = _onOutgoingMessage;
    _onConnectorChanged();
    appLogger.info('path graph started', tag: 'PathGraph');
    notifyListeners();
  }

  Future<void> stop() async {
    final graph = _graph;
    if (graph == null) return;
    _discoverWindow?.cancel();
    await _frames?.cancel();
    _connector?.removeListener(_onConnectorChanged);
    _connector?.onOutgoingMessageUpdated = null;
    _connector = null;
    _adapter = null;
    _graph = null;
    _lastProvenPath.clear();
    await graph.dispose();
    appLogger.info('path graph stopped', tag: 'PathGraph');
    notifyListeners();
  }

  void _onFrame(Uint8List frame) {
    final adapter = _adapter;
    if (adapter == null) return;
    adapter.handleFrame(frame);
    // Discover answers arrive one push per responder; commit the batch
    // once the radio's answer window has passed.
    if (frame.isNotEmpty &&
        frame[0] == pushControlData &&
        adapter.pendingDiscover.isNotEmpty) {
      _discoverWindow?.cancel();
      _discoverWindow = Timer(const Duration(seconds: 30), () {
        adapter.commitDiscover(failureEpisode: false);
        notifyListeners();
      });
    }
  }

  void _onConnectorChanged() {
    final graph = _graph;
    final connector = _connector;
    if (graph == null || connector == null) return;

    final self = connector.selfPublicKeyHex;
    if (self.isNotEmpty && graph.selfPubkey != self) {
      graph.setRadioIdentity(self, connector.pathHashByteWidth);
    }

    for (final contact in connector.contacts) {
      graph.ingestContact(contact.publicKeyHex, contact.name);
      _proveFirmwareRoute(contact);
    }
  }

  /// The firmware only ever stores a route a packet actually travelled
  /// in the sending direction (a PATH reply's payload), so a contact's
  /// out_path is proof for every hop — unless the user wrote it.
  void _proveFirmwareRoute(Contact contact) {
    final graph = _graph;
    if (graph == null || contact.pathOverride != null) return;
    if (contact.pathLength < 0) return;
    final hex = contact.path
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    if (_lastProvenPath[contact.publicKeyHex] == hex) return;
    _lastProvenPath[contact.publicKeyHex] = hex;
    graph.reportSendResult(contact.path, true,
        contactPubkey: contact.publicKeyHex);
  }

  /// A direct send that was ACKed proves the route it used; a flood
  /// delivery is proven through the contact refresh that follows it.
  void _onOutgoingMessage(Message message) {
    final graph = _graph;
    if (graph == null || !message.isOutgoing) return;
    if (message.status != MessageStatus.delivered) return;
    final hops = message.pathLength;
    if (hops == null || hops < 0) return;
    graph.reportSendResult(message.pathBytes, true,
        contactPubkey: message.senderKeyHex, tripTimeMs: message.tripTimeMs);
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
