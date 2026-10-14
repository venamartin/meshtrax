import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_graph/path_graph.dart';

import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/services/path_graph/frame_adapter.dart';

// Audit repro r1-51-0: parseAdvert uppercases the advert pubkey
// (frame_adapter.dart _hex), while PathGraphService feeds the graph the
// lowercase pubKeyToHex keys. The path_graph package keys and compares
// pubkeys raw, so advert evidence lands under a ghost uppercase owner.

Uint8List _rxFrame(List<int> path, List<int> payload) {
  const header = (0x04 << 2) | 0x01; // ADVERT, flood
  final pathLen = (1 << 6) | (path.length ~/ 2); // 2-byte hashes
  return Uint8List.fromList(
      [0x88, 32, 0, header, pathLen, ...path, ...payload]);
}

Uint8List _chatAdvert(List<int> pubkey32, String name) => Uint8List.fromList([
      ...pubkey32,
      1, 2, 3, 4, // timestamp
      ...List.filled(64, 0xEE), // signature (firmware-verified)
      0x01 | 0x80, // chat + has name
      ...name.codeUnits,
    ]);

void main() {
  late PathGraph graph;
  late PathLabAdapter adapter;

  final selfKey = List<int>.filled(32, 0xAB);
  final bobKey = List<int>.filled(32, 0x5B);
  // Exactly what the service hands the graph (pubKeyToHex, lowercase).
  final selfHex = pubKeyToHex(Uint8List.fromList(selfKey));
  final bobHex = pubKeyToHex(Uint8List.fromList(bobKey));

  setUp(() async {
    graph = PathGraph(NativeDatabase.memory());
    await graph.init();
    // PathGraphService._onConnectorChanged.
    graph.setRadioIdentity(selfHex, 2);
    graph.ingestContact(bobHex, 'Bob');
    adapter = PathLabAdapter(graph);
  });

  tearDown(() => graph.dispose());

  test('(a) Bob\'s signed advert doorstep is filed under the key routing reads',
      () {
    adapter.handleFrame(_rxFrame([0xA2, 0x77], _chatAdvert(bobKey, 'Bob')));
    expect(graph.ingressCandidates(bobHex).map((c) => c.repeaterHash),
        contains('A277'),
        reason: 'owners with ingress rows: ${graph.contactsWithIngress()}');
  });

  test('(b) after Bob\'s advert, a Public post from "Bob" still credits Bob',
      () {
    adapter.handleFrame(_rxFrame([0xA2, 0x77], _chatAdvert(bobKey, 'Bob')));
    graph.observeChannelSender('Bob', Uint8List.fromList([0x13, 0x12]), 2);
    expect(graph.ingressCandidates(bobHex).map((c) => c.repeaterHash),
        contains('1312'),
        reason: 'contactByUniqueName saw two "Bob" keys and returned null');
  });

  test('(c) my own advert echo through A277 is proof A277 hears me', () {
    adapter.handleFrame(_rxFrame([0xA2, 0x77], _chatAdvert(selfKey, 'Me')));
    expect(graph.contactsWithIngress(), isEmpty,
        reason: 'self advert filed as a contact sighting of '
            '${graph.contactsWithIngress()}');
    expect(
        graph.egressCandidates()
            .where((c) => c.proven)
            .map((c) => c.repeaterHash),
        contains('A277'));
  });
}
