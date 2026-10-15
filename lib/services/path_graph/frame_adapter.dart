// path_lab frame adapter — ALL low-level packet parsing for the
// verification harness lives here, NOT in the path_graph module and NOT
// (yet) in the app. At Phase 3 this file's parsers migrate into the
// connector unchanged. Wire layouts verified against MeshCore firmware
// (Packet.h, AdvertDataHelpers.h, simple_repeater/MyMesh.cpp) and
// docs/meshcore-protocol.md.

import 'dart:convert';
import 'dart:typed_data';

import 'package:path_graph/path_graph.dart';

import '../../helpers/path_helper.dart';
import '../../utils/app_logger.dart';

// Packet header (Packet.h).
const int _phRouteMask = 0x03;
const int _maxPathBytes = 64; // MAX_PATH_SIZE
const int _phTypeShift = 2;
const int _phTypeMask = 0x0F;
const int _routeTransportFlood = 0x00;
const int _routeFlood = 0x01;
const int _routeTransportDirect = 0x03;

const int _payloadTypeTxtMsg = 0x02;
const int _payloadTypeAck = 0x03;
const int _payloadTypeAnonReq = 0x07;
const int _payloadTypePath = 0x08;
const int _payloadTypeAdvert = 0x04;
const int _payloadTypeTrace = 0x09;

/// Plain-word label per payload type (Packet.h PAYLOAD_TYPE_*).
String packetKind(int payloadType) => switch (payloadType) {
      0x00 => 'request',
      0x01 => 'response',
      0x02 => 'dm',
      0x03 => 'ack',
      _payloadTypeAdvert => 'advert',
      0x05 => 'channel',
      0x06 => 'channel data',
      0x07 => 'anon request',
      0x08 => 'path reply',
      _payloadTypeTrace => 'trace',
      0x0A => 'multipart',
      _ => 'type 0x${payloadType.toRadixString(16)}',
    };

/// One packet the radio logged and what the graph did with it, for the
/// debug screen: the user cannot tell "not recorded" from "recorded but
/// not shown" without this.
class PacketLogEntry {
  PacketLogEntry({
    required this.at,
    required this.kind,
    required this.path,
    required this.verdict,
    required this.rxSnr,
  });

  final DateTime at;
  final String kind;

  /// Hops at the packet's own hash width, `›`-joined; empty = direct.
  final String path;
  final String verdict;
  final double rxSnr;
}

// Advert app_data flags (AdvertDataHelpers.h).
const int _advTypeMask = 0x0F;
const int _advTypeChat = 1;
const int _advTypeRepeater = 2;
const int _advTypeRoom = 3;
const int _advLatLonMask = 0x10;
const int _advFeat1Mask = 0x20;
const int _advFeat2Mask = 0x40;
const int _advNameMask = 0x80;

// Companion push codes.
const int pushAdvert = 0x80;
const int pushNewAdvert = 0x8A;
const int pushLogRxData = 0x88;
const int pushTraceData = 0x89;
const int pushPathDiscoveryResponse = 0x8D;
const int pushControlData = 0x8E;
const int _ctlNodeDiscoverResp = 0x90;

/// CMD_SEND_PATH_DISCOVERY_REQ (companion_radio MyMesh.cpp:52).
const int _cmdSendPathDiscoveryReq = 52;

/// `[52][0][pubkey x32]` — firmware forces a flood telemetry REQ to the
/// contact and reports both proven paths when the response returns.
Uint8List buildPathDiscoveryReq(Uint8List contactPubkey) =>
    Uint8List.fromList([_cmdSendPathDiscoveryReq, 0, ...contactPubkey]);

String _hex(List<int> bytes) => bytes
    .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
    .join();

/// Stable id over payload bytes for variant dedup (FNV-1a).
String payloadFingerprint(Uint8List payload) {
  var h = 0x811c9dc5;
  for (final b in payload) {
    h = ((h ^ b) * 0x01000193) & 0xFFFFFFFF;
  }
  return h.toRadixString(16);
}

/// A flooded DM or room post addressed to me, logged raw and waiting for
/// the decoded message that names its sender.
class _FloodAck {
  _FloodAck(this.at, this.hash, this.snrByte, this.pathBytes, this.stride);
  final DateTime at;
  final int hash;
  final int snrByte;
  final Uint8List pathBytes;
  final int stride;
}

class _PendingDiscovery {
  _PendingDiscovery(this.pubkey, this.expiresAt);
  final String pubkey;
  DateTime expiresAt;

  /// The radio already answered the request with SENT or ERR; any later
  /// one belongs to another command.
  bool ackSeen = false;
}

class _HeldAdvert {
  _HeldAdvert(this.at, this.advert, this.packet);
  final DateTime at;
  final ParsedAdvert advert;
  final RawPacket packet;
}

class _Attempt {
  _Attempt(this.at, this.contactByte, this.index);
  final DateTime at;
  final int contactByte;
  final int index;
  final Set<String> credited = {};

  /// A newer attempt to the same contact started, or their ACK arrived:
  /// no further echo is credited to this one. What it already credited
  /// still counts for [PathLabAdapter.echoAlreadyProved].
  bool closed = false;
}

class _FloodMessage {
  _FloodMessage(this.at, this.payloadType, this.srcHash, this.snrByte,
      this.pathBytes, this.stride, this.payload);
  final DateTime at;
  final int payloadType;

  /// Identical in every copy of one flood (only the path grows), so it
  /// tells copies of one packet from a different packet.
  final Uint8List payload;
  // The sender's first key byte and the frame's signed SNR byte: with the
  // hop count and width, the keys the decoded message is matched on.
  final int srcHash;
  final int snrByte;
  final Uint8List pathBytes;
  final int stride;
}

