import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:traxproto/traxproto.dart';

import 'header.dart';
import 'track.dart';
import 'trail.dart';

/// The channel datagram type, in MeshTrax's block 0170–017F of the
/// firmware's docs/number_allocations.md (meshcore-dev/MeshCore#3925).
const traxshareDataType = 0x0171;

/// What a member goes by, as the trip sees them on the map: byte 22 of a
/// report. One this build doesn't know is [hike]. New ones go at the end.
enum TraxMapIcon { hike, vehicle, boat, motorcycle, bicycle, aircraft, camp }

/// A member's location, as TRAX version 2's REPORT (kind 1) carries it. How
/// TRAX uses it: docs/technical/trax-mode.md.
///
/// 23 fixed bytes: the [TraxHeader], the flags (bit 0 moving, bit 1 still,
/// bit 2 may be old; bits 3–7 spare), latitude and longitude ([lat24],
/// [lon24]), seq, heading, speed or minutes still, altitude, battery and
/// icon. Multi-byte numbers are little-endian. Then [TraxReportGrowth]
/// (meshtrax.proto): the sender's name and build, and pieces of their track
/// ([TrackBlock]), all within [maxSize].
class TraxReport {
  const TraxReport({
    required this.seq,
    required this.senderPrefix,
    required this.sentAt,
    required this.lat,
    required this.lon,
    this.altitude,
    this.heading,
    this.speed,
    this.stillFor,
    this.battery,
    this.mayBeOld = false,
    this.icon = TraxMapIcon.hike,
    this.name,
    this.build,
    this.track,
  });

  static const version = 2;
  static const kind = 1;

  /// The fixed bytes. With the channel's 3 bytes of framing they fill 2
  /// cipher blocks, with 6 to spare.
  static const size = 23;

  /// The most a report may take, a track and a name included.
  static const maxSize = 157;

  /// The longest name carried, in UTF-8 bytes.
  static const maxNameBytes = 20;

  static const _movingBit = 1 << 0;
  static const _stillBit = 1 << 1;
  static const _mayBeOldBit = 1 << 2;
  static const _noAltitude = -32768;
  static const _noBattery = 255;

  /// Per sender, +1 on every send; wraps at 256.
  final int seq;

  /// The first 4 bytes of the sender's public key: a claim, not proof,
  /// since anyone holding the channel key can send.
  final Uint8List senderPrefix;

  /// The sender's phone clock, in whole seconds.
  final DateTime sentAt;

  final double lat;
  final double lon;

  /// Metres.
  final int? altitude;

  /// Degrees clockwise from north, while moving; 1.4° steps on the air.
  final double? heading;

  /// Metres a second, while moving; 0.5 m/s steps, 127.5 at most.
  final double? speed;

  /// How long since the sender last moved, while not moving; whole
  /// minutes, 255 at most.
  final Duration? stillFor;

  /// The radio's battery, 0–100 %.
  final int? battery;

  /// No change in the radio's reading has been seen lately: it may be a
  /// stored position, not a live fix.
  final bool mayBeOld;

  final TraxMapIcon icon;

  /// The sender's radio name, for members who aren't a contact.
  final String? name;

  /// The sender's app build.
  final int? build;

  /// The way the sender came: their trail ([fitTrack]) or one older piece
  /// of their track, in no more than [trackRoom].
  final TrackBlock? track;

  /// The bytes a track may take beside [name] and [build].
  static int trackRoom({String? name, int? build}) {
    final beside = _growth(name, build, null).encode().length;
    // The track's tag, then its length: 1 byte up to 127, else 2.
    final left = maxSize - size - beside - 1;
    return left <= 128 ? left - 1 : max(left - 2, 127);
  }

