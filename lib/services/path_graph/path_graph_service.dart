import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:drift/drift.dart' show QueryExecutor;
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/widgets.dart';
import 'package:path_graph/path_graph.dart';
import 'package:path_provider/path_provider.dart';

import '../../connector/meshcore_connector.dart';
import '../../connector/meshcore_protocol.dart';
import '../../helpers/path_helper.dart';
import '../../models/contact.dart';
import '../../models/path_selection.dart';
import '../../storage/prefs_manager.dart';
import '../../utils/app_logger.dart';
import '../../utils/platform_info.dart';
import 'frame_adapter.dart';
import 'place_cell.dart';
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
  PathGraphService({math.Random? random}) : _random = random ?? math.Random();

  final math.Random _random;

  PathGraph? _graph;
  PathLabAdapter? _adapter;
  RadioRouteKeeper? _keeper;
  bool _radioReady = false;
  MeshCoreConnector? _connector;
  StreamSubscription<Uint8List>? _frames;
  Timer? _sweepTimer;

  // start() and stop() only record what is wanted; the open and close run
  // one at a time on [_op], so a switch flipped during a slow open is
  // never lost and two opens never overlap.
  bool _wantRunning = false;
  Future<void> _op = Future.value();
  Object? _lastError;

  // One database per mesh: a code names different repeaters on different
  // presets, and a doorstep heard on one says nothing on another. The
  // file follows the connected radio's preset; until one connects, the
  // last mesh used; before any mesh was ever seen, the file from the days
  // of one shared graph (adopted by the first mesh that connects).
  MeshId? _mesh;
  String? _databaseName;
  bool _ownsDatabase = false;
  QueryExecutor Function(String name)? _openDatabase;
  static const _lastMeshPref = 'path_graph_last_mesh';
  static const legacyDatabaseName = 'path_graph';

  int _graphDelivered = 0;
  int _graphFailed = 0;

  // The automatic Discover (owner, 2026-10-25, reversing D3 of 2026-10-17:
  // a flood is repeated by every repeater; a Discover and its answers
  // stay in the first ring). Sent only in the gap after a failed step,
  // only when Pathfinder has a doubt about MY side of the air
  // (PathGraph.selfAdvice), and never more than once in ten minutes.
  DateTime? _lastAutoDiscoverAt;
  Timer? _autoDiscoverTimer;
  bool _inForeground = true;
  static const autoDiscoverEvery = Duration(minutes: 10);
  static const foreignDiscoverQuiet = Duration(seconds: 120);

  /// A random wait before the automatic Discover, so radios that lost the
  /// same repeater do not all ask in the same second; short enough to
  /// stay inside the retry gap so the next rung can use the answers.
  /// Tests set it to zero.
  Duration autoDiscoverJitterMax = const Duration(seconds: 5);

  /// When Pathfinder last sent a Discover of its own.
  DateTime? get lastAutoDiscoverAt => _lastAutoDiscoverAt;

  PathGraph? get graph => _graph;
  PathLabAdapter? get adapter => _adapter;
  bool get isRunning => _graph != null;

  /// The mesh the open graph is for; null until a radio has ever connected.
  MeshId? get mesh => _mesh;
  String? get databaseName => _databaseName;

  static MeshId? meshOf(MeshCoreConnector c) {
    final f = c.currentFreqHz, b = c.currentBwHz, sf = c.currentSf, cr = c.currentCr;
    if (f == null || b == null || sf == null || cr == null) return null;
    return MeshId(freqHz: f, bwHz: b, sf: sf, cr: cr);
  }

  static String databaseNameFor(MeshId? mesh) =>
      mesh == null ? legacyDatabaseName : 'path_graph_${mesh.key}';

  static MeshId? _lastMesh() =>
      MeshId.fromJson(_decode(PrefsManager.instance.getString(_lastMeshPref)));

  static Object? _decode(String? json) {
    if (json == null) return null;
    try {
      return jsonDecode(json);
    } catch (_) {
      return null;
    }
  }

  /// Why the last start failed (the graph database would not open), or
  /// null. The app runs without Pathfinder rather than not at all.
  Object? get lastError => _lastError;

  /// Direct DM attempts sent on a graph route since the service started.
  int get graphDelivered => _graphDelivered;
  int get graphFailed => _graphFailed;

  /// Opens the graph on this mesh's database and starts listening.
  /// Idempotent, and never throws: a database that will not open leaves
  /// Pathfinder off with [lastError] set. The bench passes its own
  /// [database] (in memory) so a run starts from nothing, leaves nothing
  /// behind, and keeps its graph when it retunes the radio. Tests pass
  /// [openDatabase] to see which file each mesh would get.
  Future<void> start(MeshCoreConnector connector,
      {QueryExecutor? database, QueryExecutor Function(String name)? openDatabase}) {
    _wantRunning = true;
    _openDatabase = openDatabase;
    return _op = _op.then((_) => _open(connector, database));
  }

  Future<void> stop() {
    _wantRunning = false;
    return _op = _op.then((_) => _close());
  }

  Future<void> _open(MeshCoreConnector connector, QueryExecutor? database) async {
    if (!_wantRunning || _graph != null) return;
    final mesh = meshOf(connector) ?? (database == null ? _lastMesh() : null);
    final name = database == null ? databaseNameFor(mesh) : null;
    PathGraph? graph;
    try {
      if (name != null && _openDatabase == null) await _adoptLegacyFile(name, mesh);
      graph = PathGraph(
          database ?? _openDatabase?.call(name!) ?? driftDatabase(name: name!),
          mesh: mesh);
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
    _mesh = mesh;
    _databaseName = name;
    _ownsDatabase = database == null;
    if (mesh != null && database == null) {
      unawaited(PrefsManager.instance
          .setString(_lastMeshPref, jsonEncode(mesh.toJson())));
    }
    final live = _graph = graph;
    live.onMovingSign = (hash, reason, check) {
      final name = live.snapshot().nodes[hash]?.name;
      final who = name == null ? hash : '$hash ($name)';
      final watching =
          live.config.mobileAutoTagsRoute ? '' : ' (watching only)';
      final rides = reason == MovingReason.ridesWithMe;
      final counts = 'met ${check.newLinks} repeaters it never had and was '
          'heard with ${check.oldLinks} it had, in ${rides ? 2 : 3} h';
      final shared = check.tagged && !rides
          ? live.movingStatus(hash)?.sharedKeys
          : null;
      appLogger.info(
          !check.tagged
              ? 'Pathfinder: $who $counts, so it stays put'
              : rides
                  ? 'Pathfinder thinks $who rides with me: it keeps proving '
                      'it hears me and $counts$watching'
                  : shared != null
                      ? 'Pathfinder: $who $counts — $shared radios use this '
                          'code, so it seems to be in several places$watching'
                      : 'Pathfinder thinks $who moves: it $counts$watching',
          tag: 'PathGraph');
    };
    _adapter = PathLabAdapter(graph)..onPathDiscovery = notifyListeners;
    _connector = connector;
    _frames = connector.receivedFrames.listen(_onFrame);
    connector.addListener(_onConnectorChanged);
    connector.onFirmwarePathLearned = _onFirmwarePath;
    connector.onSendAttemptResult = _onAttemptResult;
    connector.onSendAttemptStarted = _onAttemptStarted;
    connector.onAckHeard = _onAckHeard;
    connector.graphRouteCandidates = candidatesFor;
    connector.graphDistanceTo = distanceTo;
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
    connector.onSendOutcome = _onSendOutcome;
    connector.onFloodAttemptEnded = _onFloodAttempt;
    connector.graphRoomNeedsRelearn = roomNeedsRelearnAfterMove;
    connector.selfGps.addListener(_syncPlace);
    _radioReady = false;
    WidgetsBinding.instance.addObserver(this);
    _onConnectorChanged();
    appLogger.info(
        mesh == null
            ? 'path graph started; the mesh is unknown until a radio connects'
            : 'path graph started for $mesh'
                '${name == null ? "" : " (file $name)"}',
        tag: 'PathGraph');
    _sweep();
    _sweepTimer = Timer.periodic(const Duration(days: 1), (_) => _sweep());
    notifyListeners();
  }

  /// The first time a mesh gets its own file, the graph learned before
  /// meshes were kept apart moves into it: the first mesh to connect is
  /// the one it was learned on for anybody with one radio and one mesh.
  Future<void> _adoptLegacyFile(String name, MeshId? mesh) async {
    if (PlatformInfo.isWeb || name == legacyDatabaseName) return;
    final dir = (await getApplicationDocumentsDirectory()).path;
    final sep = Platform.pathSeparator;
    final target = File('$dir$sep$name.sqlite');
    final legacy = File('$dir$sep$legacyDatabaseName.sqlite');
    if (await target.exists() || !await legacy.exists()) return;
    for (final suffix in const ['', '-journal', '-wal', '-shm']) {
      final f = File('${legacy.path}$suffix');
      if (await f.exists()) await f.rename('${target.path}$suffix');
    }
    appLogger.info(
        'moved the graph learned before meshes were kept apart into the file for $mesh',
        tag: 'PathGraph');
  }

  /// The radio reports another preset than the open graph is for: close
  /// it and open the file of that mesh. Never while the caller owns the
  /// database (the bench retunes mid-run and keeps its graph).
  void _reopenFor(MeshCoreConnector connector, MeshId mesh) {
    appLogger.info('radio is on $mesh; switching to the graph of that mesh',
        tag: 'PathGraph');
    _op = _op.then((_) async {
      if (!_wantRunning) return;
      await _close();
      await _open(connector, null);
    });
  }

  /// Forget idle hearsay and enforce the growth caps: on every open and
  /// once a day after.
  void _sweep() {
    final report = _graph?.sweepStale();
    if (report == null || report.isEmpty) return;
    appLogger.info('path graph sweep: removed ${report.totalRemoved}',
        tag: 'PathGraph');
  }

  Future<void> _close() async {
    final graph = _graph;
    if (graph == null) return;
    WidgetsBinding.instance.removeObserver(this);
    _sweepTimer?.cancel();
    _sweepTimer = null;
    _notifyThrottle?.cancel();
    _notifyThrottle = null;
    _autoDiscoverTimer?.cancel();
    _autoDiscoverTimer = null;
    await _frames?.cancel();
    _connector?.removeListener(_onConnectorChanged);
    _connector?.selfGps.removeListener(_syncPlace);
    _connector?.onFirmwarePathLearned = null;
    _connector?.onSendAttemptResult = null;
    _connector?.onSendAttemptStarted = null;
    _connector?.onAckHeard = null;
    _connector?.graphRouteCandidates = null;
    _connector?.graphDistanceTo = null;
    _connector?.onChannelPacketHeard = null;
    _connector?.onOwnEchoHeard = null;
    _connector?.onContactMessageHeard = null;
    _connector?.onContactMessageCopy = null;
    _connector?.onSendLadderEnded = null;
    _connector?.onSendOutcome = null;
    _connector?.onFloodAttemptEnded = null;
    _connector?.graphRoomNeedsRelearn = null;
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

  /// The user's word on whether repeater [hash] moves; null lets the
  /// detectors decide. Routes change at once; the radio's stored routes
  /// follow on the keeper's next check.
  void setMovingOverride(String hash, MovingOverride? value) {
    final graph = _graph;
    if (graph == null) return;
    graph.setMovingOverride(hash, value);
    final how = switch (value) {
      null => 'left to Pathfinder',
      MovingOverride.moves => 'marked as moving',
      MovingOverride.withMe => 'marked as moving with me',
      MovingOverride.staysPut => 'marked as staying put',
    };
    appLogger.info('repeater $hash $how', tag: 'PathGraph');
    _notifySoon();
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
    if (adapter.framesSeen != before ||
        frame[0] == pushTraceData ||
        frame[0] == pushControlData) {
      _notifySoon();
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

    final mesh = meshOf(connector);
    if (mesh != null && mesh != _mesh && _ownsDatabase) {
      _reopenFor(connector, mesh);
      return;
    }

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
    final sw = Stopwatch()..start();
    final all = connector.allContacts;
    for (final contact in all) {
      graph.ingestContact(contact.publicKeyHex, contact.name);
    }
    appLogger.perf(
      'Pathfinder contact re-ingest',
      sw,
      detail: '${all.length} contacts',
    );
    _syncPlace();
    // Routes are proved only from PATH_UPDATED (_onFirmwarePath), never
    // from the contact list: the list cannot tell a firmware route from
    // one this app wrote in an earlier session (a graph route, a Custom
    // route left behind, a restored backup), and re-proving it on every
    // reconnect broke one-proof-per-event. A route the radio learned while
    // the app was closed waits for its next PATH_UPDATED — a missed proof,
    // never a false one.
  }

  /// The radio's position reaches the graph only as a cell about 500 m
  /// across ([PlaceCell]), and only while it is a live fix: a GPS the
  /// radio has and has on, firmware that reports it, and a reading that
  /// has moved off the position the radio reported at connect (a stored
  /// position after a restart looks like a fix). Nothing here sends a
  /// frame; the connector already polls the position while GPS is on.
  /// The log says that the area is known or changed, never which.
  void _syncPlace() {
    final graph = _graph;
    final c = _connector;
    if (graph == null || c == null) return;
    final fix = c.selfGps.value;
    final live = c.isConnected &&
        c.hasGps &&
        c.gpsOn &&
        (c.firmwareVerCode ?? 0) >= 6 &&
        c.selfPositionIsLive &&
        fix != null;
    if (!live) {
      if (graph.currentCell == null) return;
      graph.setPlace(null, const {});
      appLogger.info('Pathfinder no longer knows the area the radio is in',
          tag: 'PathGraph');
      _notifySoon();
      return;
    }
    final cell = PlaceCell.of(fix.latitude, fix.longitude);
    if (cell.key == graph.currentCell) return;
    final first = graph.currentCell == null;
    graph.setPlace(cell.key, cell.near);
    appLogger.info(
        first
            ? 'Pathfinder knows the area the radio is in (about 500 m)'
            : 'Pathfinder: the radio moved to another area',
        tag: 'PathGraph');
    _notifySoon();
  }

  /// Observations flush on a 30 s debounce; an Android kill inside that
  /// window would lose them, so flush whenever the app leaves the
  /// foreground.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _inForeground = state != AppLifecycleState.paused &&
        state != AppLifecycleState.hidden &&
        state != AppLifecycleState.detached;
    if (!_inForeground) {
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
  /// One message's ladder is over. A ladder that went unanswered with no
  /// repeater heard echoing its floods is a doubt about my side of the
  /// air, which one Discover can settle ([PathGraph.selfAdvice]).
  void _onSendOutcome(String contactKey,
      {required bool delivered, required bool? echoHeard}) {
    final graph = _graph;
    if (graph == null) return;
    graph.reportLadderEnded(contactKey,
        delivered: delivered, echoHeard: echoHeard);
    if (!delivered) _considerDiscover(contactKey);
  }

  /// A send to [contactKey] just failed a step: if Pathfinder has a doubt
  /// about my side of the air that one Discover would settle, and every
  /// gate is open, one goes out after a short random wait.
  void _considerDiscover(String contactKey) {
    final graph = _graph;
    final c = _connector;
    if (graph == null || c == null) return;
    final reason = graph.selfAdvice(contactPubkey: contactKey);
    if (reason == null) return;
    final words = discoverReasonText(reason);
    final held = _discoverHold(c);
    if (held != null) {
      appLogger.info('Pathfinder would like one Discover ($words) but held it: $held',
          tag: 'PathGraph');
      return;
    }
    if (_autoDiscoverTimer != null) return;
    final maxMs = autoDiscoverJitterMax.inMilliseconds;
    final wait = Duration(milliseconds: maxMs == 0 ? 0 : _random.nextInt(maxMs));
    _autoDiscoverTimer = Timer(wait, () {
      _autoDiscoverTimer = null;
      unawaited(_sendAutoDiscover(reason));
    });
  }

  /// Why an automatic Discover may not go out now, or null.
  String? _discoverHold(MeshCoreConnector c) {
    if (!c.isConnected) return 'no radio';
    if (!_inForeground) return 'the app is in the background';
    if (c.isDiscovering) return 'a Discover is already listening';
    if (c.hasChannelSendsQueued) return 'channel messages are queued';
    if (!c.hasDmSendsInFlight) return 'nothing is waiting to be sent';
    final now = DateTime.now();
    final last = _lastAutoDiscoverAt;
    if (last != null && now.difference(last) < autoDiscoverEvery) {
      return 'the last automatic ask was ${now.difference(last).inMinutes} min ago';
    }
    final foreign = c.foreignDiscoverHeardAt;
    if (foreign != null && now.difference(foreign) < foreignDiscoverQuiet) {
      return 'another Discover was heard ${now.difference(foreign).inSeconds} s '
          'ago (repeaters answer 4 per 2 minutes, shared)';
    }
    return null;
  }

  Future<void> _sendAutoDiscover(DiscoverReason reason) async {
    final c = _connector;
    if (c == null || _graph == null) return;
    final held = _discoverHold(c);
    final words = discoverReasonText(reason);
    if (held != null) {
      appLogger.info('Pathfinder would like one Discover ($words) but held it: $held',
          tag: 'PathGraph');
      return;
    }
    _lastAutoDiscoverAt = DateTime.now();
    // A fresh position for the cell the answers are filed under (one
    // frame to the radio, no RF).
    unawaited(c.requestSelfPosition());
    await c.sendRepeaterDiscovery(automatic: true);
    appLogger.info(
        'Pathfinder asked which repeaters hear me: $words; next automatic '
        'ask in ${autoDiscoverEvery.inMinutes} min at the earliest',
        tag: 'PathGraph');
    _notifySoon();
  }

  /// Whether the radio has moved since [room] last got a packet of its
  /// and the room's way back ends where the radio no longer is. A flooded
  /// post would not fix that (the room ACKs on its stored route back and
  /// sends no PATH); only a flooded login does, so the connector does one
  /// before the post. Pure: nothing is sent from here.
  bool roomNeedsRelearnAfterMove(Contact room) {
    final graph = _graph;
    if (graph == null || room.type != advTypeRoom) return false;
    final result = graph.findPath(room.publicKeyHex);
    return result is FloodResult &&
        result.reason == FloodReason.movedSinceTheyReachedMe;
  }

  /// Why Pathfinder would like a Discover, in plain words.
  static String discoverReasonText(DiscoverReason reason) => switch (reason) {
        DiscoverReason.noDoorstepHere =>
          'no repeater has been heard hearing this radio around here',
        DiscoverReason.movedSinceProof =>
          'the radio has moved since a repeater last proved it hears it',
        DiscoverReason.doorstepsFailingMe =>
          'the repeaters that hear this radio keep failing its sends to '
              'more than one contact',
        DiscoverReason.ladderUnanswered =>
          'a whole send went unanswered and no repeater echoed it',
      };

  /// A flood attempt ended. Delivered: their radio learned the way back
  /// from where I am now. Not delivered: the step most worth a Discover
  /// after, since the ladder is still running and its next rung can use
  /// the answers (the simulator's deaf-here run, 2026-10-25).
  void _onFloodAttempt(Contact contact, {required bool delivered}) {
    final graph = _graph;
    if (graph == null) return;
    if (delivered) {
      graph.reportFloodDelivered(contact.publicKeyHex);
    } else {
      _considerDiscover(contact.publicKeyHex);
    }
  }

  void _onAttemptResult(
      Contact contact, PathSelection selection, bool delivered, int? tripMs) {
    final graph = _graph;
    if (graph == null || selection.useFlood) return;
    final guessed = selection.guessedHops;
    appLogger.info(
        '${delivered ? "delivered" : "failed"} to ${contact.name} via '
        '${_hops(selection.pathBytes, selection.hashSize)} (${selection.source?.name}'
        '${guessed > 0 ? ", $guessed hop${guessed == 1 ? "" : "s"} guessed" : ""})'
        '${delivered ? " — first hop credited as hearing me" : ""}'
        '${delivered && guessed > 0 ? ", guessed hops now proven" : ""}'
        '${!delivered && guessed > 0 ? " — a guess failed, nothing recorded" : ""}',
        tag: 'PathGraph');
    graph.reportSendResult(Uint8List.fromList(selection.pathBytes), delivered,
        contactPubkey: contact.publicKeyHex,
        tripTimeMs: tripMs,
        stride: selection.hashSize,
        guessedLinks: selection.guessedLinks);
    if (selection.source == RouteSource.graph) {
      if (delivered) {
        _graphDelivered++;
        _keeper?.onDelivered(contact.publicKeyHex, selection);
      } else {
        _graphFailed++;
      }
    }
    if (!delivered) _considerDiscover(contact.publicKeyHex);
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
          guessedLinks: r.guessedLinks,
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

  /// The freshest distance to [contact] in hops: the route their last PATH
  /// reply named while it is live, else the hops their last flood took to
  /// reach me (within the hour), else null. The connector sizes a flood's
  /// ACK wait from it instead of assuming 8 hops.
  int? distanceTo(Contact contact) {
    final key = contact.publicKeyHex;
    return _graph?.liveRouteHops(key) ?? _adapter?.lastFloodHopsFor(key);
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
    // Their flood came with repeater codes narrower than the graph's: the
    // graph drops such paths, so it can never learn where they are.
    final graph = _graph;
    if (graph != null &&
        PathHelper.pathLenHops(pathLenRaw) > 0 &&
        PathHelper.pathLenWidth(pathLenRaw) < graph.hashWidthBytes &&
        _narrowSenders.add(pubkeyHex.toLowerCase())) {
      notifyListeners();
    }
    _notifySoon();
  }

  // Contacts whose floods arrived with 1-byte repeater codes this session.
  final Set<String> _narrowSenders = {};
  static const _narrowNoticeDismissedKey =
      'pathfinder_narrow_notice_dismissed';

  /// Whether to tell the user, once, that [contactPubkeyHex]'s radio sends
  /// short repeater codes so Pathfinder cannot learn routes to them.
  bool showNarrowNotice(String contactPubkeyHex) {
    final key = contactPubkeyHex.toLowerCase();
    if (!isRunning || !_narrowSenders.contains(key)) return false;
    final dismissed =
        PrefsManager.instance.getStringList(_narrowNoticeDismissedKey) ??
            const [];
    return !dismissed.contains(key);
  }

  /// The user has read the notice for this contact: never show it again.
  Future<void> dismissNarrowNotice(String contactPubkeyHex) async {
    final key = contactPubkeyHex.toLowerCase();
    final dismissed = {
      ...?PrefsManager.instance.getStringList(_narrowNoticeDismissedKey),
      key,
    };
    await PrefsManager.instance
        .setStringList(_narrowNoticeDismissedKey, dismissed.toList());
    notifyListeners();
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