class RawPacket {
  RawPacket(this.routeType, this.payloadType, this.stride, this.pathBytes,
      this.payload);
  final int routeType;
  final int payloadType;
  final int stride;
  final Uint8List pathBytes;
  final Uint8List payload;
}

/// [header][transport 4?][path_len][path...][payload] (Packet.h).
RawPacket? parseRawPacket(Uint8List raw) {
  if (raw.length < 2) return null;
  var i = 0;
  final header = raw[i++];
  // The firmware drops these before anything else sees them
  // (Dispatcher::tryParsePacket): a newer payload version, the reserved
  // path mode, and a path longer than it can hold.
  if (header >> 6 != 0) return null;
  final routeType = header & _phRouteMask;
  if (routeType == _routeTransportFlood || routeType == _routeTransportDirect) {
    i += 4;
  }
  if (i >= raw.length) return null;
  final pathLenRaw = raw[i++];
  if (pathLenRaw >> 6 == 3) return null;
  final stride = PathHelper.pathLenWidth(pathLenRaw);
  final pathByteLen = PathHelper.pathLenBytes(pathLenRaw);
  if (pathByteLen > _maxPathBytes || i + pathByteLen > raw.length) {
    return null;
  }
  final path = Uint8List.sublistView(raw, i, i + pathByteLen);
  i += pathByteLen;
  return RawPacket(routeType, (header >> _phTypeShift) & _phTypeMask, stride,
      path, Uint8List.sublistView(raw, i));
}

class ParsedAdvert {
  ParsedAdvert(this.pubkey, this.type, this.name, this.lat, this.lon);
  final Uint8List pubkey;

  /// Lowercase, like every other pubkey in the app and the graph.
  String get pubkeyHex => _hex(pubkey).toLowerCase();

  /// The node's on-air hash at [width] bytes (uppercase, as the graph
  /// keys repeaters).
  String nodeHash(int width) =>
      PathHelper.hopHex(PathHelper.pubKeyPrefix(pubkey, stride: width));
  final int type;
  final String? name;
  final double? lat;
  final double? lon;
}

/// pubkey(32) + timestamp(4) + signature(64) + app_data (flags, latlon?,
/// feats?, name). Signature NOT verified here, and the radio logs the raw
/// packet before it verifies anything: who sent an advert is trusted only
/// once the radio pushes PUSH_CODE_ADVERT / NEW_ADVERT for that key.
ParsedAdvert? parseAdvert(Uint8List payload) {
  if (payload.length < 32 + 4 + 64 + 1) return null;
  final pubkey = Uint8List.fromList(payload.sublist(0, 32));
  var i = 32 + 4 + 64;
  final flags = payload[i++];
  double? lat, lon;
  if (flags & _advLatLonMask != 0) {
    if (i + 8 > payload.length) return null;
    final bd = ByteData.sublistView(payload, i, i + 8);
    lat = bd.getInt32(0, Endian.little) / 1e6;
    lon = bd.getInt32(4, Endian.little) / 1e6;
    i += 8;
  }
  if (flags & _advFeat1Mask != 0) i += 2;
  if (flags & _advFeat2Mask != 0) i += 2;
  String? name;
  if (flags & _advNameMask != 0 && i < payload.length) {
    name = utf8.decode(payload.sublist(i), allowMalformed: true);
  }
  return ParsedAdvert(pubkey, flags & _advTypeMask, name, lat, lon);
}

/// Trace response (0x89):
/// [code][reserved][path_len][flag][tag x4][auth x4][path][snr per hop][snr final]
/// Each SNR byte is signed, quarter-dB: the level at which that hop
/// heard the *previous* transmission (snr[0] = hop 1 heard us). The
/// firmware appends one extra byte, the level at which THIS radio heard
/// the last hop (companion MyMesh.cpp onTraceRecv), so `snrs` is one
/// longer than `hops`.
///
/// The hash width is the trace's own (flags & 3 = log2 width, companion
/// MyMesh.cpp onTraceRecv), never the radio's: a 1-byte trace on a 2-byte
/// radio would otherwise glue two hops into one phantom hash. A trace
/// narrower than the graph's [bucketBytes] comes back with no hops.
({List<String> hops, List<double> snrs, int width})? parseTraceResponse(
    Uint8List frame, int bucketBytes) {
  const headerLen = 12;
  if (frame.length < headerLen) return null;
  final pathLen = frame[2];
  final width = 1 << (frame[3] & 0x03);
  final snrCount = (pathLen ~/ width) + 1;
  if (headerLen + pathLen + snrCount > frame.length) return null;
  final snrs = frame
      .sublist(headerLen + pathLen, headerLen + pathLen + snrCount)
      .map((b) => b.toSigned(8) / 4.0)
      .toList();
  if (width < bucketBytes) return (hops: <String>[], snrs: snrs, width: width);
  final pathBytes = frame.sublist(headerLen, headerLen + pathLen);
  final hops = [
    for (final hop in PathHelper.getHops(pathBytes, stride: width))
      if (hop.length == width) PathHelper.hopHex(hop.sublist(0, bucketBytes))
  ];
  return (hops: hops, snrs: snrs, width: width);
}

/// Path-discovery response (0x8D):
/// `[code][reserved][pubkey_prefix x6][out_len][out_path][in_len][in_path]`
/// where each `*_len` is the raw path_len byte (stride in bits 7:6,
/// hop count in bits 5:0). out_path = the route our flood took TO them
/// (forward-proven); in_path = the route the response came BACK
/// (reverse-proven; its path[0] is THEIR doorstep).
({String pubkeyPrefix, Uint8List outPath, int outStride, Uint8List inPath,
    int inStride})? parsePathDiscovery(Uint8List frame) {
  if (frame.length < 9) return null;
  var i = 2;
  final prefix = _hex(frame.sublist(i, i + 6));
  i += 6;

  (Uint8List, int)? readPath() {
    if (i >= frame.length) return null;
    final raw = frame[i++];
    final stride = PathHelper.pathLenWidth(raw);
    final bytes = PathHelper.pathLenBytes(raw);
    if (i + bytes > frame.length) return null;
    final path = Uint8List.sublistView(frame, i, i + bytes);
    i += bytes;
    return (path, stride);
  }

  final out = readPath();
  if (out == null) return null;
  final back = readPath();
  if (back == null) return null;
  return (
    pubkeyPrefix: prefix,
    outPath: out.$1,
    outStride: out.$2,
    inPath: back.$1,
    inStride: back.$2
  );
}

