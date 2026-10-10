import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';

// CMD_ADD_UPDATE_CONTACT layout: [cmd][pubKey 32][type][flags][path_len][path 64]…
// The firmware stores path_len as-is, width bits included, so the byte the
// app writes IS the route's width on the radio.
void main() {
  final key = Uint8List.fromList(List.generate(32, (i) => i + 1));
  final route = Uint8List.fromList([0xA2, 0x77, 0xBE, 0xEF]);

  test('a 2-hop 2-byte route is written as 0x42', () {
    final frame = buildUpdateContactPathFrame(key, route, 2, 2);

    expect(frame[0], cmdAddUpdateContact);
    expect(frame[35], 0x42);
    expect(frame.sublist(36, 40), route);
    expect(frame.sublist(40, 100), everyElement(0));
  });

  test('the same bytes labelled 4 hops of 1 byte are written as 0x04', () {
    // What the width leak used to produce: a route no repeater can follow.
    final frame = buildUpdateContactPathFrame(key, route, 4, 1);

    expect(frame[35], 0x04);
  });

  test('no route is written as 0xFF', () {
    final frame = buildUpdateContactPathFrame(key, Uint8List(0), -1, 2);

    expect(frame[35], 0xFF);
  });
}
