import 'dart:typed_data';

import 'package:protobuf/protobuf.dart';

/// meshtrax.proto, TraxReportGrowth: what follows a TRAX report's fixed
/// bytes. A field left at 0 or empty is not sent.
class TraxReportGrowth {
  TraxReportGrowth({this.name = '', this.build = 0, List<int>? track})
    : track = Uint8List.fromList(track ?? const []);

  String name;
  int build;

  /// packages/traxshare's TrackBlock, as it packs it.
  Uint8List track;

  Uint8List encode() {
    final w = CodedBufferWriter();
    if (name.isNotEmpty) w.writeField(1, PbFieldType.OS, name);
    if (build != 0) w.writeField(2, PbFieldType.OU3, build);
    if (track.isNotEmpty) w.writeField(3, PbFieldType.OY, track);
    return w.toBuffer();
  }

  /// Null when [bytes] don't parse, which drops the report. Fields this
  /// code doesn't know are skipped.
  static TraxReportGrowth? decode(List<int> bytes) {
    final m = TraxReportGrowth();
    final read = _parse(bytes, (r, tag) {
      switch (tag) {
        case 0x0A:
          m.name = r.readString();
        case 0x10:
          m.build = r.readUint32();
        case 0x1A:
          m.track = r.readBytes();
        default:
          return false;
      }
      return true;
    });
    return read ? m : null;
  }
}

/// meshtrax.proto, TraxAskGrowth: what follows a TRAX ask's fixed bytes.
/// Nothing yet: what a later MeshTrax adds is skipped.
class TraxAskGrowth {
  Uint8List encode() => Uint8List(0);

  /// Null when [bytes] don't parse, which drops the ask.
  static TraxAskGrowth? decode(List<int> bytes) =>
      _parse(bytes, (_, _) => false) ? TraxAskGrowth() : null;
}

/// Reads every field of [bytes]: those [field] knows by their tag, the rest
/// skipped, as they are varint, 64-bit, length-delimited or 32-bit. False
/// when they don't parse, a group included.
bool _parse(
  List<int> bytes,
  bool Function(CodedBufferReader r, int tag) field,
) {
  try {
    final r = CodedBufferReader(bytes);
    for (var tag = r.readTag(); tag != 0; tag = r.readTag()) {
      if (field(r, tag)) continue;
      switch (tag & 7) {
        case WIRETYPE_VARINT:
          r.readUint64();
        case WIRETYPE_FIXED64:
          r.readFixed64();
        // Not skipField: it takes a negative length as a step back, which
        // can come round to the same field for ever.
        case WIRETYPE_LENGTH_DELIMITED:
          r.readBytesAsView();
        case WIRETYPE_FIXED32:
          r.readFixed32();
        default:
          return false;
      }
    }
    return true;
  } on InvalidProtocolBufferException {
    return false;
  } on RangeError {
    // A negative length.
    return false;
  }
}