/// Feeds parsed frames into the module. The harness owns windowing of
/// discover responses (they arrive one push per responder).
class PathLabAdapter {
  PathLabAdapter(this.graph);

  final PathGraph graph;
  final List<DiscoverResponse> pendingDiscover = [];

  /// Tag of the repeater-discovery request this radio has out, if any;
  /// replies carrying any other tag answer someone else.
  int? expectedDiscoverTag;

  /// Tag of the trace this app has out, if any. The radio pushes every
  /// finished trace it hears — other people's too — and only the tag
  /// says which one I sent.
  int? expectedTraceTag;
  int framesSeen = 0;
  int tracesSkipped = 0;
  int messagesAttributed = 0;

  /// Newest first, bounded.
  final List<PacketLogEntry> packetLog = [];
  static const int _packetLogCap = 40;

  /// Oldest first. The radio logs the raw packet at once but hands the
  /// decoded message over one sync round-trip later (MSG_WAITING, then
  /// SYNC_NEXT_MESSAGE), with any number of other packets in between.
  final List<_FloodMessage> _floodMessages = [];
  static const int _floodMessageCap = 32;
  static const Duration _floodMessageWindow = Duration(seconds: 60);

  /// PATH_UPDATED follows the logged reply within a second or two (the
  /// log is pushed before the radio decrypts, and the app fetches the
  /// contact before telling us). Ten seconds covers a slow link; a longer
  /// window would let a same-first-byte stranger's reply be filed as theirs.
  static const Duration _pathReplyWindow = Duration(seconds: 10);

  /// Sender byte → until when: copies of a PATH reply already attributed
  /// (or refused) are not kept for the next one.
  final Map<int, DateTime> _consumedPathReplies = {};

  /// Why the graph filed nothing for a matched packet, in plain words.
  String _notFiled(List<int> pathBytes, int stride) =>
      stride < graph.hashWidthBytes
          ? 'dropped — $stride-byte hashes, the graph needs '
              '${graph.hashWidthBytes}'
          : 'malformed — path is not a whole number of hops';

  /// Flooded ACKs, oldest first, keyed by their hash: an ACK carries no
  /// address, so only the hash the radio later confirms can say whose it is.
  final List<_FloodAck> _floodAcks = [];
  static const int _floodAckCap = 32;

  /// DM / post attempts the retry ladder has in flight, oldest first. A
  /// flooded copy of my own DM comes back with only two address bytes in
  /// clear; the attempt is the gate that makes them mine.
  final List<_Attempt> _attempts = [];
  static const int _attemptCap = 16;
  static const Duration _attemptWindow = Duration(seconds: 60);

  /// First hops credited from a login echo, hop → when: copies of one
  /// login that share a first hop are one proof, and the firmware route
  /// that follows must not prove the same hop a second time.
  final Map<String, DateTime> _loginEchoCredited = {};

  /// The retry ladder is about to flood [attemptIndex] to the contact
  /// whose first key byte is [contactByte]. Only floods come back as
  /// echoes; a direct send never opens a window.
  void noteAttempt(int contactByte, int attemptIndex) {
    final now = DateTime.now();
    _attempts.removeWhere((a) => now.difference(a.at) > _attemptWindow);
    _closeAttempts(contactByte);
    _attempts.add(_Attempt(now, contactByte, attemptIndex));
    if (_attempts.length > _attemptCap) _attempts.removeAt(0);
  }

  void _closeAttempts(int contactByte) {
    for (final a in _attempts) {
      if (a.contactByte == contactByte) a.closed = true;
    }
  }

  /// Did an echo already prove [hopHex] hears me for a send to
  /// [contactPubkeyHex] (or a login) within the attempt window? The
  /// firmware route or delivery that follows refreshes the proof instead
  /// of counting it again.
  bool echoAlreadyProved(String contactPubkeyHex, String hop) {
    final hopHex = hop.toUpperCase();
    final now = DateTime.now();
    final byte = int.parse(contactPubkeyHex.substring(0, 2), radix: 16);
    final login = _loginEchoCredited[hopHex];
    if (login != null && now.difference(login) <= _attemptWindow) return true;
    return _attempts.any((a) =>
        a.contactByte == byte &&
        a.credited.contains(hopHex) &&
        now.difference(a.at) <= _attemptWindow);
  }

  bool _isFlood(RawPacket p) =>
      p.routeType == _routeFlood || p.routeType == _routeTransportFlood;

  /// The first hop of [pathBytes] as the graph identifies it: the hop at
  /// the path's own [stride], cut to the graph's width. PathHelper owns the
  /// slicing; nothing here reads bytes by hand. Null for an empty path or
  /// one narrower than the graph (those are dropped, never guessed).
  String? _firstHopId(List<int> pathBytes, int stride) {
    if (stride < graph.hashWidthBytes) return null;
    final hop = PathHelper.firstHopHex(pathBytes, stride: stride);
    return hop?.substring(0, graph.hashWidthBytes * 2);
  }

