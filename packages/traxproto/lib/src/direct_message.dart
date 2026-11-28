import 'dart:typed_data';

import 'package:protobuf/protobuf.dart';

/// The version of the fixed byte and the messages behind it that this code
/// writes and reads.
const int directVersion = 0;

/// How [DirectMessage.text] is packed (meshtrax.proto, TextPacking).
const int textPlain = 0;
const int textSmaz = 1;

int _tag(int number, int wireType) => (number << 3) | wireType;

/// The fixed byte in front of a DM or its ACK, then the message: the
/// version in the top 3 bits, the side bit ([senderSortsAbove]: the sender's
/// key sorts above the receiver's, which tells a packet from its own echo),
/// 4 spare bits.
Uint8List frameDirect(Uint8List message, {required bool senderSortsAbove}) =>
    Uint8List.fromList([
      (directVersion << 5) | (senderSortsAbove ? 0x10 : 0),
      ...message,
    ]);

/// The side bit and the message bytes of a blob [frameDirect] made. Null
/// for an empty blob or a version this code does not know, whose body is
/// never read.
({bool senderSortsAbove, Uint8List message})? unframeDirect(List<int> blob) {
  if (blob.isEmpty || blob[0] >> 5 != directVersion) return null;
  return (
    senderSortsAbove: blob[0] & 0x10 != 0,
    message: Uint8List.fromList(blob.sublist(1)),
  );
}

/// meshtrax.proto, DirectMessage. A field left at 0 or empty is not sent.
class DirectMessage {
  DirectMessage({
    this.number = 0,
    this.tryNumber = 0,
    this.time = 0,
    List<int>? route,
    List<int>? hears,
    List<int>? heardBy,
    this.codeBytes = 0,
    this.packing = textPlain,
    List<int>? text,
    this.ackHeard = 0,
  })  : route = Uint8List.fromList(route ?? const []),
        hears = Uint8List.fromList(hears ?? const []),
        heardBy = Uint8List.fromList(heardBy ?? const []),
        text = Uint8List.fromList(text ?? const []);

  int number;
  int tryNumber;
  int time;
  Uint8List route;
  Uint8List hears;
  Uint8List heardBy;
  int codeBytes;
  int packing;
  Uint8List text;
  int ackHeard;

  /// [ackHeard] for the answer to try [tryNumber] of the message numbered
  /// [answered], in a message numbered [number]. 0 when it cannot be said:
  /// the answered message is not an earlier one, or the try is above 31.
  static int ackHeardFor(int number, int answered, int tryNumber) {
    final back = number - answered;
    if (back <= 0 || back > 0x3FFFFFF || tryNumber < 0 || tryNumber > 31) {
      return 0;
    }
    return back * 32 + tryNumber;
  }

  /// The message number and try [ackHeard] names, null when it names none.
  ({int number, int tryNumber})? get ackHeardOf => ackHeard < 32
      ? null
      : (number: number - ackHeard ~/ 32, tryNumber: ackHeard % 32);

  Uint8List encode() {
    final w = CodedBufferWriter();
    if (number != 0) w.writeField(1, PbFieldType.OU3, number);
    if (tryNumber != 0) w.writeField(2, PbFieldType.OU3, tryNumber);
    if (time != 0) w.writeField(3, PbFieldType.OF3, time);
    if (route.isNotEmpty) w.writeField(4, PbFieldType.OY, route);
    if (hears.isNotEmpty) w.writeField(5, PbFieldType.OY, hears);
    if (heardBy.isNotEmpty) w.writeField(6, PbFieldType.OY, heardBy);
    if (codeBytes != 0) w.writeField(7, PbFieldType.OU3, codeBytes);
    if (packing != 0) w.writeField(8, PbFieldType.OU3, packing);
    if (text.isNotEmpty) w.writeField(9, PbFieldType.OY, text);
    if (ackHeard != 0) w.writeField(10, PbFieldType.OU3, ackHeard);
    return w.toBuffer();
  }

