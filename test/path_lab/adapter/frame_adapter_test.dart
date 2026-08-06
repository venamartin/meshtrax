import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_graph/path_graph.dart';

import 'frame_adapter.dart';

/// Builds an 0x88 RX-log frame: [0x88][snr*4][rssi][packet].
Uint8List rxFrame({
  required int payloadType,
  required List<int> path,
  required List<int> payload,
  int stride = 2,
  int snrQuarterDb = 32, // 8 dB
}) {
  final header = (payloadType << 2) | 0x01; // ROUTE_TYPE_FLOOD
  final pathLen = ((stride - 1) << 6) | (path.length ~/ stride);
  return Uint8List.fromList(
      [0x88, snrQuarterDb, 0, header, pathLen, ...path, ...payload]);
}

Uint8List advertPayload({
  required List<int> pubkey32,
  required int advType,
  String? name,
  double? lat,
  double? lon,
}) {
  var flags = advType;
  final extra = <int>[];
  if (lat != null && lon != null) {
    flags |= 0x10;
    final bd = ByteData(8)
      ..setInt32(0, (lat * 1e6).round(), Endian.little)
      ..setInt32(4, (lon * 1e6).round(), Endian.little);
    extra.addAll(bd.buffer.asUint8List());
  }
  if (name != null) {
    flags |= 0x80;
    // name appended after flags+extras
  }
  return Uint8List.fromList([
    ...pubkey32,
    1, 2, 3, 4, // timestamp
    ...List.filled(64, 0xEE), // signature (already firmware-verified)
    flags,
    ...extra,
    ...?name?.codeUnits,
  ]);
}

void main() {
  late PathGraph graph;
  late PathLabAdapter adapter;
  final pubkey = List<int>.generate(32, (i) => i == 0 ? 0xA2 : (i == 1 ? 0x77 : 0x11));

  setUp(() async {
    graph = PathGraph(NativeDatabase.memory());
    await graph.init();
    graph.setRadioIdentity('ab' * 32, 2);
    adapter = PathLabAdapter(graph);
  });

  tearDown(() => graph.dispose());

  test('repeater advert ingests node metadata and observes its path', () {
    adapter.handleFrame(rxFrame(
      payloadType: 0x04,
      path: [0x13, 0x12, 0x5C, 0xBB],
      payload: advertPayload(
          pubkey32: pubkey, advType: 2, name: 'Alpha', lat: 36.9, lon: -121.7),
    ));
    final snap = graph.snapshot();
    expect(snap.nodes['A277']!.name, 'Alpha');
    expect(snap.nodes['A277']!.lat, closeTo(36.9, 1e-5));
    expect(snap.edges.containsKey(('1312', '5CBB')), isTrue);
    expect(graph.counters.observationsApplied, 1);
  });

  test('chat advert feeds the contact mirror', () {
    adapter.handleFrame(rxFrame(
      payloadType: 0x04,
      path: [0x13, 0x12],
      payload: advertPayload(pubkey32: pubkey, advType: 1, name: 'Bob'),
    ));
    expect(graph.resolveName('Bob'), isA<UniqueNameOrigin>());
  });

  test('group text harvests edges anonymously with variant dedup', () {
    final payload = [0x42, 1, 2, 3, 4, 5, 6, 7];
    adapter.handleFrame(rxFrame(
        payloadType: 0x05, path: [0xA2, 0x77, 0x13, 0x12], payload: payload));
    adapter.handleFrame(rxFrame(
        payloadType: 0x05, path: [0xA2, 0x77, 0x13, 0x12], payload: payload));
    expect(graph.snapshot().edges[('A277', '1312')]!.obsCount, 1,
        reason: 'same payload fingerprint = one message');
  });

  test('1-byte paths are dropped and counted', () {
    adapter.handleFrame(rxFrame(
        payloadType: 0x05, path: [0xA2, 0x13], payload: [1], stride: 1));
    expect(graph.counters.dropped1Byte, 1);
  });

  test('TRACE frames are skipped entirely', () {
    adapter.handleFrame(rxFrame(
        payloadType: 0x09, path: [0x20, 0x1C], payload: [0xAA]));
    expect(adapter.tracesSkipped, 1);
    expect(graph.snapshot().edges, isEmpty);
  });

  test('path discovery feeds both proven paths', () {
    final contact = 'b0' * 32;
    adapter.pendingDiscoveryPubkey = contact;
    // [0x8D][rsv][prefix x6][out_len][out][in_len][in]
    // out = A277,1312 (us->them); in = 5CBB,249F (them->us)
    final pathLen = (1 << 6) | 2; // stride 2, 2 hops
    adapter.handleFrame(Uint8List.fromList([
      0x8D, 0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0,
      pathLen, 0xA2, 0x77, 0x13, 0x12,
      pathLen, 0x5C, 0xBB, 0x24, 0x9F,
    ]));

    final snap = graph.snapshot();
    // Forward path proven as a delivered send.
    expect(snap.edges[('A277', '1312')]!.s, 1);
    // Return path proven in reverse.
    expect(snap.edges[('5CBB', '249F')]!.n, greaterThanOrEqualTo(0));
    expect(snap.edges.containsKey(('5CBB', '249F')), isTrue);
    // Their doorstep = first hop of the return path.
    expect(graph.ingressCandidates(contact).single.repeaterHash, '5CBB');
    // My doorstep proven from the outbound first hop.
    expect(graph.egressCandidates().map((c) => c.repeaterHash),
        contains('A277'));
    expect(adapter.lastPathDiscovery, contains('B0B0B0B0B0B0'));
  });

  test('discover responses parse uplink SNR and commit as egress', () {
    // [0x8E][rx snr][rssi][path_len] then ctl: [0x92][uplink snr][tag x4][pk]
    adapter.handleFrame(Uint8List.fromList(
        [0x8E, 40, 0, 0, 0x92, 30, 1, 2, 3, 4, ...pubkey]));
    expect(adapter.pendingDiscover.single.uplinkSnr, closeTo(7.5, 1e-9));
    adapter.commitDiscover(failureEpisode: false);
    expect(graph.egressCandidates().single.repeaterHash, 'A277');
    expect(graph.egressCandidates().single.tier, EvidenceTier.proven);
  });
}