  /// A flood under my own key is an echo of my own packet: its first hop
  /// heard me. A DM/post shows only two address bytes in clear, so it is
  /// mine only while an attempt to that contact is in flight (and each
  /// first hop counts once per attempt). A login (anon request) carries my
  /// whole public key in clear, so it is mine on sight.
  void _observeOwnEcho(RawPacket packet) {
    final self = graph.selfPubkey;
    if (self == null || !_isFlood(packet)) return;
    final firstHop = _firstHopId(packet.pathBytes, packet.stride);
    if (firstHop == null) return;
    final myByte = int.parse(self.substring(0, 2), radix: 16);
    final now = DateTime.now();

    if (packet.payloadType == _payloadTypeAnonReq) {
      if (packet.payload.length < 33) return;
      final key = _hex(packet.payload.sublist(1, 33)).toLowerCase();
      if (key != self.toLowerCase()) return;
      final last = _loginEchoCredited[firstHop];
      if (last != null && now.difference(last) <= _attemptWindow) return;
      _loginEchoCredited[firstHop] = now;
      graph.observeOwnEcho(packet.pathBytes, packet.stride);
      appLogger.info('own login echo via $firstHop — it heard me',
          tag: 'PathGraph');
      return;
    }

    if (packet.payloadType != _payloadTypeTxtMsg) return;
    if (packet.payload.length < 2 || packet.payload[1] != myByte) return;
    // [X][X]: a contact sharing my first byte sends me the same two bytes
    // as I send them. It cannot be told apart, so it proves nothing.
    if (packet.payload[0] == myByte) return;
    _attempts.removeWhere((a) => now.difference(a.at) > _attemptWindow);
    final attempt = _attempts
        .where((a) => a.contactByte == packet.payload[0] && !a.closed)
        .lastOrNull;
    if (attempt == null || attempt.credited.contains(firstHop)) return;
    attempt.credited.add(firstHop);
    graph.observeOwnEcho(packet.pathBytes, packet.stride);
    appLogger.info(
        'own DM echo via $firstHop (attempt ${attempt.index}) — it heard me',
        tag: 'PathGraph');
  }

  void _log(String kind, String path, String verdict, double rxSnr) {
    packetLog.insert(
        0,
        PacketLogEntry(
            at: DateTime.now(),
            kind: kind,
            path: path,
            verdict: verdict,
            rxSnr: rxSnr));
    if (packetLog.length > _packetLogCap) packetLog.removeLast();
  }

  String _fmtHops(Uint8List bytes, int stride) =>
      PathHelper.getHops(bytes, stride: stride).map(PathHelper.hopHex).join(' › ');

  /// Last trace result, for the harness to display.
  ({List<String> hops, List<double> snrs})? lastTrace;
  void Function()? onTrace;

  /// Path-discovery status per contact (lowercase pubkey), for the
  /// Pathfinder screen to show under that contact.
  final Map<String, String> discoveryStatus = {};
  void Function()? onPathDiscovery;

  /// The contact we probed: the 0x8D push carries only a 6-byte prefix,
  /// and ingress attribution needs the whole key.
  _PendingDiscovery? _pendingDiscovery;

  /// Until the radio acknowledges the request; then its own estimate.
  static const Duration _discoveryAckWait = Duration(seconds: 10);

  String? get pendingDiscoveryPubkey => _liveDiscovery()?.pubkey;

  _PendingDiscovery? _liveDiscovery() {
    final p = _pendingDiscovery;
    if (p != null && DateTime.now().isAfter(p.expiresAt)) {
      _pendingDiscovery = null;
      if (discoveryStatus[p.pubkey]?.startsWith('asking') == true ||
          discoveryStatus[p.pubkey]?.startsWith('accepted') == true) {
        discoveryStatus[p.pubkey] = 'no answer — try again later';
      }
      return null;
    }
    return p;
  }

  /// Call right after the CMD 52 frame for [pubkey] is written.
  void beginDiscovery(String pubkey, String status) {
    final pk = pubkey.toLowerCase();
    _pendingDiscovery =
        _PendingDiscovery(pk, DateTime.now().add(_discoveryAckWait));
    discoveryStatus[pk] = status;
  }

  /// The request never went out, or the link dropped.
  void cancelDiscovery([String? status]) {
    final p = _pendingDiscovery;
    _pendingDiscovery = null;
    if (p != null && status != null) discoveryStatus[p.pubkey] = status;
  }

  void handleFrame(Uint8List frame) {
    if (frame.isEmpty) return;
    // The radio's answer to the discovery request itself, the first SENT
    // or ERR after it: RESP_CODE_SENT (accepted, with the estimated
    // timeout) or an error — most usefully ERR_CODE_NOT_FOUND, which means
    // the radio has no such contact in its own list (auto-add off). Later
    // ones belong to other commands.
    final pending = _liveDiscovery();
    if (pending != null && !pending.ackSeen) {
      if (frame[0] == 6 && frame.length >= 10) {
        pending.ackSeen = true;
        final estTimeout =
            ByteData.sublistView(frame, 6, 10).getUint32(0, Endian.little);
        pending.expiresAt = DateTime.now()
            .add(Duration(milliseconds: estTimeout) + const Duration(seconds: 5));
        discoveryStatus[pending.pubkey] =
            'accepted — waiting up to ${(estTimeout / 1000).round()}s for '
            'the contact to answer';
        onPathDiscovery?.call();
      } else if (frame[0] == 1) {
        final err = frame.length > 1 ? frame[1] : 0;
        discoveryStatus[pending.pubkey] = switch (err) {
          2 => 'REJECTED: contact not in the radio\'s list — add the '
              'contact on the radio first (auto-add is off)',
          3 => 'REJECTED: radio request table full — retry shortly',
          _ => 'REJECTED by radio (err $err)',
        };
        _pendingDiscovery = null;
        onPathDiscovery?.call();
      }
    }
    switch (frame[0]) {
      case pushAdvert:
      case pushNewAdvert:
        _onAdvertVerified(frame);
      case pushLogRxData:
        _handleRawRx(frame);
      case pushTraceData:
        _handleTraceData(frame);
      case pushPathDiscoveryResponse:
        _handlePathDiscovery(frame);
      case pushControlData:
        _handleControlData(frame);
    }
  }

