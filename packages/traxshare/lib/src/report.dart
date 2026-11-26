import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'track.dart';
import 'trail.dart';

/// The channel datagram type, in MeshTrax's block 0170–017F of the
/// firmware's docs/number_allocations.md (meshcore-dev/MeshCore#3925).
const traxshareDataType = 0x0171;

/// What a member goes by, as the trip sees them on the map. A report
/// carries it in the low 4 bits of byte 28: 0 is [hike], as builds before
/// test build 243 send, and one this build doesn't know is [hike] too.
/// New ones go at the end.
enum TraxMapIcon { hike, vehicle, boat, motorcycle, bicycle, aircraft, camp }

/// A member's location, as version 1's REPORT (subtype 2) carries it. The
/// layout is version 1 of the closed location-sharing plan (#240); later
/// fields add to it rather than replace it. How TRAX uses it:
/// docs/technical/trax-mode.md.
///
/// 29 bytes: a 12-byte header (version and subtype, seq, sender prefix,
/// session, sent at), then the field mask, the position, the fix age,
/// heading, speed, altitude, battery, and the icon in the low 4 bits of the
/// last byte (the high 4 are free). Multi-byte numbers are little-endian. The sender's name may follow, then pieces of their track
/// ([TrackBlock]), all within [maxSize].
class TraxReport {
  const TraxReport({
    required this.seq,
    required this.senderPrefix,
    required this.session,
    required this.sentAt,
    required this.lat,
    required this.lon,
    this.altitude,
    this.heading,
    this.speed,
    this.stillFor,
    this.fixAge,
    this.battery,
    this.mayBeOld = false,
    this.requester = false,
    this.icon = TraxMapIcon.hike,
    this.name,
    this.track,
  });

  static const version = 1;
  static const subtype = 2;

  /// The size without a trail or a name: the largest at its airtime cost.
  static const size = 29;

  /// The most a report may take, a track and a name included.
  static const maxSize = 157;

  /// The longest name carried, in UTF-8 bytes.
  static const maxNameBytes = 20;

  static const _headingBit = 1 << 0;
  static const _speedBit = 1 << 1;
  static const _altitudeBit = 1 << 2;
  static const _fixAgeBit = 1 << 3;
  static const _movingBit = 1 << 4;
  static const _requesterBit = 1 << 5;
  static const _batteryBit = 1 << 6;

  /// A trail, as builds before test build 243 sent it, where the name is
  /// now: such a report's name isn't read.
  static const _trailBit = 1 << 10;
  static const _mayBeOldBit = 1 << 11;
  static const _stillBit = 1 << 12;
  static const _trackBit = 1 << 13;
  static const _extensionBit = 1 << 15;
  static const _nameTag = 1;

  /// Per sender, +1 on every send; wraps at 256.
  final int seq;

  /// The first 4 bytes of the sender's public key: a claim, not proof,
  /// since anyone holding the channel key can send.
  final Uint8List senderPrefix;

  /// A random u16, new for each TRAX session.
  final int session;

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

  /// Since the radio's reading last changed; null when unknown.
  final Duration? fixAge;

  /// The radio's battery, 0–100 %.
  final int? battery;

  /// No change in the radio's reading has been seen lately: it may be a
  /// stored position, not a live fix.
  final bool mayBeOld;

  /// Sent by the session's requester; a TRAX beacon is its own session.
  final bool requester;

  final TraxMapIcon icon;

  /// The sender's radio name, for members who aren't a contact.
  final String? name;

  /// The way the sender came: their trail ([fitTrack]) or one older piece
  /// of their track, in no more than [trackRoom].
  final TrackBlock? track;

  /// The bytes a track may take beside [name].
  static int trackRoom({String? name}) {
    final cut = name == null ? 0 : _cut(name).length;
    return maxSize - size - (cut == 0 ? 0 : 3 + cut);
  }

  /// The report as sent. [random] fills a saturated fix age, so a parked
  /// radio's reports don't repeat a whole cipher block.
  Uint8List encode({Random? random}) {
    final cut = name == null ? null : _cut(name!);
    final nameBytes = cut == null || cut.isEmpty ? null : cut;
    final track = this.track;
    final trackBytes = track == null || track.pieces.isEmpty
        ? null
        : track.encode(wirePosition(lat, lon));
    final at = size + (nameBytes == null ? 0 : 3 + nameBytes.length);
    final out = Uint8List(at + (trackBytes?.length ?? 0));
    final data = ByteData.sublistView(out);
    var mask = 0;
    if (altitude != null) mask |= _altitudeBit;
    if (heading != null) mask |= _headingBit | _movingBit;
    if (speed != null) mask |= _speedBit | _movingBit;
    if (stillFor != null && heading == null && speed == null) {
      mask |= _stillBit;
    }
    if (requester) mask |= _requesterBit;
    if (battery != null) mask |= _batteryBit;
    if (mayBeOld) mask |= _mayBeOldBit;
    if (trackBytes != null) mask |= _trackBit;
    if (nameBytes != null) mask |= _extensionBit;
    final ageSeconds = fixAge?.inSeconds;
    if (ageSeconds != null && ageSeconds >= 0xFFFF) {
      mask |= _mayBeOldBit;
      final r = random ?? Random.secure();
      out[21] = r.nextInt(256);
      out[22] = r.nextInt(256);
    } else if (ageSeconds != null) {
      mask |= _fixAgeBit;
      data.setUint16(21, max(ageSeconds, 0), Endian.little);
    }

    out[0] = version << 4 | subtype;
    out[1] = seq & 0xFF;
    out.setRange(2, 6, senderPrefix);
    data.setUint16(6, session & 0xFFFF, Endian.little);
    data.setUint32(8, sentAt.millisecondsSinceEpoch ~/ 1000, Endian.little);
    data.setUint16(12, mask, Endian.little);
    // Accuracy class 0, as the radio reports it, in the low 5 bits.
    _putBits(out, 14, 5, 26, lonUnits(lon));
    _putBits(out, 14, 31, 25, latUnits(lat));
    if (heading case final h?) out[23] = (h * 256 / 360).round() % 256;
    if (speed case final v?) out[24] = (v / 0.5).round().clamp(0, 255);
    if (mask & _stillBit != 0) out[24] = stillFor!.inMinutes.clamp(0, 255);
    if (altitude != null) {
      data.setInt16(25, altitude!.clamp(-32768, 32767), Endian.little);
    }
    if (battery != null) out[27] = battery!.clamp(0, 100);
    out[28] = icon.index;
    if (nameBytes != null) {
      out[size] = 2 + nameBytes.length;
      out[size + 1] = _nameTag;
      out[size + 2] = nameBytes.length;
      out.setRange(size + 3, at, nameBytes);
    }
    if (trackBytes != null) out.setRange(at, out.length, trackBytes);
    return out;
  }

