import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_graph/path_graph.dart';

import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/services/path_graph/frame_adapter.dart';

// Audit repro r1-50-0: parseAdvert builds pubkeyHex uppercase (_hex), while
// PathGraphService feeds the graph lowercase pubKeyToHex keys
// (setRadioIdentity(selfPublicKeyHex), ingestContact(contact.publicKeyHex),
// findPath(contact.publicKeyHex)). The package never folds pubkey case, so
// advert evidence lands under a second, uppercase owner.

Uint8List _rxFrame({
  required int payloadType,
  required List<int> path,
  required List<int> payload,
  int stride = 2,
}) {
  final header = (payloadType << 2) | 0x01; // flood
  final pathLen = ((stride - 1) << 6) | (path.length ~/ stride);
  return Uint8List.fromList(
      [0x88, 32, 0, header, pathLen, ...path, ...payload]);
}

Uint8List _chatAdvert(List<int> pubkey32, String name) => Uint8List.fromList([
      ...pubkey32,
      1, 2, 3, 4, // timestamp
      ...List.filled(64, 0xEE), // signature
      0x01 | 0x80, // chat + name
      ...name.codeUnits,
    ]);

void main() {
  late PathGraph graph;
  late PathLabAdapter adapter;

  // Keys exactly as the app produces them (pubKeyToHex, lowercase).
  final selfKey = List<int>.filled(32, 0xAA);
  final bobKey = List<int>.filled(32, 0xAB);
  final selfHex = pubKeyToHex(Uint8List.fromList(selfKey));
  final bobHex = pubKeyToHex(Uint8List.fromList(bobKey));

  setUp(() async {
    graph = PathGraph(NativeDatabase.memory());
    await graph.init();
    // What PathGraphService._onConnectorChanged does.
    graph.setRadioIdentity(selfHex, 2);
    graph.ingestContact(bobHex, 'Bob');
    graph.ingestContact(selfHex, 'Me');
    adapter = PathLabAdapter(graph);
  });

  tearDown(() => graph.dispose());

  test('signed advert doorstep reaches the key routing looks up', () {
    adapter.handleFrame(_rxFrame(
        payloadType: 0x04, path: [0xBE, 0xEF], payload: _chatAdvert(bobKey, 'Bob')));
    expect(graph.ingressCandidates(bobHex).map((c) => c.repeaterHash),
        contains('BEEF'),
        reason: 'advert credited BEEF under owner '
            '${graph.contactsWithIngress()} instead of $bobHex');
  });

  test('a chat advert does not make the contact name ambiguous', () {
    adapter.handleFrame(_rxFrame(
        payloadType: 0x04, path: [0xBE, 0xEF], payload: _chatAdvert(bobKey, 'Bob')));
    final origin = graph.resolveName('Bob');
    expect(origin, isA<UniqueNameOrigin>(),
        reason: 'two knownContacts entries (lower + upper) now match Bob');
    expect((origin as UniqueNameOrigin).contactPubkey, bobHex);
  });

  test('my own advert echo is an own echo, not a contact sighting', () {
    adapter.handleFrame(_rxFrame(
        payloadType: 0x04, path: [0xBE, 0xEF], payload: _chatAdvert(selfKey, 'Me')));
    expect(graph.contactsWithIngress(), isEmpty,
        reason: 'self advert filed as contact row(s): '
            '${graph.contactsWithIngress()}');
    expect(
        graph.egressCandidates().where((c) => c.proven).map((c) => c.repeaterHash),
        contains('BEEF'));
  });
}
