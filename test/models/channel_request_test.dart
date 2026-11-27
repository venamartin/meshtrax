import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/models/channel_request.dart';

void main() {
  final asking = ChannelRequest(
    kind: ChannelRequestKind.photoPackets,
    id: 9,
    asker: 0xBEEF,
    asked: 0x7777,
    build: 252,
    body: Uint8List.fromList([0x3a, 4, 0x00, 0x06]),
  );

  test('a request is its kind, version and flags, build, id, asker, asked '
      'and body', () {
    expect(asking.encode(), [
      1, 0x00, 0x00, 0xFC, 9, 0xBE, 0xEF, 0x77, 0x77, //
      0x3a, 4, 0x00, 0x06,
    ]);
  });

  test('a request for photo packets fills one AES block with the 3 bytes '
      'the radio adds', () {
    expect(asking.encode().length + 3, 16);
  });

  test('it reads back as written', () {
    final read = ChannelRequest.decode(asking.encode())!;
    expect(read.kind, ChannelRequestKind.photoPackets);
    expect(read.flags, 0);
    expect(read.build, 252);
    expect(read.id, 9);
    expect(read.asker, 0xBEEF);
    expect(read.asked, 0x7777);
    expect(read.body, [0x3a, 4, 0x00, 0x06]);
  });

  test('too short, kind 0, or a version this build does not know: no '
      'request', () {
    final bytes = asking.encode();
    expect(ChannelRequest.decode(Uint8List.sublistView(bytes, 0, 8)), null);
    expect(ChannelRequest.decode(Uint8List.fromList([0, ...bytes.skip(1)])),
        null);
    expect(
      ChannelRequest.decode(
        Uint8List.fromList([bytes[0], 0x10, ...bytes.skip(2)]),
      ),
      null,
    );
  });

  test('flags it does not know are kept, not refused', () {
    final bytes = asking.encode()..[1] = 0x0F;
    expect(ChannelRequest.decode(bytes)?.flags, 0x0F);
  });

  test('it is for the node asked, or for anyone', () {
    expect(asking.isFor(0x7777), isTrue);
    expect(asking.isFor(0x1234), isFalse);
    final anyone = ChannelRequest(kind: 1, id: 1, asker: 0xBEEF);
    expect(anyone.isFor(0x1234), isTrue);
  });
}