  /// The radio answers only its own pending request (matched by tag), so
  /// both paths are this app's exchange:
  ///  * out_path is the route my flood took to them, and they answered:
  ///    its first hop heard me and its last hop reached them. One
  ///    exchange is not a tally of the corridor's links.
  ///  * in_path came back as a flood the raw feed already filed (links
  ///    and the hop I heard last); here only their doorstep is credited.
  /// The contact is the one asked only when the reply's key prefix is
  /// theirs.
  void _handlePathDiscovery(Uint8List frame) {
    final parsed = parsePathDiscovery(frame);
    if (parsed == null) return;
    final pending = _liveDiscovery();
    final contact = pending != null &&
            pending.pubkey.startsWith(parsed.pubkeyPrefix.toLowerCase())
        ? pending.pubkey
        : null;

    if (parsed.outPath.isNotEmpty) {
      graph.reportSendResult(parsed.outPath, true,
          contactPubkey: contact, stride: parsed.outStride, tally: false);
    }
    if (contact != null) {
      graph.observeContactSender(contact, parsed.inPath, parsed.inStride,
          confirmed: true);
    }

    String fmt(Uint8List p, int stride) =>
        p.isEmpty ? '(direct)' : PathHelper.formatPathHex(p, stride: stride);

    final summary = 'to ${parsed.pubkeyPrefix}: '
        'out ${fmt(parsed.outPath, parsed.outStride)} · '
        'back ${fmt(parsed.inPath, parsed.inStride)}';
    if (contact != null) {
      discoveryStatus[contact] = summary;
      _pendingDiscovery = null;
    }
    // Every event that can prove a doorstep leaves a trail: the first
    // hop of out_path is credited as hearing me.
    _log('discover path', fmt(parsed.outPath, parsed.outStride),
        'their reply: out = the route my flood took to them · back = the route their reply took', 0);
    appLogger.info(
        'path discovery $summary${contact == null ? ' (not the contact asked)' : ''}',
        tag: 'PathGraph');
    onPathDiscovery?.call();
  }

  /// Trace results are top-grade evidence: per-hop SNR in the traversal
  /// direction (round-trip paths fill both directions naturally).
  void _handleTraceData(Uint8List frame) {
    final parsed = parseTraceResponse(frame, graph.hashWidthBytes);
    if (parsed == null) return;
    if (parsed.width < graph.hashWidthBytes) {
      _log('trace', '(${parsed.width}-byte hashes)',
          'dropped — ${parsed.width}-byte hashes are too narrow to tell repeaters apart',
          parsed.snrs.isEmpty ? 0 : parsed.snrs.last);
      return;
    }
    if (parsed.hops.isEmpty) return;
    final levels = parsed.snrs.map((s) => s.toStringAsFixed(1)).join(' ');
    final tag = ByteData.sublistView(frame, 4, 8).getUint32(0, Endian.little);
    if (expectedTraceTag == null || tag != expectedTraceTag) {
      // Someone else's trace ended on a repeater I can hear: its last hop
      // reached me, at a measured level. Its first hop heard THEM, not me.
      final rx = parsed.snrs.isEmpty ? null : parsed.snrs.last;
      graph.observeRepeaterHeard(parsed.hops.last, rxSnr: rx);
      _log('trace', parsed.hops.join(','),
          'a trace that is not mine — counts as I hear its last hop only',
          rx ?? 0);
      return;
    }
    lastTrace = (hops: parsed.hops, snrs: parsed.snrs);
    _log('trace', parsed.hops.join(','),
        'first hop ${parsed.hops.first} heard me at ${levels.split(' ').first} dB · levels $levels',
        parsed.snrs.isEmpty ? 0 : parsed.snrs.last);
    appLogger.info(
        'trace ${parsed.hops.join(',')} levels $levels', tag: 'PathGraph');
    graph.observeTrace(parsed.hops, parsed.snrs);
    onTrace?.call();
  }

  /// [0x88][snr][rssi][raw packet] — 3-byte header per connector.
  void _handleRawRx(Uint8List frame) {
    if (frame.length < 4) return;
    framesSeen++;
    final rxSnr = frame[1].toSigned(8) / 4.0;
    final packet = parseRawPacket(Uint8List.sublistView(frame, 3));
    if (packet == null) {
      _log('unparsed', '', 'malformed — could not read the packet header',
          rxSnr);
      return;
    }
    final kind = packetKind(packet.payloadType);

    if (packet.payloadType == _payloadTypeTrace) {
      tracesSkipped++; // TRACE path bytes are SNRs, never hashes
      _log(
          kind,
          '(${packet.pathBytes.length} SNR bytes)',
          'skipped — a trace packet carries signal levels, not hashes; '
              'the trace result is learned from the radio\'s report instead',
          rxSnr);
      return;
    }

    // A direct packet's path is the hops still AHEAD of it; every
    // forwarder strips its own hash (Mesh.cpp removeSelfFromPath). Nothing
    // in it says who transmitted it or which links were travelled, and
    // the plan it carries is the originator's stored route — a guess some
    // app may have written. File nothing.
    if (!_isFlood(packet)) {
      _log(kind, _fmtHops(packet.pathBytes, packet.stride),
          'direct — carries the hops ahead, not the ones travelled; nothing '
          'to learn',
          rxSnr);
      return;
    }

    final edgesBefore = graph.edgeCount;
    final narrowBefore = graph.counters.droppedNarrow;
    _observe(packet, rxSnr);
    _observeOwnEcho(packet);
    _rememberFloodMessage(packet, frame[1].toSigned(8));
    _log(kind, _fmtHops(packet.pathBytes, packet.stride),
        _verdict(packet, edgesBefore, narrowBefore), rxSnr);
  }

