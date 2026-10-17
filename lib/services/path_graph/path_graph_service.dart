import 'dart:async';
import 'dart:typed_data';

import 'package:drift/drift.dart' show QueryExecutor;
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/widgets.dart';
import 'package:path_graph/path_graph.dart';

import '../../connector/meshcore_connector.dart';
import '../../helpers/path_helper.dart';
import '../../models/contact.dart';
import '../../models/path_selection.dart';
import '../../utils/app_logger.dart';
import 'frame_adapter.dart';
import 'radio_route_keeper.dart';

/// Pathfinder: the path graph's hook into the app.
///
/// When enabled it feeds the graph from the radio's raw frame stream (the
/// adapter parses every packet the radio logs), the radio identity, the
/// contact list, every channel packet the connector decrypts (sender name
/// plus the path it arrived on — echoes of this radio's own messages
/// confirm their first hop as a doorstep), every route the firmware
/// learns, and how each direct DM attempt ended. In return it ranks
/// routes for the retry ladder ([candidatesFor]) and keeps its route to
/// each active contact stored on the radio, the route the radio's ACKs
/// go on ([RadioRouteKeeper]).
class PathGraphService extends ChangeNotifier with WidgetsBindingObserver {
  PathGraphService();

  PathGraph? _graph;
  PathLabAdapter? _adapter;
  RadioRouteKeeper? _keeper;
  bool _radioReady = false;
  MeshCoreConnector? _connector;
  StreamSubscription<Uint8List>? _frames;
  Timer? _discoverWindow;
  Timer? _sweepTimer;

  // start() and stop() only record what is wanted; the open and close run
  // one at a time on [_op], so a switch flipped during a slow open is
  // never lost and two opens never overlap.
  bool _wantRunning = false;
  Future<void> _op = Future.value();
  Object? _lastError;

  int _graphDelivered = 0;
  int _graphFailed = 0;

  PathGraph? get graph => _graph;
  PathLabAdapter? get adapter => _adapter;
  bool get isRunning => _graph != null;

  /// Why the last start failed (the graph database would not open), or
  /// null. The app runs without Pathfinder rather than not at all.
  Object? get lastError => _lastError;

  /// Direct DM attempts sent on a graph route since the service started.
  int get graphDelivered => _graphDelivered;
  int get graphFailed => _graphFailed;

  /// Opens the graph on `path_graph.db` and starts listening. Idempotent,
  /// and never throws: a database that will not open leaves Pathfinder
  /// off with [lastError] set. The bench passes its own [database] (in
  /// memory) so a run starts from nothing and leaves nothing behind.
  Future<void> start(MeshCoreConnector connector, {QueryExecutor? database}) {
    _wantRunning = true;
    return _op = _op.then((_) => _open(connector, database));
  }

  Future<void> stop() {
    _wantRunning = false;
    return _op = _op.then((_) => _close());
  }

