import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_graph/path_graph.dart';

import 'package:meshtrax/services/path_graph/frame_adapter.dart';

/// Builds an 0x88 RX-log frame: [0x88][snr*4][rssi][packet].
Uint8List rxFrame({
  required int payloadType,
  required List<int> path,
  required List<int> payload,
  int stride = 2,
  int snrQuarterDb = 32, // 8 dB
  int routeType = 0x01, // ROUTE_TYPE_FLOOD; 0x02 = direct
}) {
  final header = (payloadType << 2) | routeType;
  final pathLen = ((stride - 1) << 6) | (path.length ~/ stride);
  // Transport routes (0x00 / 0x03) carry four transport-code bytes first.
  final transport = routeType == 0x00 || routeType == 0x03 ? [0, 0, 0, 0] : [];
  return Uint8List.fromList([
    0x88, snrQuarterDb, 0, header, ...transport, pathLen, ...path, ...payload
  ]);
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
    adapter.handleFrame(Uint8List.fromList([0x80, ...pubkey])); // verified
    final snap = graph.snapshot();
    expect(snap.nodes['A277']!.name, 'Alpha');
    expect(snap.nodes['A277']!.lat, closeTo(36.9, 1e-5));
    expect(snap.edges.containsKey(('1312', '5CBB')), isTrue);
  });

  test('chat advert feeds the contact mirror', () {
    adapter.handleFrame(rxFrame(
      payloadType: 0x04,
      path: [0x13, 0x12],
      payload: advertPayload(pubkey32: pubkey, advType: 1, name: 'Bob'),
    ));
    adapter.handleFrame(Uint8List.fromList([0x8A, ...pubkey])); // new contact
    expect(graph.resolveName('Bob'), isA<UniqueNameOrigin>());
  });

  group('adverts are trusted only once the radio verified them', () {
    Uint8List advert({String name = 'Alpha', List<int> path = const [0x13, 0x12]}) =>
        rxFrame(
          payloadType: 0x04,
          path: path,
          payload: advertPayload(pubkey32: pubkey, advType: 2, name: name),
        );
    final verified = Uint8List.fromList([0x80, ...pubkey]);
    final owner = 'a277${'11' * 30}';

    test('no push: the path is a corridor, nobody is named or credited', () {
      adapter.handleFrame(advert(path: [0x13, 0x12, 0x5C, 0xBB]));
      final snap = graph.snapshot();
      expect(snap.edges.containsKey(('1312', '5CBB')), isTrue);
      expect(snap.nodes['A277']?.name, isNull);
      expect(graph.contactsWithIngress(), isEmpty);
    });

    test('a push for another key credits nothing', () {
      adapter.handleFrame(advert());
      adapter.handleFrame(Uint8List.fromList([0x80, ...List.filled(32, 0x42)]));
      expect(graph.snapshot().nodes['A277']?.name, isNull);
    });

    test('a later copy with the same bytes is credited, one with other bytes is not',
        () {
      adapter.handleFrame(advert());
      adapter.handleFrame(verified);
      adapter.handleFrame(advert(path: [0xBE, 0xEF]));
      adapter.handleFrame(advert(name: 'Forged', path: [0xAD, 0x77]));
      final doorsteps =
          graph.ingressCandidates(owner).map((c) => c.repeaterHash).toSet();
      expect(doorsteps, {'1312', 'BEEF'});
      expect(graph.snapshot().nodes['A277']!.name, 'Alpha');
    });

    test('the firmware\'s rejects are rejected here too', () {
      final ok = Uint8List.fromList([(0x05 << 2) | 0x01, 0x41, 0xA2, 0x77, 9]);
      expect(parseRawPacket(ok), isNotNull);
      // Payload version 1.
      expect(parseRawPacket(Uint8List.fromList([0x40 | ok[0], ...ok.sublist(1)])),
          isNull);
      // Path mode 3 (reserved width).
      expect(parseRawPacket(Uint8List.fromList([ok[0], 0xC1, 0xA2, 0x77, 0, 0, 9])),
          isNull);
      // 33 two-byte hops = 66 path bytes, more than the 64 a packet holds.
      expect(
          parseRawPacket(Uint8List.fromList(
              [ok[0], 0x40 | 33, ...List.filled(66, 0x11), 9])),
          isNull);
    });
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
    expect(graph.counters.droppedNarrow, 1);
  });

  test('packet log says what happened to each packet', () {
    adapter.handleFrame(rxFrame(
        payloadType: 0x05,
        path: [0xA2, 0x77, 0xBE, 0xEF, 0xAD, 0x77],
        payload: [9, 8, 7, 6, 5, 4, 3, 2]));
    expect(adapter.packetLog.first.kind, 'channel');
    expect(adapter.packetLog.first.path, 'A277 › BEEF › AD77');
    expect(adapter.packetLog.first.verdict, 'recorded — 2 new links');
    expect(adapter.packetLog.first.rxSnr, 8.0);

    adapter.handleFrame(rxFrame(
        payloadType: 0x05,
        path: [0xA2, 0x77, 0xBE, 0xEF, 0xAD, 0x77],
        payload: [1, 1, 1, 1, 1, 1, 1, 1]));
    expect(adapter.packetLog.first.verdict, 'recorded — links already known');

    adapter.handleFrame(rxFrame(
        payloadType: 0x02, path: [0xA2, 0x13], payload: [1], stride: 1));
    expect(adapter.packetLog.first.kind, 'dm');
    expect(adapter.packetLog.first.path, 'A2 › 13');
    expect(adapter.packetLog.first.verdict, startsWith('dropped — 1-byte'));

    adapter.handleFrame(rxFrame(payloadType: 0x03, path: [], payload: [7]));
    expect(adapter.packetLog.first.verdict, 'direct — no repeater in the path');

    adapter.handleFrame(
        rxFrame(payloadType: 0x09, path: [0x20, 0x1C], payload: [0xAA]));
    expect(adapter.packetLog.first.kind, 'trace');
    expect(adapter.packetLog.first.verdict, startsWith('skipped'));
    expect(adapter.packetLog, hasLength(5));
  });

  test('TRACE frames are skipped entirely', () {
    adapter.handleFrame(rxFrame(
        payloadType: 0x09, path: [0x20, 0x1C], payload: [0xAA]));
    expect(adapter.tracesSkipped, 1);
    expect(graph.snapshot().edges, isEmpty);
  });

  // [0x89][reserved][path_len][flags][tag x4][auth x4][hashes][snr per hop][final snr]
  Uint8List traceFrame({required List<int> tag}) => Uint8List.fromList([
        0x89, 0, 4, 1, ...tag, 0, 0, 0, 0, //
        0xA2, 0x77, 0xBE, 0xEF, // hops A277 then BEEF, 2-byte hashes
        16, 40, // A277 heard me at 4 dB, BEEF heard A277 at 10 dB
        -8 & 0xFF, // I heard BEEF at -2 dB
      ]);

  test('my own trace proves its first hop with the measured uplink', () {
    adapter.expectedTraceTag = 0x04030201;
    adapter.handleFrame(traceFrame(tag: [1, 2, 3, 4]));
    final mine = {for (final c in graph.egressCandidates()) c.repeaterHash: c};
    expect(mine['A277']!.proven, isTrue);
    expect(mine['A277']!.uplinkSnr, closeTo(4.0, 1e-9));
    expect(mine['BEEF']!.proven, isFalse, reason: 'BEEF heard A277, not me');
    expect(adapter.lastTrace, isNotNull);
  });

  test('a trace that is not mine proves nothing — its last hop is heard only',
      () {
    // Field: a stranger traced 1000 → …; 1000's final retransmission reached
    // this radio and 1000 was filed as hearing it at the stranger's level.
    adapter.expectedTraceTag = null;
    adapter.handleFrame(traceFrame(tag: [1, 2, 3, 4]));
    adapter.expectedTraceTag = 0x99999999;
    adapter.handleFrame(traceFrame(tag: [1, 2, 3, 4]));
    final mine = {for (final c in graph.egressCandidates()) c.repeaterHash: c};
    expect(mine.containsKey('A277'), isFalse);
    final beef = mine['BEEF']!;
    expect(beef.proven, isFalse);
    expect(beef.tier, EvidenceTier.inferred);
    expect(beef.uplinkSnr, isNull);
    expect(beef.downlinkSnr, closeTo(-2.0, 1e-9));
    expect(adapter.packetLog.first.verdict, contains('not mine'));
    expect(adapter.lastTrace, isNull);
  });

  test('a 1-byte trace is dropped, never glued into a 2-byte phantom', () {
    // Audit: hops were cut at the radio's width, so the 1-byte route A2,AA
    // became the proven repeater "A2AA". The trace carries its own width.
    final oneByte = Uint8List.fromList([
      0x89, 0, 2, 0, 1, 2, 3, 4, 0, 0, 0, 0, //
      0xA2, 0xAA, // two 1-byte hops
      16, 40, -8 & 0xFF, // one SNR per hop + final
    ]);
    adapter.expectedTraceTag = 0x04030201;
    adapter.handleFrame(oneByte);
    adapter.expectedTraceTag = null;
    adapter.handleFrame(oneByte);
    expect(graph.egressCandidates(), isEmpty);
    expect(graph.snapshot().nodes.containsKey('A2AA'), isFalse);
    expect(adapter.lastTrace, isNull);
    expect(adapter.packetLog.first.verdict, contains('1-byte hashes are too narrow'));
  });

  test('a 4-byte trace files 2-byte buckets with aligned levels', () {
    adapter.expectedTraceTag = 0x04030201;
    adapter.handleFrame(Uint8List.fromList([
      0x89, 0, 8, 2, 1, 2, 3, 4, 0, 0, 0, 0, //
      0xA2, 0x77, 0x01, 0x02, 0xBE, 0xEF, 0x03, 0x04, // two 4-byte hops
      16, 40, -8 & 0xFF,
    ]));
    expect(adapter.lastTrace!.hops, ['A277', 'BEEF']);
    expect(adapter.lastTrace!.snrs, hasLength(3));
    final mine = {for (final c in graph.egressCandidates()) c.repeaterHash: c};
    expect(mine['A277']!.uplinkSnr, closeTo(4.0, 1e-9));
  });

  group('what a packet proves', () {
    const bobPk = '5b' '5b' '5b' '5b' '5b' '5b' '5b' '5b' '5b' '5b' '5b' '5b'
        '5b' '5b' '5b' '5b' '5b' '5b' '5b' '5b' '5b' '5b' '5b' '5b' '5b' '5b'
        '5b' '5b' '5b' '5b' '5b' '5b';
    Map<String, Candidate> mine() =>
        {for (final c in graph.egressCandidates()) c.repeaterHash: c};

    test('a direct packet files nothing: its path is the hops ahead', () {
      // Field: our own post retransmitted by A277 with AD77,41B1,BEEF still
      // ahead; strangers' direct DMs with their next hop in the path.
      for (final route in const [0x02, 0x03]) {
        adapter.handleFrame(rxFrame(
            payloadType: 0x02,
            path: [0xAD, 0x77, 0x41, 0xB1, 0xBE, 0xEF],
            payload: [0x5B, 0xAB, 1, 1],
            routeType: route));
        adapter.handleFrame(rxFrame(
            payloadType: 0x03, path: [], payload: [1, 2, 3, 4],
            routeType: route));
      }
      expect(graph.snapshot().edges, isEmpty);
      expect(graph.egressCandidates(), isEmpty);
      expect(graph.ingressCandidates(bobPk), isEmpty);
      expect(adapter.packetLog.first.verdict, startsWith('direct — carries'));
    });

    test('my own flooded DM echo proves its first hop, once per attempt', () {
      adapter.noteAttempt(0x5B, 0);
      // dest Bob (5B), src me (AB): two copies of one attempt via A277.
      adapter.handleFrame(rxFrame(
          payloadType: 0x02, path: [0xA2, 0x77], payload: [0x5B, 0xAB, 7, 7]));
      adapter.handleFrame(rxFrame(
          payloadType: 0x02,
          path: [0xA2, 0x77, 0x10, 0x00],
          payload: [0x5B, 0xAB, 7, 7]));
      final a277 = mine()['A277']!;
      expect(a277.proven, isTrue);
      expect(a277.provenCount, 1, reason: 'copies of one send are one proof');
      expect(adapter.echoAlreadyProved(bobPk, 'A277'), isTrue);
      expect(adapter.echoAlreadyProved(bobPk, 'a277'), isTrue,
          reason: 'the service spells hashes in lowercase');
      expect(adapter.echoAlreadyProved(bobPk, '1000'), isFalse);
    });

    test('a flooded DM under my byte with no attempt in flight is not mine',
        () {
      adapter.handleFrame(rxFrame(
          payloadType: 0x02, path: [0xA2, 0x77], payload: [0x5B, 0xAB, 7, 7]));
      expect(mine()['A277']!.proven, isFalse, reason: 'heard-only (R1)');
      // An attempt to a contact with another first byte does not gate it.
      adapter.noteAttempt(0x3F, 0);
      adapter.handleFrame(rxFrame(
          payloadType: 0x02, path: [0xBE, 0xEF], payload: [0x5B, 0xAB, 7, 7]));
      expect(mine()['BEEF']!.proven, isFalse);
    });

    test('a direct copy of my own DM proves nothing', () {
      adapter.noteAttempt(0x5B, 0);
      adapter.handleFrame(rxFrame(
          payloadType: 0x02,
          path: [0xA2, 0x77],
          payload: [0x5B, 0xAB, 7, 7],
          routeType: 0x02));
      expect(graph.egressCandidates(), isEmpty);
    });

    test('a contact sharing my first byte: [X][X] proves nothing', () {
      // My key and theirs both start 0xAB: my DM to them and theirs to me
      // carry the same two address bytes.
      adapter.noteAttempt(0xAB, 0);
      adapter.handleFrame(rxFrame(
          payloadType: 0x02, path: [0xA2, 0x77], payload: [0xAB, 0xAB, 7, 7]));
      expect(mine()['A277']!.proven, isFalse);
    });

    test('their ACK closes the window: a later matching flood is not mine',
        () {
      adapter.noteAttempt(0x5B, 0);
      adapter.attributeAck(bobPk, 0x12345678);
      adapter.handleFrame(rxFrame(
          payloadType: 0x02, path: [0xA2, 0x77], payload: [0x5B, 0xAB, 7, 7]));
      expect(mine()['A277']!.proven, isFalse);
    });

    test('a closed attempt still remembers what it proved', () {
      adapter.noteAttempt(0x5B, 0);
      adapter.handleFrame(rxFrame(
          payloadType: 0x02, path: [0xA2, 0x77], payload: [0x5B, 0xAB, 7, 7]));
      adapter.noteAttempt(0x5B, 1);
      expect(adapter.echoAlreadyProved(bobPk, 'A277'), isTrue,
          reason: 'the delivery that follows must not prove A277 again');
    });

    test('my own login echo is mine by its full key, no gate needed', () {
      final me = List<int>.filled(32, 0xAB);
      adapter.handleFrame(rxFrame(
          payloadType: 0x07, path: [0xA2, 0x77], payload: [0x3F, ...me, 9]));
      adapter.handleFrame(rxFrame(
          payloadType: 0x07,
          path: [0xA2, 0x77, 0xAD, 0x77],
          payload: [0x3F, ...me, 9]));
      expect(mine()['A277']!.proven, isTrue);
      expect(mine()['A277']!.provenCount, 1);
      // Same first byte, different key: not mine.
      final other = [0xAB, ...List<int>.filled(31, 0xCD)];
      adapter.handleFrame(rxFrame(
          payloadType: 0x07, path: [0xBE, 0xEF], payload: [0x3F, ...other, 9]));
      expect(mine()['BEEF']!.proven, isFalse);
    });

    test('a flooded ACK is credited by its hash when the radio confirms it',
        () {
      // Bob's ACK (companion: hash + attempt + random) came 1000 › A277,
      // then via 4000 › AD77 › A277; a stranger's ACK too.
      adapter.handleFrame(rxFrame(
          payloadType: 0x03,
          path: [0x10, 0x00, 0xA2, 0x77],
          payload: [0x78, 0x56, 0x34, 0x12, 0, 9]));
      adapter.handleFrame(rxFrame(
          payloadType: 0x03,
          path: [0x40, 0x00, 0xAD, 0x77, 0xA2, 0x77],
          payload: [0x78, 0x56, 0x34, 0x12, 0, 9]));
      adapter.handleFrame(rxFrame(
          payloadType: 0x03, path: [0xBE, 0xEF], payload: [1, 2, 3, 4]));
      expect(graph.ingressCandidates(bobPk), isEmpty);

      adapter.attributeAck(bobPk, 0x12345678);
      final theirs = graph.ingressCandidates(bobPk);
      expect(theirs.single.repeaterHash, '1000');
      expect(theirs.single.heard, isTrue);
      expect(theirs.single.proven, isFalse);
      expect(adapter.packetLog.first.kind, 'ack');
      expect(adapter.packetLog.first.verdict, contains('also heard via'));
      expect((graph.findReturnPath(bobPk) as RouteResult).pathBytes,
          [0x10, 0x00, 0xA2, 0x77]);

      adapter.attributeAck(bobPk, 0x99999999);
      expect(adapter.packetLog.first.verdict, contains('no flood to learn'));
      expect(graph.ingressCandidates(bobPk), hasLength(1));
    });

    test('a flooded ACK with no path means they were heard directly', () {
      adapter.handleFrame(rxFrame(
          payloadType: 0x03, path: [], payload: [0x78, 0x56, 0x34, 0x12]));
      adapter.attributeAck(bobPk, 0x12345678);
      expect(graph.ingressCandidates(bobPk).single.repeaterHash, directHash);
    });
  });

  test('a PATH reply flood is credited to the contact the radio names', () {
    // Field (2026-10-13): a room's reply to a flooded login reached
    // this radio room → BEEF → me, then again via 1000, AD77, A277. The
    // payload is encrypted; only its first two bytes (dest, src) show.
    const roomPk = '3f' '3f' '3f' '3f' '3f' '3f' '3f' '3f' '3f' '3f' '3f' '3f'
        '3f' '3f' '3f' '3f' '3f' '3f' '3f' '3f' '3f' '3f' '3f' '3f' '3f' '3f'
        '3f' '3f' '3f' '3f' '3f' '3f';
    adapter.handleFrame(rxFrame(
        payloadType: 0x08, path: [0xBE, 0xEF], payload: [0xAB, 0x3F, 9, 9]));
    adapter.handleFrame(rxFrame(
        payloadType: 0x08,
        path: [0x10, 0x00, 0xAD, 0x77, 0xA2, 0x77],
        payload: [0xAB, 0x3F, 9, 9]));
    // A reply to somebody else from the same first byte is not mine.
    adapter.handleFrame(rxFrame(
        payloadType: 0x08, path: [0x13, 0x12], payload: [0x20, 0x3F, 9, 9]));
    expect(graph.ingressCandidates(roomPk), isEmpty,
        reason: 'encrypted: nothing is credited until the radio says whose');

    adapter.attributePathReply(roomPk); // the PATH_UPDATED moment
    final theirs = graph.ingressCandidates(roomPk);
    expect(theirs.single.repeaterHash, 'BEEF',
        reason: 'the earliest copy is the one the radio acted on');
    expect(theirs.single.heard, isTrue);
    expect(theirs.single.proven, isFalse);
    expect(adapter.packetLog.first.kind, 'path reply');
    expect(adapter.packetLog.first.verdict, contains('also heard via'));

    // I heard BEEF last on that same packet: the way back is BEEF alone.
    final back = graph.findReturnPath(roomPk);
    expect(back, isA<RouteResult>());
    expect((back as RouteResult).pathBytes, [0xBE, 0xEF]);

    // Nothing left to match a second time.
    adapter.attributePathReply(roomPk);
    expect(adapter.packetLog.first.verdict, contains('no logged flood'));
  });

  group('a PATH reply is credited exactly or not at all', () {
    final roomPk = '3f' * 32;
    Uint8List reply(List<int> path, int tag) => rxFrame(
        payloadType: 0x08, path: path, payload: [0xAB, 0x3F, tag, tag]);

    test('two different replies carrying the room\'s byte: nobody', () {
      adapter.handleFrame(reply([0xBE, 0xEF], 1));
      adapter.handleFrame(reply([0x10, 0x00], 2));
      adapter.attributePathReply(roomPk);
      expect(graph.ingressCandidates(roomPk), isEmpty);
      expect(adapter.packetLog.first.verdict, contains('different replies'));
      expect(adapter.messagesAttributed, 0);
    });

    test('another contact shares the room\'s first byte: nobody', () {
      graph.ingestContact('3f${'00' * 31}', 'Other');
      adapter.handleFrame(reply([0xBE, 0xEF], 1));
      adapter.attributePathReply(roomPk);
      expect(graph.ingressCandidates(roomPk), isEmpty);
      expect(adapter.packetLog.first.verdict, contains('same byte'));
    });

    test('a copy arriving after the credit is not kept for the next reply',
        () {
      adapter.handleFrame(reply([0xBE, 0xEF], 1));
      adapter.attributePathReply(roomPk);
      adapter.handleFrame(reply([0x10, 0x00, 0xBE, 0xEF], 1));
      adapter.attributePathReply(roomPk);
      expect(adapter.packetLog.first.verdict, contains('no logged flood'));
      expect(graph.ingressCandidates(roomPk).single.repeaterHash, 'BEEF');
    });
  });

  test('a matched DM with 1-byte hashes is logged as dropped, not credited',
      () {
    final sender = '5b' * 32;
    adapter.handleFrame(rxFrame(
        payloadType: 0x02,
        path: [0xA2, 0x13],
        payload: [0xAB, 0x5B, 1, 2, 3],
        stride: 1));
    adapter.attributeContactMessage(sender, 0x02, 32); // 2 hops, 1 byte
    expect(adapter.messagesAttributed, 0);
    expect(adapter.packetLog.first.verdict, startsWith('from'));
    expect(adapter.packetLog.first.verdict, contains('1-byte hashes'));
    expect(graph.ingressCandidates(sender), isEmpty);
  });

  test('a discovery reply with 1-byte paths mints no 2-byte repeater', () {
    // Field: "A2AA" appeared as a proven doorstep for months. It was the
    // 1-byte route A2,AA from a reply, handed to the graph without its
    // width and read as one 2-byte hash. The width travels with the bytes.
    final contact = 'b0' * 32;
    adapter.beginDiscovery(contact, 'asking');
    const pathLen = (0 << 6) | 2; // stride 1, 2 hops
    adapter.handleFrame(Uint8List.fromList([
      0x8D, 0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0, 0xB0,
      pathLen, 0xA2, 0xAA,
      pathLen, 0xAA, 0xA2,
    ]));
    expect(graph.egressCandidates(), isEmpty);
    expect(graph.ingressCandidates(contact), isEmpty);
    expect(graph.snapshot().nodes.containsKey('A2AA'), isFalse);
    expect(graph.counters.droppedNarrow, 2,
        reason: 'both paths dropped as narrower than the graph');
  });

  group('path discovery', () {
    final contact = 'b0' * 32;
    final pathLen = (1 << 6) | 2; // stride 2, 2 hops
    // [0x8D][rsv][prefix x6][out_len][out][in_len][in]
    // out = A277,1312 (us->them); in = 5CBB,249F (them->us)
    Uint8List reply({int prefixByte = 0xB0, int inLen = -1, List<int>? inPath}) =>
        Uint8List.fromList([
          0x8D, 0, ...List.filled(6, prefixByte),
          pathLen, 0xA2, 0x77, 0x13, 0x12,
          inLen < 0 ? pathLen : inLen, ...(inPath ?? [0x5C, 0xBB, 0x24, 0x9F]),
        ]);
    final sent = Uint8List.fromList([6, 0, 0, 0, 0, 0, 0x30, 0x75, 0, 0]);

    test('feeds both paths, once each, without tallying the corridor', () {
      adapter.beginDiscovery(contact, 'asking');
      adapter.handleFrame(reply());

      final snap = graph.snapshot();
      // One answered exchange is not an attempt count on every link.
      final out = snap.edges[('A277', '1312')]!;
      expect((out.s, out.n), (0, 0));
      // The return path's links came in through the raw feed, not here.
      expect(snap.edges.containsKey(('5CBB', '249F')), isFalse);
      // The outbound path's last hop reached them: proven ingress. The
      // return path's first hop only heard them: a guess, kept as inferred.
      final ingress = {
        for (final c in graph.ingressCandidates(contact)) c.repeaterHash: c
      };
      expect(ingress['1312']!.proven, isTrue);
      expect(ingress['5CBB']!.proven, isFalse);
      expect(ingress['5CBB']!.tier, EvidenceTier.inferred);
      expect(ingress['5CBB']!.finalCount, 1);
      // My doorstep proven from the outbound first hop.
      expect(graph.egressCandidates().map((c) => c.repeaterHash),
          contains('A277'));
      expect(adapter.discoveryStatus[contact], contains('B0B0B0B0B0B0'));
      expect(adapter.pendingDiscoveryPubkey, isNull);
    });

    test('a reply for another contact is not credited to the one asked', () {
      adapter.beginDiscovery(contact, 'asking');
      adapter.handleFrame(reply(prefixByte: 0xC0));
      expect(graph.ingressCandidates(contact), isEmpty);
      expect(graph.ingressCandidates('c0' * 32), isEmpty);
      // It answered my flood all the same: its first hop heard me.
      expect(graph.egressCandidates().map((c) => c.repeaterHash),
          contains('A277'));
      expect(adapter.pendingDiscoveryPubkey, contact, reason: 'still waiting');
    });

    test('only the first SENT or ERR answers the request', () {
      adapter.beginDiscovery(contact, 'asking');
      adapter.handleFrame(sent);
      adapter.handleFrame(Uint8List.fromList([1, 3])); // another command's
      expect(adapter.pendingDiscoveryPubkey, contact);
      expect(adapter.discoveryStatus[contact], startsWith('accepted'));
    });

    test('a refused request: a reply after it credits nobody', () {
      adapter.beginDiscovery(contact, 'asking');
      adapter.handleFrame(Uint8List.fromList([1, 2]));
      expect(adapter.discoveryStatus[contact], startsWith('REJECTED'));
      adapter.handleFrame(reply());
      expect(graph.ingressCandidates(contact), isEmpty);
    });

    test('a narrow return path drops only that side', () {
      adapter.beginDiscovery(contact, 'asking');
      adapter.handleFrame(reply(inLen: 2, inPath: [0x5C, 0x24])); // 1-byte
      expect(graph.ingressCandidates(contact).map((c) => c.repeaterHash),
          ['1312']);
      expect(graph.counters.droppedNarrow, 1);
    });
  });

  test('discover responses parse uplink SNR and commit as egress', () {
    // [0x8E][rx snr][rssi][path_len] then ctl: [0x92][uplink snr][tag x4][pk]
    adapter.expectedDiscoverTag = 0x04030201;
    adapter.handleFrame(Uint8List.fromList(
        [0x8E, 40, 0, 0, 0x92, 30, 1, 2, 3, 4, ...pubkey]));
    expect(adapter.pendingDiscover.single.uplinkSnr, closeTo(7.5, 1e-9));
    adapter.commitDiscover(failureEpisode: false);
    expect(graph.egressCandidates().single.repeaterHash, 'A277');
    expect(graph.egressCandidates().single.tier, EvidenceTier.proven);
  });

  test('a discover reply to a request that is not mine proves nothing', () {
    // Field: a mountaintop 30 miles out answered a neighbour's scan at
    // +11.75 dB and was filed as hearing this radio at +11.75 dB.
    final reply = [0x8E, 40, 0, 0, 0x92, 47, 1, 2, 3, 4, ...pubkey];
    adapter.expectedDiscoverTag = null; // no request of ours is out
    adapter.handleFrame(Uint8List.fromList(reply));
    adapter.expectedDiscoverTag = 0x99999999; // ours has another tag
    adapter.handleFrame(Uint8List.fromList(reply));
    expect(adapter.pendingDiscover, isEmpty);
    expect(adapter.packetLog.first.verdict, contains('not mine'));
    adapter.commitDiscover(failureEpisode: false);
    // Its reply did reach me, so it counts as heard — never as hearing me.
    final heard = graph.egressCandidates().single;
    expect(heard.repeaterHash, 'A277');
    expect(heard.proven, isFalse);
    expect(heard.tier, EvidenceTier.inferred);
    expect(heard.downlinkSnr, closeTo(10.0, 1e-9));
    expect(heard.uplinkSnr, isNull);
  });

  group('flooded DMs are matched to their sender', () {
    // The radio's key starts 0xAB (setUp); the sender's starts 0x5B.
    final sender = '5b' * 32;
    Uint8List dm({
      required List<int> path,
      int snrQuarterDb = 32,
      int dest = 0xAB,
      int src = 0x5B,
    }) =>
        rxFrame(
            payloadType: 0x02,
            path: path,
            payload: [dest, src, 0x11, 0x22, 1, 2, 3],
            snrQuarterDb: snrQuarterDb);

    double weightOf(String hash) => graph
        .ingressCandidates(sender)
        .firstWhere((c) => c.repeaterHash == hash)
        .weight;

    test('the logged packet credits the sender\'s doorstep, once', () {
      adapter.handleFrame(dm(path: [0xA2, 0x77, 0x13, 0x12]));
      adapter.attributeContactMessage(sender, 0x42, 32);

      final row = graph.ingressCandidates(sender).single;
      expect(row.repeaterHash, 'A277');
      expect(row.weight, closeTo(3.0, 0.01), reason: 'the MAC proved the key');
      expect(row.heard, isTrue);
      expect(adapter.messagesAttributed, 1);
      expect(adapter.packetLog.first.verdict, contains('heard by A277'));

      adapter.attributeContactMessage(sender, 0x42, 32);
      expect(weightOf('A277'), closeTo(3.0, 0.01), reason: 'the packet was consumed');
      expect(adapter.packetLog.first.verdict, contains('no logged packet'));
    });

    test('a sender sharing my first byte is not credited from [X][X]', () {
      final twin = 'ab' * 31 + 'cd';
      // Could be my own echo to them, or theirs to me: not kept.
      adapter.handleFrame(dm(path: [0xA2, 0x77, 0x13, 0x12], src: 0xAB));
      adapter.attributeContactMessage(twin, 0x42, 32);
      expect(graph.ingressCandidates(twin), isEmpty);
    });

    test('a weak signal (negative SNR) still matches', () {
      adapter.handleFrame(dm(path: [0xA2, 0x77, 0x13, 0x12], snrQuarterDb: 0xE8));
      adapter.attributeContactMessage(sender, 0x42, -24);
      expect(graph.ingressCandidates(sender).single.repeaterHash, 'A277');
    });

    test('the signal byte picks the right copy', () {
      adapter.handleFrame(dm(path: [0xA2, 0x77, 0x13, 0x12], snrQuarterDb: 32));
      adapter.handleFrame(dm(path: [0x5C, 0xBB, 0x13, 0x12], snrQuarterDb: 20));
      adapter.attributeContactMessage(sender, 0x42, 20);
      expect(graph.ingressCandidates(sender).single.repeaterHash, '5CBB');
    });

    test('copies sharing the first repeater are one sighting', () {
      adapter.handleFrame(dm(path: [0xA2, 0x77, 0x13, 0x12]));
      adapter.handleFrame(dm(path: [0xA2, 0x77, 0x5C, 0xBB]));
      adapter.attributeContactMessage(sender, 0x42, 32);
      expect(weightOf('A277'), closeTo(3.0, 0.01));
      expect(adapter.messagesAttributed, 1);
    });

    test('copies that differ on the first repeater credit nobody', () {
      adapter.handleFrame(dm(path: [0xA2, 0x77, 0x13, 0x12]));
      adapter.handleFrame(dm(path: [0x5C, 0xBB, 0x13, 0x12]));
      adapter.attributeContactMessage(sender, 0x42, 32);
      expect(graph.ingressCandidates(sender), isEmpty);
      expect(adapter.packetLog.first.verdict, contains('credited nobody'));
    });

    test('a direct message carries no path and is ignored', () {
      adapter.handleFrame(dm(path: [0xA2, 0x77, 0x13, 0x12]));
      adapter.attributeContactMessage(sender, 0xFF, 32);
      expect(graph.ingressCandidates(sender), isEmpty);
    });

    test('own echoes and messages for others never match', () {
      // An echo of my own DM to them: src is me, dest is them.
      adapter.handleFrame(dm(path: [0xA2, 0x77, 0x13, 0x12], dest: 0x5B, src: 0xAB));
      // Someone else's DM from the same sender.
      adapter.handleFrame(dm(path: [0xA2, 0x77, 0x13, 0x12], dest: 0x99));
      adapter.attributeContactMessage(sender, 0x42, 32);
      expect(graph.ingressCandidates(sender), isEmpty);
    });

    test('a zero-hop flood is direct only when its packet was logged', () {
      adapter.attributeContactMessage(sender, 0x40, 32);
      expect(graph.ingressCandidates(sender), isEmpty,
          reason: 'a message synced hours later is not a live sighting');

      adapter.handleFrame(dm(path: []));
      adapter.attributeContactMessage(sender, 0x40, 32);
      expect(graph.ingressCandidates(sender).map((c) => c.repeaterHash),
          contains(directHash));
    });

    test('attribution files no second set of links or last-hop prior', () {
      adapter.handleFrame(dm(path: [0xA2, 0x77, 0x13, 0x12, 0x5C, 0xBB]));
      final edges = graph.edgeCount;
      final mine = graph.egressCandidates().length;
      adapter.attributeContactMessage(sender, 0x43, 32);
      expect(graph.edgeCount, edges);
      expect(graph.egressCandidates().length, mine);
    });
  });
}
