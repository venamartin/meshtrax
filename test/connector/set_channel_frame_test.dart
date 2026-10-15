import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';

// CMD_SET_CHANNEL: [cmd][idx][name x32][psk x16]. Firmware 1.18 skips
// nameless slots for incoming group traffic, so a keyed slot must carry a
// name or it goes deaf.
void main() {
  String nameOf(Uint8List frame) {
    final raw = frame.sublist(2, 34);
    final end = raw.indexOf(0);
    return utf8.decode(end < 0 ? raw : raw.sublist(0, end));
  }

  final key = Uint8List.fromList(List.generate(16, (i) => i + 1));

  test('a keyed slot without a name is written with one', () {
    final frame = buildSetChannelFrame(3, '', key);

    expect(nameOf(frame), 'Channel 3');
    expect(frame.sublist(34, 50), key);
  });

  test('a named slot keeps its name', () {
    expect(nameOf(buildSetChannelFrame(3, '#test', key)), '#test');
  });

  test('clearing a slot still writes an empty name and zero key', () {
    final frame = buildSetChannelFrame(3, '', Uint8List(16));

    expect(frame.sublist(2, 50), everyElement(0));
  });
}