  Future<void> _open(MeshCoreConnector connector, QueryExecutor? database) async {
    if (!_wantRunning || _graph != null) return;
    PathGraph? graph;
    try {
      graph = PathGraph(database ?? driftDatabase(name: 'path_graph'));
      await graph.init();
    } catch (e) {
      _lastError = e;
      appLogger.error('path graph did not start: $e', tag: 'PathGraph');
      try {
        await graph?.dispose();
      } catch (_) {}
      notifyListeners();
      return;
    }
    if (!_wantRunning) {
      // Switched off while the database was opening.
      await graph.dispose();
      return;
    }
    _lastError = null;
    _graph = graph;
    _adapter = PathLabAdapter(graph)..onPathDiscovery = notifyListeners;
    _connector = connector;
    _frames = connector.receivedFrames.listen(_onFrame);
    connector.addListener(_onConnectorChanged);
    connector.onFirmwarePathLearned = _onFirmwarePath;
    connector.onSendAttemptResult = _onAttemptResult;
    connector.onSendAttemptStarted = _onAttemptStarted;
    connector.onAckHeard = _onAckHeard;
    connector.graphRouteCandidates = candidatesFor;
    connector.onChannelPacketHeard = _onChannelPacket;
    connector.onOwnEchoHeard = _onOwnEcho;
    connector.onContactMessageHeard = _onContactMessage;
    final keeper = _keeper = RadioRouteKeeper(
      contacts: () => connector.contacts,
      routesFor: candidatesFor,
      radioWidth: () => connector.pathHashByteWidth,
      budget: () => connector.messageAttemptBudget,
      isSendingTo: connector.isSendingTo,
      recentChats: connector.contactsWithMessagesSince,
      withRouteLock: connector.withPathLock,
      writeRoute: (contact, route) => route.useFlood
          ? connector.clearContactPath(contact)
          : connector.setContactPath(contact,
              Uint8List.fromList(route.pathBytes), route.hopCount,
              hashSize: route.hashSize),
    );
    connector.onContactMessageCopy = keeper.onCopy;
    connector.onSendLadderEnded = keeper.reassert;
    _radioReady = false;
    WidgetsBinding.instance.addObserver(this);
    _onConnectorChanged();
    appLogger.info('path graph started', tag: 'PathGraph');
    _sweep();
    _sweepTimer = Timer.periodic(const Duration(days: 1), (_) => _sweep());
    notifyListeners();
  }

  /// Forget idle hearsay and enforce the growth caps: on every open and
  /// once a day after.
  void _sweep() {
    final report = _graph?.sweepStale();
    if (report == null || report.isEmpty) return;
    appLogger.info(
        'path graph sweep: removed ${report.totalRemoved}, '
        'cleared ${report.positionsCleared} positions',
        tag: 'PathGraph');
  }

  Future<void> _close() async {
    final graph = _graph;
    if (graph == null) return;
    WidgetsBinding.instance.removeObserver(this);
    _sweepTimer?.cancel();
    _sweepTimer = null;
    _discoverWindow?.cancel();
    _notifyThrottle?.cancel();
    _notifyThrottle = null;
    await _frames?.cancel();
    _connector?.removeListener(_onConnectorChanged);
    _connector?.onFirmwarePathLearned = null;
    _connector?.onSendAttemptResult = null;
    _connector?.onSendAttemptStarted = null;
    _connector?.onAckHeard = null;
    _connector?.graphRouteCandidates = null;
    _connector?.onChannelPacketHeard = null;
    _connector?.onOwnEchoHeard = null;
    _connector?.onContactMessageHeard = null;
    _connector?.onContactMessageCopy = null;
    _connector?.onSendLadderEnded = null;
    _keeper?.dispose();
    _keeper = null;
    _connector = null;
    _adapter = null;
    _graph = null;
    try {
      await graph.dispose();
    } catch (e) {
      appLogger.warn('path graph close failed: $e', tag: 'PathGraph');
    }
    appLogger.info('path graph stopped', tag: 'PathGraph');
    notifyListeners();
  }

  /// Listeners (the debug screen) are told about new observations at
  /// most every couple of seconds; RX-log frames can arrive in bursts.
  Timer? _notifyThrottle;
  void _notifySoon() {
    _keeper?.scheduleSync();
    _notifyThrottle ??= Timer(const Duration(seconds: 2), () {
      _notifyThrottle = null;
      notifyListeners();
    });
  }

