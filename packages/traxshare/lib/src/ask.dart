import 'dart:typed_data';

import 'package:traxproto/traxproto.dart';

import 'header.dart';
import 'report.dart';
import 'track.dart';

/// Asks a member's MeshTrax for the pieces of their track this phone lacks:
/// TRAX version 2's ASK (kind 2), on the trip channel like the reports. The
/// member's phone answers with a report carrying its trail, then each piece
/// not in [have], a few seconds apart.
///
/// 15 fixed bytes and 2 per piece held: the [TraxHeader], the flags (all 8
/// spare), the first 4 bytes of the member's key, the number held, then each
/// one's minute (low 16 bits, little-endian). Then [TraxAskGrowth]
/// (meshtrax.proto), with nothing in it yet.
class TraxAsk {
  const TraxAsk({
    required this.senderPrefix,
    required this.sentAt,
    required this.target,
    this.have = const [],
  });

  static const kind = 2;

  /// As many pieces as one ask can say it holds; the member sends older
  /// ones again.
  static const maxHave = 71;

  static const _fixed = 15;

  /// The first 4 bytes of the asker's key.
  final Uint8List senderPrefix;

  /// The asker's phone clock, in whole seconds.
  final DateTime sentAt;

  /// The first 4 bytes of the key of the member asked.
  final Uint8List target;

  /// The minutes of the member's pieces the asker holds at their finest,
  /// newest first.
  final List<int> have;

  Uint8List encode() {
    final have = this.have.take(maxHave).toList();
    final growth = TraxAskGrowth().encode();
    final end = _fixed + 2 * have.length;
    final out = Uint8List(end + growth.length);
    final data = ByteData.sublistView(out);
    out.setRange(
      0,
      TraxHeader.size,
      TraxHeader(
        version: TraxReport.version,
        kind: kind,
        senderPrefix: senderPrefix,
        sentAt: sentAt,
      ).encode(),
    );
    out.setRange(10, 14, target);
    out[14] = have.length;
    for (var i = 0; i < have.length; i++) {
      data.setUint16(_fixed + 2 * i, have[i] & 0xFFFF, Endian.little);
    }
    out.setRange(end, out.length, growth);
    return out;
  }

  /// A version 2 ask, or null for anything else or a malformed one. Each
  /// minute held is the latest with its low 16 bits at or before [sentAt].
  static TraxAsk? decode(Uint8List data) {
    final header = TraxHeader.decode(data);
    if (header == null ||
        header.version != TraxReport.version ||
        header.kind != kind ||
        data.length < _fixed) {
      return null;
    }
    final end = _fixed + 2 * data[14];
    if (data.length < end ||
        TraxAskGrowth.decode(Uint8List.sublistView(data, end)) == null) {
      return null;
    }
    final view = ByteData.sublistView(data);
    final sent = TrackPiece.minuteOf(header.sentAt);
    return TraxAsk(
      senderPrefix: header.senderPrefix,
      sentAt: header.sentAt,
      target: Uint8List.fromList(data.sublist(10, 14)),
      have: [
        for (var at = _fixed; at < end; at += 2)
          sent - ((sent - view.getUint16(at, Endian.little)) & 0xFFFF),
      ],
    );
  }
}
