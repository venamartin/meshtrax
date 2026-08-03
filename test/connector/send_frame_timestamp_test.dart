import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';

// The channel send frame's wire timestamp is what MeshCore One reaction
// hashes are computed over. The caller may now supply it (so it can be
// remembered on the row); the bytes on the wire must be identical either way.
void main() {
  test('explicit timestampSecs is encoded little-endian, bytes unchanged', () {
    final frame = buildSendChannelTextMsgFrame(
      2,
      'hi',
      timestampSecs: 0x01020304,
    );
    expect(frame[0], cmdSendChannelTxtMsg);
    expect(frame[1], txtTypePlain);
    expect(frame[2], 2);
    expect(frame.sublist(3, 7), [0x04, 0x03, 0x02, 0x01]);
    expect(String.fromCharCodes(frame.sublist(7)), 'hi');
  });

  test('omitted timestamp still stamps the current second (old behavior)',
      () {
    final before = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final frame = buildSendChannelTextMsgFrame(0, 'x');
    final after = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final stamped = frame[3] | (frame[4] << 8) | (frame[5] << 16) | (frame[6] << 24);
    expect(stamped, inInclusiveRange(before, after));
  });
}