  void _onFrame(Uint8List frame) {
    final adapter = _adapter;
    if (adapter == null) return;
    final before = adapter.framesSeen;
    adapter.expectedDiscoverTag = _connector?.pendingDiscoverTag;
    adapter.expectedTraceTag = _connector?.pendingTraceTag;
    adapter.handleFrame(frame);
    if (adapter.framesSeen != before || frame[0] == pushTraceData) {
      _notifySoon();
    }
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
    // A dropped link loses the radio's pending request with it.
    if (!connector.isConnected && _adapter?.pendingDiscoveryPubkey != null) {
      _adapter!.cancelDiscovery('link lost — ask again');
    }
    final ready = connector.isConnected && !connector.isLoadingContacts;
    if (ready && !_radioReady) _keeper?.onConnected();
    _radioReady = ready;

    final self = connector.selfPublicKeyHex;
    // The radio's Path Hash Size can change without a new key; the graph
    // must follow it or my own floods are read at the old width.
    if (self.isNotEmpty &&
        (graph.selfPubkey != self ||
            graph.selfStride != connector.pathHashByteWidth)) {
      graph.setRadioIdentity(self, connector.pathHashByteWidth);
    }

    // Names from everyone the radio knows, saved or merely discovered —
    // a Public sender need not be in the contact list to get a doorstep.
    for (final contact in connector.allContacts) {
      graph.ingestContact(contact.publicKeyHex, contact.name);
    }
    // Routes are proved only from PATH_UPDATED (_onFirmwarePath), never
    // from the contact list: the list cannot tell a firmware route from
    // one this app wrote in an earlier session (a graph route, a Custom
    // route left behind, a restored backup), and re-proving it on every
    // reconnect broke one-proof-per-event. A route the radio learned while
    // the app was closed waits for its next PATH_UPDATED — a missed proof,
    // never a false one.
  }