  /// Keeps a flooded DM or room post addressed to me (the payload's first
  /// byte is my first key byte) until its decoded message arrives. Own
  /// echoes and other people's messages fail that test and are not kept.
  void _rememberFloodMessage(RawPacket packet, int snrByte) {
    final self = graph.selfPubkey;
    if (self == null || !_isFlood(packet)) return;
    if (packet.payloadType == _payloadTypeAck) {
      if (packet.payload.length < 4) return;
      final now = DateTime.now();
      _floodAcks.removeWhere((a) => now.difference(a.at) > _floodMessageWindow);
      _floodAcks.add(_FloodAck(
          now,
          ByteData.sublistView(packet.payload, 0, 4).getUint32(0, Endian.little),
          snrByte,
          packet.pathBytes,
          packet.stride));
      if (_floodAcks.length > _floodAckCap) _floodAcks.removeAt(0);
      return;
    }
    if (packet.payloadType != _payloadTypeTxtMsg &&
        packet.payloadType != _payloadTypePath) {
      return;
    }
    final myByte = int.parse(self.substring(0, 2), radix: 16);
    if (packet.payload.length < 2 || packet.payload[0] != myByte) return;
    // From a contact sharing my first byte it looks exactly like my own
    // echo to them: it says nothing about whose doorstep it crossed.
    if (packet.payload[1] == myByte) return;
    final now = DateTime.now();
    if (packet.payloadType == _payloadTypePath) {
      final until = _consumedPathReplies[packet.payload[1]];
      if (until != null && now.isBefore(until)) return;
    }
    _floodMessages.removeWhere(
        (m) => now.difference(m.at) > _floodMessageWindow);
    _floodMessages.add(_FloodMessage(now, packet.payloadType,
        packet.payload[1], snrByte, packet.pathBytes, packet.stride,
        Uint8List.fromList(packet.payload)));
    if (_floodMessages.length > _floodMessageCap) _floodMessages.removeAt(0);
  }

  /// The radio confirmed delivery to [contactPubkeyHex] with [ackHash]
  /// (uint32, as the push carries it). If the ACK came back as a flood it
  /// was logged under that hash a moment earlier, and its first hop is a
  /// repeater that heard THEM. The hash is a per-message digest, so the
  /// match is exact. A direct ACK, or one carried inside a PATH reply,
  /// leaves no flood to find.
  void attributeAck(String contactPubkeyHex, int ackHash) {
    final who = contactPubkeyHex.substring(0, 12).toUpperCase();
    final now = DateTime.now();
    // Delivered: later floods matching these bytes are not this send.
    _closeAttempts(int.parse(contactPubkeyHex.substring(0, 2), radix: 16));
    _floodAcks.removeWhere((a) => now.difference(a.at) > _floodMessageWindow);
    final matches = _floodAcks.where((a) => a.hash == ackHash).toList();
    if (matches.isEmpty) {
      _log('ack', '',
          'from $who — came back direct or inside a path reply; no flood to '
          'learn from', 0);
      return;
    }
    final first = matches.first;
    _floodAcks.removeWhere(matches.contains);
    if (!graph.observeContactSender(
        contactPubkeyHex, first.pathBytes, first.stride,
        confirmed: true)) {
      _log('ack', _fmtHops(first.pathBytes, first.stride),
          'from $who — ${_notFiled(first.pathBytes, first.stride)}',
          first.snrByte / 4.0);
      return;
    }
    messagesAttributed++;
    final others = matches.skip(1).map((m) => _fmtHops(m.pathBytes, m.stride));
    _log(
        'ack',
        _fmtHops(first.pathBytes, first.stride),
        'from $who — ${first.pathBytes.isEmpty ? "heard directly" : "its first hop heard them"}'
        '${others.isEmpty ? "" : " · also heard via ${others.join(" | ")}"}',
        first.snrByte / 4.0);
    appLogger.info(
        'flooded ack from $who via ${_fmtHops(first.pathBytes, first.stride)} '
        '— first hop credited as hearing them',
        tag: 'PathGraph');
  }

  /// The radio stored a route it was handed in a PATH reply from
  /// [contactPubkeyHex] (PATH_UPDATED). That reply was a flood from them,
  /// logged seconds earlier under their first key byte: its first hop is
  /// a repeater that heard THEM — the fact "routes back" needs, which the
  /// encrypted payload never gives the app by itself. Every logged copy is
  /// genuinely theirs; the earliest is the one the radio acted on and the
  /// one credited (field: a room's reply arrived BEEF then 1000,
  /// AD77, A277 two seconds apart).
  void attributePathReply(String contactPubkeyHex) {
    final srcHash = int.parse(contactPubkeyHex.substring(0, 2), radix: 16);
    final who = contactPubkeyHex.substring(0, 12).toUpperCase();
    final now = DateTime.now();
    final matches = _floodMessages
        .where((m) =>
            m.payloadType == _payloadTypePath &&
            m.srcHash == srcHash &&
            now.difference(m.at) <= _pathReplyWindow)
        .toList();
    if (matches.isEmpty) {
      _log('path reply', '',
          'from $who — no logged flood to match (decoded while the app '
          'was away, or sent direct)', 0);
      return;
    }
    final first = matches.first;
    // Later copies of this reply are the same reply: never a second one.
    _floodMessages.removeWhere(matches.contains);
    _consumedPathReplies[srcHash] = now.add(_pathReplyWindow);
    // A logged reply shows only the sender's first key byte: exact or
    // nothing. Copies of one reply share their payload (each first hop
    // heard them; the earliest is credited); different payloads are
    // different replies, and only one is theirs.
    final packets = {for (final m in matches) payloadFingerprint(m.payload)};
    final why = packets.length > 1
        ? '${packets.length} different replies carry that byte'
        : graph.sharesFirstByte(contactPubkeyHex)
            ? 'another contact\'s key starts with the same byte'
            : null;
    if (why != null) {
      _log('path reply', _fmtHops(first.pathBytes, first.stride),
          'from $who — $why, credited nobody', first.snrByte / 4.0);
      return;
    }
    if (!graph.observeContactSender(
        contactPubkeyHex, first.pathBytes, first.stride,
        confirmed: true)) {
      _log('path reply', _fmtHops(first.pathBytes, first.stride),
          'from $who — ${_notFiled(first.pathBytes, first.stride)}',
          first.snrByte / 4.0);
      return;
    }
    messagesAttributed++;
    final others = matches.skip(1).map((m) => _fmtHops(m.pathBytes, m.stride));
    _log(
        'path reply',
        _fmtHops(first.pathBytes, first.stride),
        'from $who — its first hop heard them'
        '${others.isEmpty ? "" : " · also heard via ${others.join(" | ")}"}',
        first.snrByte / 4.0);
    appLogger.info(
        'path reply from $who via ${_fmtHops(first.pathBytes, first.stride)} '
        '— first hop credited as hearing them',
        tag: 'PathGraph');
  }

