import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:traxproto/traxproto.dart';

Uint8List _hex(String s) => Uint8List.fromList([
      for (var i = 0; i < s.length; i += 2)
        int.parse(s.substring(i, i + 2), radix: 16),
    ]);

// Encoded by hand from proto/meshtrax.proto, field by field. These bytes
// must never change: a phone on an older MeshTrax reads them.
final dmBytes = _hex('0805' // number 5
    '1001' // try 1
    '1D78563412' // time 0x12345678, fixed32
    '2204A277BEEF' // route A277, BEEF
    '2A03A27785' // hears A277 at +5 dB
    '4001' // packing: Smaz
    '4A026869'); // text
final ackBytes = _hex('0805' // number 5
    '1001' // try 1
    '1803' // tries 0 and 1 arrived
    '2202A277' // came by A277
    '280D' // level -7 dB, zigzag
    '3202BEEF' // route BEEF
    '3A03A27785' // hears A277 at +5 dB
    '4203BEEF00' // heard by BEEF, level not known
    '4803'); // 3-byte codes

void main() {
  test('a DM, byte for byte', () {
    final dm = DirectMessage(
      number: 5,
      tryNumber: 1,
      time: 0x12345678,
      route: _hex('A277BEEF'),
      hears: _hex('A27785'),
      packing: textSmaz,
      text: 'hi'.codeUnits,
    );
    expect(dm.encode(), dmBytes);

    final back = DirectMessage.decode(dmBytes)!;
    expect(back.number, 5);
    expect(back.tryNumber, 1);
    expect(back.time, 0x12345678);
    expect(back.route, _hex('A277BEEF'));
    expect(back.hears, _hex('A27785'));
    expect(back.heardBy, isEmpty);
    expect(back.codeBytes, 0);
    expect(back.packing, textSmaz);
    expect(back.text, 'hi'.codeUnits);
  });

  test('an ACK, byte for byte', () {
    final ack = DirectAck(
      number: 5,
      tryNumber: 1,
      triesArrived: 3,
      cameBy: _hex('A277'),
      level: -7,
      route: _hex('BEEF'),
      hears: _hex('A27785'),
      heardBy: _hex('BEEF00'),
      codeBytes: 3,
    );
    expect(ack.encode(), ackBytes);

    final back = DirectAck.decode(ackBytes)!;
    expect(back.number, 5);
    expect(back.tryNumber, 1);
    expect(back.triesArrived, 3);
    expect(back.cameBy, _hex('A277'));
    expect(back.level, -7);
    expect(back.route, _hex('BEEF'));
    expect(back.hears, _hex('A27785'));
    expect(back.heardBy, _hex('BEEF00'));
    expect(back.codeBytes, 3);
  });

  test('nothing set is no bytes, and no bytes is nothing set', () {
    expect(DirectMessage().encode(), isEmpty);
    expect(DirectAck().encode(), isEmpty);
    expect(DirectMessage.decode(const [])!.text, isEmpty);
    expect(DirectAck.decode(const [])!.number, 0);
  });

  // A packet from a later MeshTrax: fields this one has never heard of, of
  // each kind the rules allow, before, between and after the ones it knows.
  test('fields from the future are skipped', () {
    final future = Uint8List.fromList([
      ..._hex('782A'), // field 15, varint
      ...dmBytes.sublist(0, 4),
      ..._hex('A20102FFFF'), // field 20, bytes
      ..._hex('AD0101020304'), // field 21, 32-bit
      ...dmBytes.sublist(4),
      ..._hex('B1010102030405060708'), // field 22, 64-bit
    ]);
    final dm = DirectMessage.decode(future)!;
    expect(dm.number, 5);
    expect(dm.tryNumber, 1);
    expect(dm.route, _hex('A277BEEF'));
    expect(dm.text, 'hi'.codeUnits);
  });

  test('a known number with another type is skipped, not misread', () {
    // Field 1 as bytes where a number is expected.
    final dm = DirectMessage.decode(_hex('0A02FFFF' '1001'))!;
    expect(dm.number, 0);
    expect(dm.tryNumber, 1);
  });

  test('cut short or not protobuf reads as nothing', () {
    expect(DirectMessage.decode(dmBytes.sublist(0, dmBytes.length - 1)), isNull);
    expect(DirectAck.decode(_hex('2210A2')), isNull);
  });

  group('the fixed byte', () {
    test('version, side bit, four spare bits', () {
      expect(frameDirect(dmBytes, senderSortsAbove: false).first, 0x00);
      expect(frameDirect(dmBytes, senderSortsAbove: true).first, 0x10);
      final back = unframeDirect(frameDirect(dmBytes, senderSortsAbove: true))!;
      expect(back.senderSortsAbove, isTrue);
      expect(back.message, dmBytes);
    });

    test('spare bits set by a later MeshTrax change nothing', () {
      final blob = [0x1F, ...dmBytes];
      expect(unframeDirect(blob)!.senderSortsAbove, isTrue);
      expect(unframeDirect(blob)!.message, dmBytes);
    });

    test('a later version is not read', () {
      expect(unframeDirect([0x20, ...dmBytes]), isNull);
      expect(unframeDirect(const []), isNull);
    });
  });
}