  /// Null when [bytes] are not a protobuf message. Fields this code does
  /// not know are skipped.
  static DirectMessage? decode(List<int> bytes) {
    final m = DirectMessage();
    try {
      final r = CodedBufferReader(bytes);
      while (true) {
        final tag = r.readTag();
        if (tag == 0) return m;
        if (tag == _tag(1, WIRETYPE_VARINT)) {
          m.number = r.readUint32();
        } else if (tag == _tag(2, WIRETYPE_VARINT)) {
          m.tryNumber = r.readUint32();
        } else if (tag == _tag(3, WIRETYPE_FIXED32)) {
          m.time = r.readFixed32();
        } else if (tag == _tag(4, WIRETYPE_LENGTH_DELIMITED)) {
          m.route = r.readBytes();
        } else if (tag == _tag(5, WIRETYPE_LENGTH_DELIMITED)) {
          m.hears = r.readBytes();
        } else if (tag == _tag(6, WIRETYPE_LENGTH_DELIMITED)) {
          m.heardBy = r.readBytes();
        } else if (tag == _tag(7, WIRETYPE_VARINT)) {
          m.codeBytes = r.readUint32();
        } else if (tag == _tag(8, WIRETYPE_VARINT)) {
          m.packing = r.readUint32();
        } else if (tag == _tag(9, WIRETYPE_LENGTH_DELIMITED)) {
          m.text = r.readBytes();
        } else if (tag == _tag(10, WIRETYPE_VARINT)) {
          m.ackHeard = r.readUint32();
        } else if (!r.skipField(tag)) {
          return m;
        }
      }
    } on InvalidProtocolBufferException {
      return null;
    }
  }
}

/// meshtrax.proto, DirectAck. A field left at 0 or empty is not sent.
class DirectAck {
  DirectAck({
    this.number = 0,
    this.tryNumber = 0,
    this.triesArrived = 0,
    List<int>? cameBy,
    this.level = 0,
    List<int>? route,
    List<int>? hears,
    List<int>? heardBy,
    this.codeBytes = 0,
  })  : cameBy = Uint8List.fromList(cameBy ?? const []),
        route = Uint8List.fromList(route ?? const []),
        hears = Uint8List.fromList(hears ?? const []),
        heardBy = Uint8List.fromList(heardBy ?? const []);

  int number;
  int tryNumber;
  int triesArrived;
  Uint8List cameBy;
  int level;
  Uint8List route;
  Uint8List hears;
  Uint8List heardBy;
  int codeBytes;

  Uint8List encode() {
    final w = CodedBufferWriter();
    if (number != 0) w.writeField(1, PbFieldType.OU3, number);
    if (tryNumber != 0) w.writeField(2, PbFieldType.OU3, tryNumber);
    if (triesArrived != 0) w.writeField(3, PbFieldType.OU3, triesArrived);
    if (cameBy.isNotEmpty) w.writeField(4, PbFieldType.OY, cameBy);
    if (level != 0) w.writeField(5, PbFieldType.OS3, level);
    if (route.isNotEmpty) w.writeField(6, PbFieldType.OY, route);
    if (hears.isNotEmpty) w.writeField(7, PbFieldType.OY, hears);
    if (heardBy.isNotEmpty) w.writeField(8, PbFieldType.OY, heardBy);
    if (codeBytes != 0) w.writeField(9, PbFieldType.OU3, codeBytes);
    return w.toBuffer();
  }

  /// Null when [bytes] are not a protobuf message. Fields this code does
  /// not know are skipped.
  static DirectAck? decode(List<int> bytes) {
    final m = DirectAck();
    try {
      final r = CodedBufferReader(bytes);
      while (true) {
        final tag = r.readTag();
        if (tag == 0) return m;
        if (tag == _tag(1, WIRETYPE_VARINT)) {
          m.number = r.readUint32();
        } else if (tag == _tag(2, WIRETYPE_VARINT)) {
          m.tryNumber = r.readUint32();
        } else if (tag == _tag(3, WIRETYPE_VARINT)) {
          m.triesArrived = r.readUint32();
        } else if (tag == _tag(4, WIRETYPE_LENGTH_DELIMITED)) {
          m.cameBy = r.readBytes();
        } else if (tag == _tag(5, WIRETYPE_VARINT)) {
          m.level = r.readSint32();
        } else if (tag == _tag(6, WIRETYPE_LENGTH_DELIMITED)) {
          m.route = r.readBytes();
        } else if (tag == _tag(7, WIRETYPE_LENGTH_DELIMITED)) {
          m.hears = r.readBytes();
        } else if (tag == _tag(8, WIRETYPE_LENGTH_DELIMITED)) {
          m.heardBy = r.readBytes();
        } else if (tag == _tag(9, WIRETYPE_VARINT)) {
          m.codeBytes = r.readUint32();
        } else if (!r.skipField(tag)) {
          return m;
        }
      }
    } on InvalidProtocolBufferException {
      return null;
    }
  }
}