  /// The radio decoded a DM or room post from [contactPubkeyHex] (full
  /// key) that arrived with the raw path_len byte [pathLenRaw] and the
  /// signed SNR byte [snrByte] (null on the pre-V3 frame). Finds the
  /// logged packet it came from — same sender byte, hop count, width and
  /// signal — and credits the sender's doorstep. Copies of one flood that
  /// share the first repeater are one sighting; copies that differ there
  /// are ambiguous and credit nobody. A direct message (0xFF) carries no
  /// path: the hops were stripped on the way.
  void attributeContactMessage(
      String contactPubkeyHex, int pathLenRaw, int? snrByte) {
    final hops = PathHelper.pathLenHops(pathLenRaw);
    if (hops < 0) return;
    final width = PathHelper.pathLenWidth(pathLenRaw);
    final srcHash = int.parse(contactPubkeyHex.substring(0, 2), radix: 16);
    final who = contactPubkeyHex.substring(0, 12).toUpperCase();
    final now = DateTime.now();
    _floodMessages.removeWhere(
        (m) => now.difference(m.at) > _floodMessageWindow);
    final matches = _floodMessages
        .where((m) =>
            m.payloadType == _payloadTypeTxtMsg &&
            m.srcHash == srcHash &&
            m.stride == width &&
            m.pathBytes.length ~/ width == hops &&
            (snrByte == null || m.snrByte == snrByte))
        .toList();
    if (matches.isEmpty) {
      _log('dm', '',
          'from $who — no logged packet to match (decoded while the app '
          'was away, or longer than the radio logs)', 0);
      return;
    }
    String doorstep(_FloodMessage m) =>
        PathHelper.firstHopHex(m.pathBytes, stride: m.stride) ?? '';
    final doorsteps = {for (final m in matches) doorstep(m)};
    final first = matches.first;
    if (doorsteps.length > 1) {
      _log('dm', _fmtHops(first.pathBytes, first.stride),
          'from $who — ${matches.length} logged packets could be this '
          'message and they differ on the first repeater, credited nobody',
          first.snrByte / 4.0);
      return;
    }
    _floodMessages.removeWhere(matches.contains);
    if (!graph.observeContactSender(
        contactPubkeyHex, first.pathBytes, first.stride,
        confirmed: true)) {
      _log('dm', _fmtHops(first.pathBytes, first.stride),
          'from $who — ${_notFiled(first.pathBytes, first.stride)}',
          first.snrByte / 4.0);
      return;
    }
    messagesAttributed++;
    _log(
        'dm',
        _fmtHops(first.pathBytes, first.stride),
        first.pathBytes.isEmpty
            ? 'attributed — $who reached me with no repeater between us'
            : 'attributed — $who heard by ${doorstep(first)}',
        first.snrByte / 4.0);
  }

  String _verdict(RawPacket packet, int edgesBefore, int narrowBefore) {
    if (graph.counters.droppedNarrow > narrowBefore) {
      return 'dropped — ${packet.stride}-byte hashes, the graph needs '
          '${graph.hashWidthBytes}';
    }
    if (packet.pathBytes.isEmpty) return 'direct — no repeater in the path';
    if (packet.pathBytes.length % packet.stride != 0) {
      return 'malformed — path is not a whole number of hops';
    }
    if (packet.pathBytes.length ~/ packet.stride == 1) {
      return 'recorded — one repeater, no link to learn';
    }
    final added = graph.edgeCount - edgesBefore;
    return added > 0
        ? 'recorded — $added new link${added == 1 ? "" : "s"}'
        : 'recorded — links already known';
  }

  void _observe(RawPacket packet, double rxSnr) {
    if (packet.payloadType == _payloadTypeAdvert) {
      final advert = parseAdvert(packet.payload);
      // My own advert gets no push (the firmware ignores its own key); it
      // is filed as an echo of my flood, as before.
      if (advert != null && advert.pubkeyHex == graph.selfPubkey) {
        graph.observePath(packet.pathBytes, packet.stride,
            ObservationOrigin.pubkeyConfirmed(advert.pubkeyHex),
            rxSnr: rxSnr, messageId: payloadFingerprint(packet.payload));
        return;
      }
      if (advert != null) _holdAdvert(advert, packet);
    }

    // Every path, adverts included: anonymous edge harvest (paths are cleartext even
    // when payloads aren't decryptable). Attribution upgrades (channel
    // name resolution, DM correlation) come later in the harness.
    graph.observePath(packet.pathBytes, packet.stride,
        const ObservationOrigin.anonymous(),
        rxSnr: rxSnr, messageId: payloadFingerprint(packet.payload));
  }