  /// Observations flush on a 30 s debounce; an Android kill inside that
  /// window would lose them, so flush whenever the app leaves the
  /// foreground.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _graph?.flush();
    }
  }

  /// The radio reported PATH_UPDATED and [snapshot] is the contact as the
  /// radio now holds it: a live PATH reply that arrived right after one of
  /// my floods, naming the path that flood just took. This is the only
  /// thing Pathfinder learns from the firmware side; routes stored on the
  /// radio are never read as evidence and never tried as a route (owner
  /// rule, 2026-10-14).
  void _onFirmwarePath(Contact snapshot) {
    final connector = _connector;
    if (connector == null || snapshot.pathLength < 0) return;
    // The reply that carried this route was a flood from them: credit
    // their doorstep from the logged copy before proving the route.
    _adapter?.attributePathReply(snapshot.publicKeyHex);
    final known = connector.contacts
        .where((c) => c.publicKeyHex == snapshot.publicKeyHex)
        .firstOrNull;
    if (known?.pathOverride != null) return;
    // A ladder write can land between the push and the contact fetch; the
    // snapshot then holds the app's route, not the firmware's.
    if (connector.wroteContactPath(snapshot)) return;
    _provePathReply(snapshot);
    // The firmware just replaced the stored route the ACKs go on.
    _keeper?.reassert(snapshot.publicKeyHex);
  }

  /// A PATH reply names the first flood copy that arrived: it proves both
  /// doorsteps, but says nothing about how good its corridor is.
  /// The route keeps the hash width of the packet that built it
  /// ([Contact.pathHashSize]), not the radio's.
  void _provePathReply(Contact contact) {
    // The flood that earned this route was echoed back first; if that
    // echo already proved the first hop, this is the same proof again.
    // The route's first hop at the graph's width, through PathHelper: a
    // route narrower than the graph has no identity here (and is dropped
    // by the graph below).
    final width = _graph?.hashWidthBytes ?? contact.pathHashSize;
    final hop = contact.pathHashSize >= width
        ? PathHelper.firstHopHex(contact.path, stride: contact.pathHashSize)
        : null;
    final firstHop = hop == null ? '' : hop.substring(0, width * 2);
    final echoed = firstHop.isNotEmpty &&
        (_adapter?.echoAlreadyProved(contact.publicKeyHex, firstHop) ?? false);
    appLogger.info(
        'path reply from ${contact.name}: ${_hops(contact.path, contact.pathHashSize)} '
        '— ${echoed ? "first hop already proved by its echo" : "first hop credited as hearing me"}',
        tag: 'PathGraph');
    _graph?.reportSendResult(contact.path, true,
        contactPubkey: contact.publicKeyHex,
        stride: contact.pathHashSize,
        tally: false,
        proveEgress: !echoed);
    _notifySoon();
  }

  void _onAttemptStarted(Contact contact, PathSelection selection, int attempt) {
    // A direct send never comes back as a flood echo.
    if (!selection.useFlood) return;
    _adapter?.noteAttempt(
        int.parse(contact.publicKeyHex.substring(0, 2), radix: 16), attempt);
  }

  /// The radio confirmed an ACK: if it came back as a flood, its first hop
  /// heard the contact.
  void _onAckHeard(Contact contact, int ackHash) {
    _adapter?.attributeAck(contact.publicKeyHex, ackHash);
    _notifySoon();
  }

  /// How one direct DM attempt ended. A delivery proves the route it went
  /// on; a timeout is the small forward penalty. Floods carry no route.
  void _onAttemptResult(
      Contact contact, PathSelection selection, bool delivered, int? tripMs) {
    final graph = _graph;
    if (graph == null || selection.useFlood) return;
    appLogger.info(
        '${delivered ? "delivered" : "failed"} to ${contact.name} via '
        '${_hops(selection.pathBytes, selection.hashSize)} (${selection.source?.name})'
        '${delivered ? " — first hop credited as hearing me" : ""}',
        tag: 'PathGraph');
    graph.reportSendResult(Uint8List.fromList(selection.pathBytes), delivered,
        contactPubkey: contact.publicKeyHex,
        tripTimeMs: tripMs,
        stride: selection.hashSize);
    if (selection.source == RouteSource.graph) {
      if (delivered) {
        _graphDelivered++;
      } else {
        _graphFailed++;
      }
    }
    _notifySoon();
  }

  /// Pathfinder's ranked routes to [contact] for the retry ladder, best
  /// first (the planner drops repeats and weak ones). Empty when the graph
  /// knows nothing about them: the ladder then floods. Null when
  /// Pathfinder cannot route at all — no graph, or a radio sending hashes
  /// narrower than the graph's (it would reject the wider path) — and the
  /// ladder falls back to the firmware one, as if Pathfinder were off.
  List<PathSelection>? candidatesFor(Contact contact) {
    final graph = _graph;
    final connector = _connector;
    if (graph == null || connector == null) return null;
    final width = graph.hashWidthBytes;
    if (connector.pathHashByteWidth < width) return null;

    PathSelection route(RouteResult r) => PathSelection(
          pathBytes: r.pathBytes,
          hopCount: r.pathBytes.length ~/ width,
          hashSize: width,
          useFlood: false,
          source: RouteSource.graph,
          estDelivery: r.estDelivery,
        );
    final key = contact.publicKeyHex;
    return [
      switch (graph.findPath(key)) {
        DirectResult() => PathSelection(
            pathBytes: const [],
            hopCount: 0,
            hashSize: width,
            useFlood: false,
            source: RouteSource.graph),
        RouteResult r => route(r),
        FloodResult() => null,
      },
      for (final r in graph.findAlternatives(key, count: 3)) route(r),
    ].nonNulls.toList();
  }

  /// A channel message names its sender; if that name belongs to exactly
  /// one contact, the packet's first hop is a repeater that heard them.
  void _onChannelPacket(String senderName, Uint8List pathBytes, int stride) {
    final graph = _graph;
    if (graph == null) return;
    graph.observeChannelSender(senderName, pathBytes, stride);
    _notifySoon();
  }

  /// A DM or room post names its sender by key; the adapter matches it to
  /// the raw packet it came from and credits the sender's doorstep.
  void _onContactMessage(String pubkeyHex, int pathLenRaw, int? snrByte) {
    _adapter?.attributeContactMessage(pubkeyHex, pathLenRaw, snrByte);
    _notifySoon();
  }

  /// My own channel message came back through the mesh: its first hop
  /// heard me directly. Every echo counts — two echoes with different
  /// first hops confirm two doorsteps from one message.
  void _onOwnEcho(Uint8List pathBytes, int stride) {
    final graph = _graph;
    if (graph == null) return;
    appLogger.info(
        'own echo via ${_hops(pathBytes, stride)} — first hop credited as hearing me',
        tag: 'PathGraph');
    graph.observeOwnEcho(pathBytes, stride);
    _notifySoon();
  }

  static String _hops(List<int> bytes, int stride) =>
      PathHelper.formatPathHex(bytes, stride: stride);


  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
