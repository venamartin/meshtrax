import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';

// Room server posts arrive as signed messages whose 4-byte author pubkey
// prefix sits between the timestamp and the text. The app used to skip those
// bytes, then treat the first 4 characters of the TEXT as the author key —
// clipping every room message and attributing it to "Unknown [<text bytes>]".
// These tests pin the corrected layout parse.
void main() {
  final roomPrefix = Uint8List.fromList([0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF]);
  final authorPrefix = Uint8List.fromList([0x12, 0x34, 0x56, 0x78]);
  const timestamp = 1752854400; // arbitrary epoch seconds

  Uint8List buildFrame({
    required int code,
    required int txtType,
    Uint8List? author,
    required String text,
  }) {
    final b = BytesBuilder();
    b.addByte(code);
    if (code == respCodeContactMsgRecvV3) {
      b.addByte(0x14); // snr
      b.addByte(0); // reserved1
      b.addByte(0); // reserved2
    }
    b.add(roomPrefix);
    b.addByte(0xFF); // path_len (direct)
    b.addByte(txtType);
    b.add((ByteData(4)..setUint32(0, timestamp, Endian.little))
        .buffer
        .asUint8List());
    if (author != null) b.add(author);
    b.add(utf8.encode(text));
    return b.toBytes();
  }

  group('parseContactMsgLayout', () {
    test('signed room post keeps full text and real author prefix', () {
      final frame = buildFrame(
        code: respCodeContactMsgRecvV3,
        txtType: txtTypeSigned,
        author: authorPrefix,
        text: 'It is not working correctly',
      );

      final layout = MeshCoreConnector.parseContactMsgLayout(frame);

      expect(layout, isNotNull);
      expect(layout!.text, 'It is not working correctly');
      expect(layout.authorPrefix, authorPrefix);
      expect(layout.senderPrefix, roomPrefix);
      expect(layout.txtType, txtTypeSigned);
      expect(layout.timestampRaw, timestamp);
    });

    test('plain direct message has no author prefix and untouched text', () {
      final frame = buildFrame(
        code: respCodeContactMsgRecvV3,
        txtType: txtTypePlain,
        text: 'It is not working correctly',
      );

      final layout = MeshCoreConnector.parseContactMsgLayout(frame);

      expect(layout, isNotNull);
      expect(layout!.text, 'It is not working correctly');
      expect(layout.authorPrefix, isNull);
    });

    test('legacy non-V3 frame parses with the shorter header', () {
      final frame = buildFrame(
        code: respCodeContactMsgRecv,
        txtType: txtTypeSigned,
        author: authorPrefix,
        text: 'hello room',
      );

      final layout = MeshCoreConnector.parseContactMsgLayout(frame);

      expect(layout, isNotNull);
      expect(layout!.text, 'hello room');
      expect(layout.authorPrefix, authorPrefix);
      expect(layout.senderPrefix, roomPrefix);
    });

    test('returns null for a non-message code', () {
      final frame = buildFrame(
        code: respCodeContactMsgRecvV3,
        txtType: txtTypePlain,
        text: 'x',
      );
      frame[0] = 0x42;

      expect(MeshCoreConnector.parseContactMsgLayout(frame), isNull);
    });
  });
}