  /// Adverts logged but not yet verified, by pubkey: the path is already
  /// filed as an anonymous corridor; who sent it waits for the radio.
  final Map<String, List<_HeldAdvert>> _heldAdverts = {};

  /// Payloads the radio verified, by pubkey: later flood copies of the
  /// same advert (the radio drops duplicates without a second push) are
  /// attributed when their bytes match exactly.
  final Map<String, ({Uint8List payload, DateTime at})> _verifiedAdverts = {};
  static const Duration _advertVerifyWindow = Duration(seconds: 5);
  static const Duration _advertCopyWindow = Duration(seconds: 60);

  void _holdAdvert(ParsedAdvert advert, RawPacket packet) {
    final key = advert.pubkeyHex;
    final now = DateTime.now();
    final verified = _verifiedAdverts[key];
    if (verified != null &&
        now.difference(verified.at) <= _advertCopyWindow &&
        _sameBytes(verified.payload, packet.payload)) {
      _attributeAdvert(advert, packet);
      return;
    }
    _heldAdverts.removeWhere((_, held) =>
        held.every((h) => now.difference(h.at) > _advertVerifyWindow));
    (_heldAdverts[key] ??= []).add(_HeldAdvert(now, advert, packet));
  }

  /// [PUSH_CODE_ADVERT][pubkey ×32] or [PUSH_CODE_NEW_ADVERT][contact…]:
  /// the radio checked the signature (and that it is not a replay).
  void _onAdvertVerified(Uint8List frame) {
    if (frame.length < 33) return;
    final key = _hex(frame.sublist(1, 33)).toLowerCase();
    final held = _heldAdverts.remove(key);
    if (held == null) return;
    final now = DateTime.now();
    final fresh =
        held.where((h) => now.difference(h.at) <= _advertVerifyWindow).toList();
    if (fresh.isEmpty) return;
    // The radio verified one advert; copies with other bytes are not it.
    final payload = fresh.first.packet.payload;
    _verifiedAdverts[key] = (payload: Uint8List.fromList(payload), at: now);
    if (_verifiedAdverts.length > 64) {
      _verifiedAdverts.remove(_verifiedAdverts.keys.first);
    }
    for (final h in fresh) {
      if (_sameBytes(payload, h.packet.payload)) {
        _attributeAdvert(h.advert, h.packet);
      }
    }
  }

  void _attributeAdvert(ParsedAdvert advert, RawPacket packet) {
    if (advert.type == _advTypeRepeater || advert.type == _advTypeRoom) {
      graph.ingestNode(advert.nodeHash(graph.hashWidthBytes),
          name: advert.name,
          pubkey: advert.pubkeyHex,
          lat: advert.lat,
          lon: advert.lon);
    } else if (advert.type == _advTypeChat && advert.name != null) {
      graph.ingestContact(advert.pubkeyHex, advert.name!);
    }
    graph.observeContactSender(
        advert.pubkeyHex, packet.pathBytes, packet.stride, confirmed: true);
  }

  static bool _sameBytes(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Wire layout (verified against the connector's own handler):
  ///   [0x8E][our RX snr][rssi][path_len][ctl payload…]
  /// ctl payload: [type|node_type][UPLINK snr][tag ×4][pubkey…]
  /// Byte 1 of the payload is the firmware's "let sender know the
  /// inbound SNR" — how well the repeater heard US, which is the
  /// ranking signal we want (the app currently discards it).
  void _handleControlData(Uint8List frame) {
    if (frame.length < 11) return;
    final ctl = frame.sublist(4);
    if (ctl[0] & 0xF0 != _ctlNodeDiscoverResp) return;
    if (ctl[0] & 0x0F != _advTypeRepeater) return;
    final uplinkSnr = ctl[1].toSigned(8) / 4.0;
    final rxSnr = frame[1].toSigned(8) / 4.0; // how well WE heard them
    final pubkey = ctl.sublist(6);
    if (pubkey.length < graph.hashWidthBytes) return;
    final hash = PathHelper.hopHex(
        PathHelper.pubKeyPrefix(pubkey, stride: graph.hashWidthBytes));
    // Replies are zero-hop, so every one a radio hears is pushed to the
    // app — including answers to OTHER people's requests. Only the tag
    // says whose request a repeater heard; without it a mountaintop
    // answering a neighbour at +11 dB is filed as hearing ME at +11 dB.
    final tag = ByteData.sublistView(ctl, 2, 6).getUint32(0, Endian.little);
    if (expectedDiscoverTag == null || tag != expectedDiscoverTag) {
      // Still worth something: its zero-hop reply reached me, so I hear
      // it, at a measured level. Not a word about it hearing me.
      graph.observeRepeaterHeard(hash, rxSnr: rxSnr);
      _log('discover reply', hash,
          'answering a request that is not mine — counts as I hear it only',
          rxSnr);
      return;
    }
    pendingDiscover.add(DiscoverResponse(
        repeaterHash: hash, uplinkSnr: uplinkSnr, rxSnr: rxSnr));
    // The full key prefix tells two repeaters sharing a short hash apart.
    final key = _hex(pubkey.sublist(0, pubkey.length < 8 ? pubkey.length : 8));
    final verdict = 'heard my request at ${uplinkSnr.toStringAsFixed(1)} dB · '
        'key $key · hops on arrival ${frame[3]}';
    _log('discover reply', hash, verdict, rxSnr);
    appLogger.info('discover reply $hash $verdict · I heard it at '
        '${rxSnr.toStringAsFixed(1)} dB', tag: 'PathGraph');
  }

  /// Harness calls this when the discover window closes.
  void commitDiscover({required bool failureEpisode}) {
    graph.observeDiscoverResults(List.of(pendingDiscover),
        failureEpisode: failureEpisode);
    pendingDiscover.clear();
  }
}