  Uint8List encode() {
    final track = this.track;
    final growth = _growth(
      name,
      build,
      track == null || track.pieces.isEmpty
          ? null
          : track.encode(wirePosition(lat, lon)),
    ).encode();
    final out = Uint8List(size + growth.length);
    final data = ByteData.sublistView(out);
    final moving = heading != null || speed != null;
    final still = !moving && stillFor != null;
    out.setRange(
      0,
      TraxHeader.size,
      TraxHeader(
        version: version,
        kind: kind,
        senderPrefix: senderPrefix,
        sentAt: sentAt,
      ).encode(),
    );
    out[9] =
        (moving ? _movingBit : 0) |
        (still ? _stillBit : 0) |
        (mayBeOld ? _mayBeOldBit : 0);
    _put24(data, 10, lat24(lat));
    _put24(data, 13, lon24(lon));
    out[16] = seq & 0xFF;
    if (heading case final h?) out[17] = (h * 256 / 360).round() % 256;
    if (speed case final v?) out[18] = (v / 0.5).round().clamp(0, 255);
    if (still) out[18] = stillFor!.inMinutes.clamp(0, 255);
    data.setInt16(
      19,
      altitude?.clamp(-32767, 32767) ?? _noAltitude,
      Endian.little,
    );
    out[21] = battery?.clamp(0, 100) ?? _noBattery;
    out[22] = icon.index;
    out.setRange(size, out.length, growth);
    return out;
  }

  /// A version 2 REPORT, or null for anything else or a malformed one: a
  /// tail that doesn't parse, or a track that doesn't read to its end.
  static TraxReport? decode(Uint8List data) {
    final header = TraxHeader.decode(data);
    if (header == null ||
        header.version != version ||
        header.kind != kind ||
        data.length < size) {
      return null;
    }
    final growth = TraxReportGrowth.decode(Uint8List.sublistView(data, size));
    if (growth == null) return null;
    final d = ByteData.sublistView(data);
    final at = positionOf(_get24(d, 10), _get24(d, 13));
    TrackBlock? track;
    if (growth.track.isNotEmpty) {
      final read = TrackBlock.decode(at, header.sentAt, growth.track, 0);
      if (read == null || read.bytes != growth.track.length) return null;
      track = read.block;
    }
    final flags = data[9];
    final moving = flags & _movingBit != 0;
    final altitude = d.getInt16(19, Endian.little);
    final battery = data[21];
    return TraxReport(
      seq: data[16],
      senderPrefix: header.senderPrefix,
      sentAt: header.sentAt,
      lat: at.lat,
      lon: at.lon,
      altitude: altitude == _noAltitude ? null : altitude,
      heading: moving ? data[17] * 360 / 256 : null,
      speed: moving ? data[18] * 0.5 : null,
      stillFor: !moving && flags & _stillBit != 0
          ? Duration(minutes: data[18])
          : null,
      battery: battery <= 100 ? battery : null,
      mayBeOld: flags & _mayBeOldBit != 0,
      icon: TraxMapIcon.values.elementAtOrNull(data[22]) ?? TraxMapIcon.hike,
      name: growth.name.isEmpty ? null : growth.name,
      build: growth.build == 0 ? null : growth.build,
      track: track,
    );
  }

  static TraxReportGrowth _growth(String? name, int? build, Uint8List? track) =>
      TraxReportGrowth(
        name: name == null ? '' : _cut(name),
        build: build ?? 0,
        track: track,
      );

  /// [s] cut at a character boundary to [maxNameBytes] of UTF-8.
  static String _cut(String s) {
    final out = StringBuffer();
    var bytes = 0;
    for (final rune in s.runes) {
      final char = String.fromCharCode(rune);
      bytes += utf8.encode(char).length;
      if (bytes > maxNameBytes) break;
      out.write(char);
    }
    return out.toString();
  }

  static void _put24(ByteData d, int at, int v) {
    d.setUint16(at, v & 0xFFFF, Endian.little);
    d.setUint8(at + 2, v >> 16);
  }

  static int _get24(ByteData d, int at) =>
      d.getUint16(at, Endian.little) | d.getUint8(at + 2) << 16;
}
