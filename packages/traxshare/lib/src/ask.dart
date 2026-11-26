import 'dart:typed_data';

import 'report.dart';
import 'track.dart';

/// Asks a member's MeshTrax for the pieces of their track this phone lacks:
/// version 1, subtype 3, on the trip channel like the reports. The member's
/// phone answers with a report carrying its trail, then each piece not in
/// [have], a few seconds apart.
///
/// 17 bytes and 2 per piece held: the reports' 12-byte header, the first 4
/// bytes of the member's key, the number held, then each one's minute (low
/// 16 bits, little-endian).
class TraxAsk {
  const TraxAsk({
    required this.seq,
    required this.senderPrefix,
    required this.session,
    required this.sentAt,
    required this.target,
    this.have = const [],
  });

  static const subtype = 3;

  /// As many pieces as one ask can say it holds; the member sends older
  /// ones again.
  static const maxHave = 70;

  static const _fixed = 17;

  final int seq;

  /// The first 4 bytes of the asker's key.
  final Uint8List senderPrefix;
  final int session;

  /// The asker's phone clock, in whole seconds.
  final DateTime sentAt;

  /// The first 4 bytes of the key of the member asked.
  final Uint8List target;

  /// The minutes of the member's pieces the asker holds at their finest,
  /// newest first.
  final List<int> have;

  Uint8List encode() {
    final have = this.have.take(maxHave).toList();
    final out = Uint8List(_fixed + 2 * have.length);
    final data = ByteData.sublistView(out);
    out[0] = TraxReport.version << 4 | subtype;
    out[1] = seq & 0xFF;
    out.setRange(2, 6, senderPrefix);
    data.setUint16(6, session & 0xFFFF, Endian.little);
    data.setUint32(8, sentAt.millisecondsSinceEpoch ~/ 1000, Endian.little);
    out.setRange(12, 16, target);
    out[16] = have.length;
    for (var i = 0; i < have.length; i++) {
      data.setUint16(_fixed + 2 * i, have[i] & 0xFFFF, Endian.little);
    }
    return out;
  }

  /// A version 1 ask, or null for anything else or a malformed one. Each
  /// minute held is the latest with its low 16 bits at or before [sentAt].
  static TraxAsk? decode(Uint8List data) {
    if (data.length < _fixed) return null;
    if (data[0] >> 4 != TraxReport.version || data[0] & 0x0F != subtype) {
      return null;
    }
    final n = data[16];
    if (data.length < _fixed + 2 * n) return null;
    final view = ByteData.sublistView(data);
    final sentAt = DateTime.fromMillisecondsSinceEpoch(
      view.getUint32(8, Endian.little) * 1000,
      isUtc: true,
    );
    final sent = TrackPiece.minuteOf(sentAt);
    return TraxAsk(
      seq: data[1],
      senderPrefix: Uint8List.fromList(data.sublist(2, 6)),
      session: view.getUint16(6, Endian.little),
      sentAt: sentAt,
      target: Uint8List.fromList(data.sublist(12, 16)),
      have: [
        for (var i = 0; i < n; i++)
          sent -
              ((sent - view.getUint16(_fixed + 2 * i, Endian.little)) & 0xFFFF),
      ],
    );
  }
}
