import 'dart:typed_data';

import '../connector/meshcore_protocol.dart';
import 'passing_copy.dart';
import 'path_helper.dart';

/// MeshTrax's own DM and its ACK, in MeshTrax's block of data types
/// (0x0170 to 0x017F, docs/technical/photos.md).
const int dataTypeMeshTraxDm = 0x0175;
const int dataTypeMeshTraxAck = 0x0176;

/// The longest packet, on the air, the radio still hands to the app
/// (companion MyMesh.cpp logRxRaw: len + 3 <= MAX_FRAME_SIZE, 176). A longer
/// one is never seen: not opened, no copy heard, nothing for Pathfinder.
const int heardPacketMaxBytes = 173;

const int _routeTransportFlood = 0x00;
const int _routeFlood = 0x01;
const int _routeDirect = 0x02;
const int _blockSize = 16;

/// A packet between two MeshTrax phones that the app builds and opens
/// itself: the type a photo packet has (PAYLOAD_TYPE_GRP_DATA), which every
/// repeater passes on routed or flooded whether or not it can open it
/// (Mesh.cpp onRecvPacket), sealed with the two radios' shared secret as a
/// firmware DM is. The radio sends it as handed over (CMD_SEND_RAW_PACKET)
/// and hands over every copy it hears (PUSH_CODE_LOG_RX_DATA), so no channel
/// slot is needed and any copy can be opened.
///
/// Payload: [their key's first byte][mine][2-byte MAC][AES blocks], and in
/// the blocks what a channel datagram holds: the data type (2 bytes, low
/// first), the blob's length, the blob.
class MeshTraxPacket {
  const MeshTraxPacket._();

  /// The payload for [blob] of [dataType], to the radio whose key starts
  /// with [toByte] from the one whose key starts with [fromByte].
  static Uint8List seal(
    Uint8List secret, {
    required int toByte,
    required int fromByte,
    required int dataType,
    required List<int> blob,
  }) {
    if (blob.length > 255) throw ArgumentError('blob over 255 bytes');
    return Uint8List.fromList([
      toByte,
      fromByte,
      ...PassingCopyOpener.encryptThenMac(secret, [
        dataType & 0xFF,
        dataType >> 8,
        blob.length,
        ...blob,
      ]),
    ]);
  }

  /// What [payload] holds, opened with [secret]; null when the MAC fails or
  /// the length inside runs past the blocks.
  static ({int dataType, Uint8List blob})? open(
    Uint8List secret,
    List<int> payload,
  ) {
    if (payload.length < 2 + 2 + _blockSize) return null;
    final plain = PassingCopyOpener.macThenDecrypt(
      secret,
      Uint8List.fromList(payload.sublist(2)),
    );
    if (plain == null || 3 + plain[2] > plain.length) return null;
    return (
      dataType: plain[0] | (plain[1] << 8),
      blob: Uint8List.sublistView(plain, 3, 3 + plain[2]),
    );
  }

  /// The packet for CMD_SEND_RAW_PACKET that carries [payload] along
  /// [route] ([width] bytes a repeater).
  static Uint8List routed(List<int> payload, List<int> route, int width) =>
      Uint8List.fromList([
        (payloadTypeGRPDATA << 2) | _routeDirect,
        PathHelper.encodePathLen(route.length ~/ width, width),
        ...route,
        ...payload,
      ]);

  /// The packet that floods [payload], repeaters adding [width] bytes each,
  /// in the region of [scopeKey] when there is one (MyMesh::sendFloodScoped).
  static Uint8List flood(List<int> payload, int width, {Uint8List? scopeKey}) {
    final pathLen = PathHelper.encodePathLen(0, width);
    if (scopeKey == null) {
      return Uint8List.fromList([
        (payloadTypeGRPDATA << 2) | _routeFlood,
        pathLen,
        ...payload,
      ]);
    }
    final code =
        PassingCopyOpener.transportCode(scopeKey, payloadTypeGRPDATA, payload);
    return Uint8List.fromList([
      (payloadTypeGRPDATA << 2) | _routeTransportFlood,
      code & 0xFF,
      code >> 8,
      0,
      0,
      pathLen,
      ...payload,
    ]);
  }

  /// The longest blob a packet can carry and still be heard with
  /// [pathBytes] of path on it: a routed packet's whole route as it leaves,
  /// or what a flood has grown to at the last repeater it must still be
  /// heard from. [scoped]: a flood in a region carries 4 more bytes.
  static int roomFor({required int pathBytes, bool scoped = false}) {
    final sealed =
        heardPacketMaxBytes - 2 - (scoped ? 4 : 0) - pathBytes - 2 - 2;
    return (sealed ~/ _blockSize) * _blockSize - 3;
  }
}