  /// A version 1 REPORT, or null for anything else or a malformed one.
  static TraxReport? decode(Uint8List data) {
    if (data.length < size) return null;
    if (data[0] >> 4 != version || data[0] & 0x0F != subtype) return null;
    final d = ByteData.sublistView(data);
    final mask = d.getUint16(12, Endian.little);
    final latU = _getBits(data, 14, 31, 25);
    final lonU = _getBits(data, 14, 5, 26);
    if (latU > 18000000 || lonU >= 36000000) return null;
    final lat = latU / 100000 - 90, lon = lonU / 100000 - 180;
    final sentAt = DateTime.fromMillisecondsSinceEpoch(
      d.getUint32(8, Endian.little) * 1000,
      isUtc: true,
    );
    String? name;
    var at = size;
    if (mask & _extensionBit != 0 && mask & _trailBit == 0) {
      name = _readName(data, at);
      if (data.length > at) at += 1 + data[at];
    }
    TrackBlock? track;
    if (mask & _trackBit != 0) {
      final read = TrackBlock.decode((lat: lat, lon: lon), sentAt, data, at);
      if (read == null) return null;
      track = read.block;
    }
    final battery = data[27];
    return TraxReport(
      seq: data[1],
      senderPrefix: Uint8List.fromList(data.sublist(2, 6)),
      session: d.getUint16(6, Endian.little),
      sentAt: sentAt,
      lat: lat,
      lon: lon,
      altitude: mask & _altitudeBit != 0 ? d.getInt16(25, Endian.little) : null,
      heading: mask & _headingBit != 0 ? data[23] * 360 / 256 : null,
      speed: mask & _speedBit != 0 ? data[24] * 0.5 : null,
      stillFor: mask & (_stillBit | _speedBit) == _stillBit
          ? Duration(minutes: data[24])
          : null,
      fixAge: mask & _fixAgeBit != 0
          ? Duration(seconds: d.getUint16(21, Endian.little))
          : null,
      battery: mask & _batteryBit != 0 && battery <= 100 ? battery : null,
      mayBeOld: mask & _mayBeOldBit != 0,
      requester: mask & _requesterBit != 0,
      icon:
          TraxMapIcon.values.elementAtOrNull(data[28] & 0x0F) ??
          TraxMapIcon.hike,
      name: name,
      track: track,
    );
  }

  /// [s] in UTF-8, cut at a character boundary to [maxNameBytes].
  static Uint8List _cut(String s) {
    final out = BytesBuilder();
    for (final rune in s.runes) {
      final bytes = utf8.encode(String.fromCharCode(rune));
      if (out.length + bytes.length > maxNameBytes) break;
      out.add(bytes);
    }
    return out.toBytes();
  }

  /// Tag 1 from the extension block at [at]; unknown tags are skipped.
  static String? _readName(Uint8List data, int at) {
    if (data.length <= at) return null;
    final end = at + 1 + data[at];
    if (end > data.length) return null;
    var i = at + 1;
    while (i + 2 <= end) {
      final tag = data[i], length = data[i + 1];
      if (i + 2 + length > end) return null;
      if (tag == _nameTag) {
        if (length == 0) return null;
        return utf8.decode(
          data.sublist(i + 2, i + 2 + length),
          allowMalformed: true,
        );
      }
      i += 2 + length;
    }
    return null;
  }

  // Bit by bit, so the 56-bit position never needs more than 32-bit
  // arithmetic, which is all a web build has.
  static void _putBits(Uint8List b, int start, int offset, int width, int v) {
    for (var i = 0; i < width; i++) {
      if ((v >> i) & 1 == 0) continue;
      final p = offset + i;
      b[start + (p >> 3)] |= 1 << (p & 7);
    }
  }

  static int _getBits(Uint8List b, int start, int offset, int width) {
    var v = 0;
    for (var i = 0; i < width; i++) {
      final p = offset + i;
      if ((b[start + (p >> 3)] >> (p & 7)) & 1 == 1) v |= 1 << i;
    }
    return v;
  }
}
