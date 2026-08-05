// path_lab frame adapter — ALL low-level packet parsing for the
// verification harness lives here, NOT in the path_graph module and NOT
// (yet) in the app. At Phase 3 this file's parsers migrate into the
// connector unchanged. Wire layouts verified against MeshCore firmware
// (Packet.h, AdvertDataHelpers.h, simple_repeater/MyMesh.cpp) and
// docs/meshcore-protocol.md.

import 'dart:typed_data';

import 'package:path_graph/path_graph.dart';

// Packet header (Packet.h).
const int _phRouteMask = 0x03;
const int _phTypeShift = 2;
const int _phTypeMask = 0x0F;
const int _routeTransportFlood = 0x00;
const int _routeTransportDirect = 0x03;

const int _payloadTypeAdvert = 0x04;
const int _payloadTypeTrace = 0x09;

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
const int pushLogRxData = 0x88;
const int pushTraceData = 0x89;
const int pushControlData = 0x8E;
const int _ctlNodeDiscoverResp = 0x90;

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
  final routeType = header & _phRouteMask;
  if (routeType == _routeTransportFlood || routeType == _routeTransportDirect) {
    i += 4;
  }
  if (i >= raw.length) return null;
  final pathLenRaw = raw[i++];
  final stride = (pathLenRaw >> 6) + 1;
  final pathByteLen = (pathLenRaw & 0x3F) * stride;
  if (i + pathByteLen > raw.length) return null;
  final path = Uint8List.sublistView(raw, i, i + pathByteLen);
  i += pathByteLen;
  return RawPacket(routeType, (header >> _phTypeShift) & _phTypeMask, stride,
      path, Uint8List.sublistView(raw, i));
}

class ParsedAdvert {
  ParsedAdvert(this.pubkeyHex, this.type, this.name, this.lat, this.lon);
  final String pubkeyHex;
  final int type;
  final String? name;
  final double? lat;
  final double? lon;
}

/// pubkey(32) + timestamp(4) + signature(64) + app_data (flags, latlon?,
/// feats?, name). Signature NOT verified here — the firmware already
/// verified it before forwarding (Mesh.cpp advert case).
ParsedAdvert? parseAdvert(Uint8List payload) {
  if (payload.length < 32 + 4 + 64 + 1) return null;
  final pubkey = _hex(payload.sublist(0, 32));
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
    name = String.fromCharCodes(payload.sublist(i));
  }
  return ParsedAdvert(pubkey, flags & _advTypeMask, name, lat, lon);
}

/// Trace response (0x89):
/// [code][reserved][path_len][flag][tag x4][auth x4][path][snr per hop]
/// Each SNR byte is signed, quarter-dB: the level at which that hop
/// heard the *previous* transmission (snr[0] = hop 1 heard us).
({List<String> hops, List<double> snrs})? parseTraceResponse(
    Uint8List frame, int stride) {
  if (frame.length < 12) return null;
  final pathLen = frame[2];
  const headerLen = 12;
  if (headerLen + pathLen > frame.length) return null;
  final pathBytes = frame.sublist(headerLen, headerLen + pathLen);
  final hops = <String>[];
  for (var i = 0; i + stride <= pathBytes.length; i += stride) {
    hops.add(_hex(pathBytes.sublist(i, i + 2))); // 2-byte bucket
  }
  final snrs = frame
      .sublist(headerLen + pathLen)
      .map((b) => b.toSigned(8) / 4.0)
      .toList();
  return (hops: hops, snrs: snrs);
}

/// Feeds parsed frames into the module. The harness owns windowing of
/// discover responses (they arrive one push per responder).
class PathLabAdapter {
  PathLabAdapter(this.graph);

  final PathGraph graph;
  final List<DiscoverResponse> pendingDiscover = [];
  int framesSeen = 0;
  int tracesSkipped = 0;

  /// Last trace result, for the harness to display.
  ({List<String> hops, List<double> snrs})? lastTrace;
  void Function()? onTrace;

  void handleFrame(Uint8List frame) {
    if (frame.isEmpty) return;
    switch (frame[0]) {
      case pushLogRxData:
        _handleRawRx(frame);
      case pushTraceData:
        _handleTraceData(frame);
      case pushControlData:
        _handleControlData(frame);
    }
  }

  /// Trace results are top-grade evidence: per-hop SNR in the traversal
  /// direction (round-trip paths fill both directions naturally).
  void _handleTraceData(Uint8List frame) {
    final parsed = parseTraceResponse(frame, graph.selfStride);
    if (parsed == null || parsed.hops.isEmpty) return;
    lastTrace = parsed;
    graph.observeTrace(parsed.hops, parsed.snrs);
    onTrace?.call();
  }

  /// [0x88][snr][rssi][raw packet] — 3-byte header per connector.
  void _handleRawRx(Uint8List frame) {
    if (frame.length < 4) return;
    framesSeen++;
    final rxSnr = frame[1].toSigned(8) / 4.0;
    final packet = parseRawPacket(Uint8List.sublistView(frame, 3));
    if (packet == null) return;

    if (packet.payloadType == _payloadTypeTrace) {
      tracesSkipped++; // TRACE path bytes are SNRs, never hashes
      return;
    }

    if (packet.payloadType == _payloadTypeAdvert) {
      final advert = parseAdvert(packet.payload);
      if (advert != null) {
        if (advert.type == _advTypeRepeater || advert.type == _advTypeRoom) {
          graph.ingestNode(advert.pubkeyHex.substring(0, 4),
              name: advert.name,
              pubkey: advert.pubkeyHex,
              lat: advert.lat,
              lon: advert.lon);
        } else if (advert.type == _advTypeChat && advert.name != null) {
          graph.ingestContact(advert.pubkeyHex, advert.name!);
        }
        // The advert's own path is a normal RF-heard observation with
        // cryptographic attribution.
        graph.observePath(packet.pathBytes, packet.stride,
            ObservationOrigin.pubkeyConfirmed(advert.pubkeyHex),
            rxSnr: rxSnr,
            messageId: payloadFingerprint(packet.payload));
        return;
      }
    }

    // Everything else: anonymous edge harvest (paths are cleartext even
    // when payloads aren't decryptable). Attribution upgrades (channel
    // name resolution, DM correlation) come later in the harness.
    graph.observePath(packet.pathBytes, packet.stride,
        const ObservationOrigin.anonymous(),
        rxSnr: rxSnr, messageId: payloadFingerprint(packet.payload));
  }

  /// [0x8E][ctl_type|node_type][uplink SNR ×4][tag ×4][pubkey ...]
  /// (simple_repeater handleDiscoverReq response layout).
  void _handleControlData(Uint8List frame) {
    if (frame.length < 8) return;
    if (frame[1] & 0xF0 != _ctlNodeDiscoverResp) return;
    final uplinkSnr = frame[2].toSigned(8) / 4.0;
    final pubkey = frame.sublist(7);
    if (pubkey.length < 2) return;
    pendingDiscover.add(DiscoverResponse(
        repeaterHash: _hex(pubkey.sublist(0, 2)), uplinkSnr: uplinkSnr));
  }

  /// Harness calls this when the discover window closes.
  void commitDiscover({required bool failureEpisode}) {
    graph.observeDiscoverResults(List.of(pendingDiscover),
        failureEpisode: failureEpisode);
    pendingDiscover.clear();
  }
}
