import 'dart:typed_data';

import 'package:test/test.dart';

import 'package:traxpix/src/photo_chunks.dart';
import 'package:traxpix/src/photo_tag.dart';
import 'package:traxpix/src/rate_point.dart';

Uint8List payloadOf(int length, {int seed = 7}) => Uint8List.fromList(
  List<int>.generate(length, (i) => (i * 37 + seed * 11) & 0xFF),
);

const ImageStreamMetadata ft8Meta = ImageStreamMetadata(
  rate: ImageCodecRatePoint.ft8,
);

const int senderA = 0x1234;
const int senderB = 0xBEEF;

/// A copy of [blob] with the byte at [offset] flipped by [mask].
Uint8List flipByte(Uint8List blob, int offset, {int mask = 0x01}) {
  final copy = Uint8List.fromList(blob);
  copy[offset] ^= mask;
  return copy;
}

/// Feeds [blobs] to [r] in the given order and returns the completed image, if
/// any completed.
ImageReassemblyResult? feed(
  ImageReassembler r,
  List<Uint8List> blobs, {
  int channelIndex = 0,
  DateTime? now,
}) {
  ImageReassemblyResult? result;
  for (final blob in blobs) {
    final outcome = r.addChunk(blob, channelIndex: channelIndex, now: now);
    result ??= outcome.result;
  }
  return result;
}

void main() {
  group('constants', () {
    test('every blob fits the binding transport limit', () {
      expect(kImageChunkBlobBytes, 157);
      expect(kImageChunkHeaderBytes, 4);
      expect(kImageChunkBodyBytes, 152);
      // Chunk 0 spends 1 byte on metadata and nothing else: the CRC-16 that
      // briefly lived here was removed once it turned out the LoRa PHY CRC and
      // MeshCore's per-packet HMAC already cover a delivered chunk.
      expect(kImageChunkMetadataBytes, 1);
      expect(kImageChunkZeroMetadataBytes, 1);
      expect(kImageChunkFirstCapacity, 151);
      expect(kImageChunkCapacity, 152);
      expect(kImageMaxPayloadBytes, 151 + 14 * 152);
    });

    test('a full photo packet fits the raw log with a 3-repeater path', () {
      // The radio copies heard packets to the app only up to 173 bytes; a
      // path of 3 repeaters with 2-byte IDs adds 6.
      expect(kPhotoPacketAirBytes, 165);
      expect(kPhotoPacketAirBytes + 3 * 2, lessThanOrEqualTo(173));
    });

    test('ft8 sizes land on the expected chunk counts', () {
      // Chunk 0 carries 151 image bytes, every later chunk 152.
      expect(imageDataChunkCount(151), 1);
      expect(imageDataChunkCount(152), 2);
      // ft8: the smallest measured photo takes 2 data chunks, the mean 3, the
      // busiest 6 -- plus the repair chunk on air.
      expect(imageDataChunkCount(ImageCodecRateStats.ft8.minBytes), 2);
      expect(imageDataChunkCount(ImageCodecRateStats.ft8.meanBytes), 3);
      expect(imageDataChunkCount(ImageCodecRateStats.ft8.maxBytes), 6);
    });
  });

  group('metadata byte', () {
    test('round-trips every rate point', () {
      for (final rate in ImageCodecRatePoint.values) {
        final meta = ImageStreamMetadata(rate: rate);
        expect(ImageStreamMetadata.decode(meta.encode()), meta);
      }
    });

    test('rejects an unrepresentable resolution', () {
      expect(
        () => const ImageStreamMetadata(
          rate: ImageCodecRatePoint.ft8,
          squareSize: 999,
        ).encode(),
        throwsArgumentError,
      );
    });

    test('an unknown RATE code is what signals a format break', () {
      // The byte is tag(1) | reserved(3) | resolution(2) | rate(2). Resolution
      // is a closed
      // 2-bit field: all four codes are legal. Rate is where an incompatible
      // format shows: only ft8 (2) decodes here; codes 0, 1 and 3 are rejected
      // instead of guessed at.
      expect(ImageStreamMetadata.decode(0x00), isNull);
      expect(ImageStreamMetadata.decode(0x01), isNull);
      expect(ImageStreamMetadata.decode(0x03), isNull); // spare
      // 0xF2 has the tag bit and all three reserved bits set, resolution 0,
      // rate 2: still a photo; the reserved bits are ignored.
      final legal = ImageStreamMetadata.decode(0xF2);
      expect(legal, isNotNull);
      expect(legal!.rate, ImageCodecRatePoint.ft8);
      expect(legal.hasTag, isTrue);
    });
  });

  group('chunking', () {
    test('one, two and three chunk payloads produce the right blob shapes', () {
      final cases = <int, int>{
        1: 1,
        kImageChunkFirstCapacity: 1,
        kImageChunkFirstCapacity + 1: 2,
        kImageChunkFirstCapacity + kImageChunkCapacity: 2,
        kImageChunkFirstCapacity + kImageChunkCapacity + 1: 3,
      };
      cases.forEach((length, expectedChunks) {
        final set = buildImageChunks(
          payload: payloadOf(length),
          metadata: ft8Meta,
          senderPrefix: senderA,
          imgId: 3,
        );
        expect(set.dataChunkCount, expectedChunks, reason: 'len $length');
        expect(set.blobs.length, expectedChunks + 1); // + parity
        for (final blob in set.blobs) {
          expect(blob.length, lessThanOrEqualTo(kImageChunkBlobBytes));
        }
      });
    });

    test('header fields are on the wire where the spec says', () {
      final set = buildImageChunks(
        payload: payloadOf(400),
        metadata: ft8Meta,
        senderPrefix: senderA,
        imgId: 0x5A,
      );
      expect(set.dataChunkCount, 3);
      for (var i = 0; i < set.blobs.length; i++) {
        final blob = set.blobs[i];
        expect(blob[0], 0x12);
        expect(blob[1], 0x34);
        expect(blob[2], 0x5A);
        expect((blob[3] >> 4) & 0x0F, i);
        expect(blob[3] & 0x0F, 3);
      }
      expect(parseImageChunkHeader(set.blobs.last)!.isParity, isTrue);
      expect(set.blobs[4 - 1].length, greaterThan(kImageChunkHeaderBytes));
      // Chunk 0 carries the metadata byte first.
      expect(set.blobs[0][kImageChunkHeaderBytes], ft8Meta.encode());
    });

    test('rejects a payload larger than the framing can address', () {
      expect(
        () => buildImageChunks(
          payload: payloadOf(kImageMaxPayloadBytes + 1),
          metadata: ft8Meta,
          senderPrefix: senderA,
          imgId: 1,
        ),
        throwsArgumentError,
      );
    });
  });

  group('round trip', () {
    for (final length in <int>[
      100, // 1 chunk
      300, // 2 chunks
      460, // 3 chunks
    ]) {
      test('$length bytes round-trips in order', () {
        final payload = payloadOf(length);
        final set = buildImageChunks(
          payload: payload,
          metadata: ft8Meta,
          senderPrefix: senderA,
          imgId: 11,
        );
        final r = ImageReassembler(selfPrefix: senderB);
        final result = feed(r, set.blobs);
        expect(result, isNotNull);
        expect(result!.data, payload);
        expect(result.metadata, ft8Meta);
        expect(result.recoveredWithParity, isFalse);
        expect(result.chunkCount, set.dataChunkCount);
        expect(r.pendingCount, 0, reason: 'trailing parity must not linger');
      });
    }

    test('completion callback fires exactly once', () {
      final payload = payloadOf(300);
      final set = buildImageChunks(
        payload: payload,
        metadata: ft8Meta,
        senderPrefix: senderA,
        imgId: 4,
      );
      final results = <ImageReassemblyResult>[];
      final r = ImageReassembler(onImage: results.add);
      feed(r, set.blobs);
      expect(results.length, 1);
      expect(results.single.data, payload);
    });

    test('out-of-order arrival still reassembles', () {
      final payload = payloadOf(450, seed: 3);
      final set = buildImageChunks(
        payload: payload,
        metadata: ft8Meta,
        senderPrefix: senderA,
        imgId: 9,
      );
      // All three data chunks arrive out of order, parity last (so this
      // exercises reordering, not parity recovery).
      final shuffled = <Uint8List>[
        set.blobs[2],
        set.blobs[0],
        set.blobs[1],
        set.blobs[3], // parity
      ];
      final r = ImageReassembler();
      final result = feed(r, shuffled);
      expect(result, isNotNull);
      expect(result!.data, payload);
      expect(result.recoveredWithParity, isFalse);
    });

    test('duplicate chunks are ignored', () {
      final payload = payloadOf(450); // 3 data chunks + parity
      final set = buildImageChunks(
        payload: payload,
        metadata: ft8Meta,
        senderPrefix: senderA,
        imgId: 2,
      );
      final r = ImageReassembler();
      expect(r.addChunk(set.blobs[0]).status, ImageChunkStatus.accepted);
      expect(r.addChunk(set.blobs[0]).status, ImageChunkStatus.duplicate);
      expect(r.addChunk(set.blobs[2]).status, ImageChunkStatus.accepted);
      expect(r.addChunk(set.blobs[2]).status, ImageChunkStatus.duplicate);
      final done = r.addChunk(set.blobs[1]);
      expect(done.status, ImageChunkStatus.completed);
      expect(done.result!.data, payload);
      expect(done.result!.recoveredWithParity, isFalse);
      // Trailing parity and late duplicates are ignored, not restarted.
      expect(r.addChunk(set.blobs[3]).status, ImageChunkStatus.duplicate);
      expect(r.addChunk(set.blobs[1]).status, ImageChunkStatus.duplicate);
      expect(r.pendingCount, 0);
    });

    test('a duplicate parity chunk is ignored', () {
      final set = buildImageChunks(
        payload: payloadOf(450),
        metadata: ft8Meta,
        senderPrefix: senderA,
        imgId: 15,
      );
      final r = ImageReassembler();
      expect(r.addChunk(set.blobs[3]).status, ImageChunkStatus.accepted);
      expect(r.addChunk(set.blobs[3]).status, ImageChunkStatus.duplicate);
      expect(r.pendingCount, 1);
    });

    test('parity completes an image that is one chunk short', () {
      final payload = payloadOf(300); // 2 data chunks
      final set = buildImageChunks(
        payload: payload,
        metadata: ft8Meta,
        senderPrefix: senderA,
        imgId: 16,
      );
      final r = ImageReassembler();
      expect(r.addChunk(set.blobs[0]).status, ImageChunkStatus.accepted);
      final done = r.addChunk(set.blobs[2]); // parity rebuilds chunk 1
      expect(done.status, ImageChunkStatus.completed);
      expect(done.result!.data, payload);
      expect(done.result!.recoveredWithParity, isTrue);
    });

    test('two senders interleaved on one channel do not mix', () {
      final a = payloadOf(300, seed: 1);
      final b = payloadOf(300, seed: 2);
      final setA = buildImageChunks(
        payload: a,
        metadata: ft8Meta,
        senderPrefix: senderA,
        imgId: 5,
      );
      final setB = buildImageChunks(
        payload: b,
        metadata: ft8Meta,
        senderPrefix: senderB,
        imgId: 5, // same img_id on purpose
      );
      final got = <int, Uint8List>{};
      final r = ImageReassembler(
        onImage: (res) => got[res.key.senderPrefix] = res.data,
      );
      feed(r, <Uint8List>[
        setA.blobs[0],
        setB.blobs[1],
        setA.blobs[1],
        setB.blobs[0],
      ]);
      expect(got[senderA], a);
      expect(got[senderB], b);
    });

    test('the same img_id on different channels stays separate', () {
      final payload = payloadOf(300);
      final set = buildImageChunks(
        payload: payload,
        metadata: ft8Meta,
        senderPrefix: senderA,
        imgId: 8,
      );
      final r = ImageReassembler();
      expect(
        r.addChunk(set.blobs[0], channelIndex: 0).status,
        ImageChunkStatus.accepted,
      );
      expect(
        r.addChunk(set.blobs[1], channelIndex: 1).status,
        ImageChunkStatus.accepted,
      );
      expect(r.pendingCount, 2);
    });

    test('clearChannel stops a reused slot finishing with old bytes', () {
      final oldSet = buildImageChunks(
        payload: payloadOf(300, seed: 1),
        metadata: ft8Meta,
        senderPrefix: senderA,
        imgId: 9,
      );
      final newPayload = payloadOf(300, seed: 2);
      final newSet = buildImageChunks(
        payload: newPayload,
        metadata: ft8Meta,
        senderPrefix: senderA,
        imgId: 9,
      );
      expect(newSet.dataChunkCount, greaterThanOrEqualTo(2));
      final failures = <ImageReassemblyFailure>[];
      final r = ImageReassembler(onFailed: failures.add);
      r.addChunk(oldSet.blobs[0], channelIndex: 3);
      r.addChunk(oldSet.blobs[0], channelIndex: 4);

      r.clearChannel(3);
      expect(failures.single.key.channelIndex, 3);
      expect(
        failures.single.reason,
        ImageReassemblyFailureReason.channelChanged,
      );
      expect(r.pendingKeys.single.channelIndex, 4);

      // Without the clear, these would complete with the old chunk 0.
      final dataBlobs = newSet.blobs.sublist(0, newSet.dataChunkCount);
      expect(feed(r, dataBlobs.sublist(1), channelIndex: 3), isNull);
      expect(feed(r, [dataBlobs[0]], channelIndex: 3)!.data, newPayload);
    });
  });

  group('parity recovery', () {
    test('recovers any single lost data chunk (2 and 3 chunk images)', () {
      for (final length in <int>[300, 460]) {
        final payload = payloadOf(length, seed: length);
        final set = buildImageChunks(
          payload: payload,
          metadata: ft8Meta,
          senderPrefix: senderA,
          imgId: 6,
        );
        for (var lost = 0; lost < set.dataChunkCount; lost++) {
          final blobs = <Uint8List>[
            for (var i = 0; i < set.blobs.length; i++)
              if (i != lost) set.blobs[i],
          ];
          final r = ImageReassembler();
          final result = feed(r, blobs);
          expect(result, isNotNull, reason: 'len $length lost $lost');
          expect(result!.data, payload, reason: 'len $length lost $lost');
          expect(result.metadata, ft8Meta);
          expect(result.recoveredWithParity, isTrue);
        }
      }
    });

    test('recovers the short final chunk (length is carried by parity)', () {
      // 158 + 1 => final chunk is a single byte long.
      final payload = payloadOf(kImageChunkFirstCapacity + 1);
      final set = buildImageChunks(
        payload: payload,
        metadata: ft8Meta,
        senderPrefix: senderA,
        imgId: 12,
      );
      expect(set.dataChunkCount, 2);
      final r = ImageReassembler();
      final result = feed(r, <Uint8List>[set.blobs[0], set.blobs[2]]);
      expect(result, isNotNull);
      expect(result!.data, payload);
      expect(result.recoveredWithParity, isTrue);
    });

    test('total=1 with parity recovers the only data chunk', () {
      final payload = payloadOf(100);
      final set = buildImageChunks(
        payload: payload,
        metadata: ft8Meta,
        senderPrefix: senderA,
        imgId: 1,
      );
      expect(set.dataChunkCount, 1);
      expect(set.blobs.length, 2);
      final r = ImageReassembler();
      final result = feed(r, <Uint8List>[set.blobs[1]]); // parity only
      expect(result, isNotNull);
      expect(result!.data, payload);
      expect(result.metadata, ft8Meta);
      expect(result.recoveredWithParity, isTrue);
    });

    test('losing two chunks fails and never yields a wrong image', () {
      final payload = payloadOf(450);
      final set = buildImageChunks(
        payload: payload,
        metadata: ft8Meta,
        senderPrefix: senderA,
        imgId: 7,
      );
      final r = ImageReassembler();
      // Deliver only chunk 1 and parity: two data chunks are missing.
      final result = feed(r, <Uint8List>[set.blobs[1], set.blobs[3]]);
      expect(result, isNull);
      expect(r.pendingCount, 1);
    });

    test('parity is optional', () {
      final payload = payloadOf(300);
      final set = buildImageChunks(
        payload: payload,
        metadata: ft8Meta,
        senderPrefix: senderA,
        imgId: 3,
        parity: false,
      );
      expect(set.hasParity, isFalse);
      expect(set.blobs.length, 2);
      final r = ImageReassembler();
      expect(feed(r, set.blobs)!.data, payload);
    });
  });

  group('TTL and eviction', () {
    test('a stalled image expires and is reported as failed', () {
      final set = buildImageChunks(
        payload: payloadOf(450),
        metadata: ft8Meta,
        senderPrefix: senderA,
        imgId: 21,
      );
      final failures = <ImageReassemblyFailure>[];
      final start = DateTime(2026, 1, 1, 12);
      final r = ImageReassembler(
        ttl: const Duration(seconds: 60),
        onFailed: failures.add,
      );
      r.addChunk(set.blobs[0], now: start);
      r.addChunk(set.blobs[1], now: start.add(const Duration(seconds: 30)));
      expect(r.pendingCount, 1);

      expect(
        r.evictExpired(now: start.add(const Duration(seconds: 59))),
        isEmpty,
      );
      expect(r.pendingCount, 1);

      final expired = r.evictExpired(
        now: start.add(const Duration(minutes: 2)),
      );
      expect(expired.length, 1);
      expect(expired.single.total, 3);
      expect(expired.single.receivedDataChunks, 2);
      expect(expired.single.hadParity, isFalse);
      expect(expired.single.missingChunks, 1);
      expect(failures.length, 1);
      expect(r.pendingCount, 0);
    });

    test('addChunk sweeps expired streams', () {
      final setOld = buildImageChunks(
        payload: payloadOf(450),
        metadata: ft8Meta,
        senderPrefix: senderA,
        imgId: 30,
      );
      final setNew = buildImageChunks(
        payload: payloadOf(300),
        metadata: ft8Meta,
        senderPrefix: senderB,
        imgId: 31,
      );
      final failures = <ImageReassemblyFailure>[];
      final start = DateTime(2026, 1, 1);
      final r = ImageReassembler(onFailed: failures.add);
      r.addChunk(setOld.blobs[0], now: start);
      r.addChunk(setNew.blobs[0], now: start.add(const Duration(minutes: 5)));
      expect(failures.length, 1);
      expect(failures.single.key.imgId, 30);
      expect(r.pendingCount, 1);
    });

    test('an unrelated chunk after expiry does not resurrect the old data', () {
      final set = buildImageChunks(
        payload: payloadOf(300),
        metadata: ft8Meta,
        senderPrefix: senderA,
        imgId: 40,
      );
      final start = DateTime(2026, 5, 5);
      final r = ImageReassembler();
      r.addChunk(set.blobs[0], now: start);
      final late = r.addChunk(
        set.blobs[1],
        now: start.add(const Duration(minutes: 2)),
      );
      // Chunk 0 expired, so chunk 1 alone cannot complete anything.
      expect(late.status, ImageChunkStatus.accepted);
      expect(late.result, isNull);
    });

    test('too many concurrent streams evicts the oldest', () {
      final start = DateTime(2026, 2, 2);
      final failures = <ImageReassemblyFailure>[];
      final r = ImageReassembler(
        maxConcurrentStreams: 2,
        onFailed: failures.add,
      );
      for (var i = 0; i < 3; i++) {
        final set = buildImageChunks(
          payload: payloadOf(300),
          metadata: ft8Meta,
          senderPrefix: senderA,
          imgId: 50 + i,
        );
        r.addChunk(set.blobs[0], now: start.add(Duration(seconds: i)));
      }
      expect(r.pendingCount, 2);
      expect(failures.length, 1);
      expect(failures.single.key.imgId, 50);
    });
  });

  group('boundary cases', () {
    test('empty payload round-trips as one chunk', () {
      final set = buildImageChunks(
        payload: Uint8List(0),
        metadata: ft8Meta,
        senderPrefix: senderA,
        imgId: 0,
      );
      expect(set.dataChunkCount, 1);
      expect(
        set.blobs[0].length,
        kImageChunkHeaderBytes + kImageChunkZeroMetadataBytes,
      );
      final r = ImageReassembler();
      final result = feed(r, set.blobs);
      expect(result, isNotNull);
      expect(result!.data, isEmpty);
      expect(result.metadata, ft8Meta);
    });

    test('empty payload recovers from parity alone', () {
      final set = buildImageChunks(
        payload: Uint8List(0),
        metadata: ft8Meta,
        senderPrefix: senderA,
        imgId: 0,
      );
      final r = ImageReassembler();
      final result = feed(r, <Uint8List>[set.blobs[1]]);
      expect(result, isNotNull);
      expect(result!.data, isEmpty);
    });

    test('maximum addressable payload round-trips', () {
      final payload = payloadOf(kImageMaxPayloadBytes);
      final set = buildImageChunks(
        payload: payload,
        metadata: ft8Meta,
        senderPrefix: senderA,
        imgId: 255,
      );
      expect(set.dataChunkCount, kImageMaxDataChunks);
      expect(set.blobs.length, kImageMaxDataChunks + 1);
      for (final blob in set.blobs) {
        expect(blob.length, lessThanOrEqualTo(kImageChunkBlobBytes));
      }
      final r = ImageReassembler();
      expect(feed(r, set.blobs.reversed.toList())!.data, payload);
    });

    test('maximum payload still recovers a single loss', () {
      final payload = payloadOf(kImageMaxPayloadBytes, seed: 5);
      final set = buildImageChunks(
        payload: payload,
        metadata: ft8Meta,
        senderPrefix: senderA,
        imgId: 254,
      );
      final blobs = <Uint8List>[
        for (var i = 0; i < set.blobs.length; i++)
          if (i != kImageMaxDataChunks - 1) set.blobs[i],
      ];
      final r = ImageReassembler();
      final result = feed(r, blobs);
      expect(result!.data, payload);
      expect(result.recoveredWithParity, isTrue);
    });

    test('img_id wraps around 255 -> 0', () {
      final alloc = ImageIdAllocator(seed: 254);
      expect(alloc.next(), 254);
      expect(alloc.next(), 255);
      expect(alloc.next(), 0);
      expect(alloc.next(), 1);
    });

    test('img_id wraparound reusing a key restarts the stream', () {
      final first = buildImageChunks(
        payload: payloadOf(450, seed: 1),
        metadata: ft8Meta,
        senderPrefix: senderA,
        imgId: 77,
      );
      final second = payloadOf(300, seed: 2);
      final secondSet = buildImageChunks(
        payload: second,
        metadata: ft8Meta,
        senderPrefix: senderA,
        imgId: 77, // wrapped back onto the same id
      );
      final r = ImageReassembler();
      // Partially deliver the first image (3 data chunks), then the second
      // image (2 data chunks) arrives under the same key.
      expect(r.addChunk(first.blobs[0]).status, ImageChunkStatus.accepted);
      expect(
        r.addChunk(secondSet.blobs[0]).status,
        ImageChunkStatus.conflicting,
      );
      final done = r.addChunk(secondSet.blobs[1]);
      expect(done.status, ImageChunkStatus.completed);
      expect(done.result!.data, second);
    });

    test('chunks bearing our own prefix are dropped as loopback', () {
      final set = buildImageChunks(
        payload: payloadOf(300),
        metadata: ft8Meta,
        senderPrefix: senderA,
        imgId: 1,
      );
      final r = ImageReassembler(selfPrefix: senderA);
      expect(r.addChunk(set.blobs[0]).status, ImageChunkStatus.fromSelf);
      expect(r.pendingCount, 0);
    });

    test('malformed blobs are rejected, not stored', () {
      final r = ImageReassembler();
      expect(
        r.addChunk(Uint8List.fromList(<int>[1, 2, 3])).status,
        ImageChunkStatus.malformed,
      );
      // total == 0 is illegal.
      expect(
        r.addChunk(Uint8List.fromList(<int>[0, 1, 2, 0x00, 9])).status,
        ImageChunkStatus.malformed,
      );
      // index > total is illegal.
      expect(
        r.addChunk(Uint8List.fromList(<int>[0, 1, 2, 0x32, 9])).status,
        ImageChunkStatus.malformed,
      );
      // Over-long blob cannot have come from this framing.
      expect(
        r.addChunk(Uint8List(kImageChunkBlobBytes + 1)).status,
        ImageChunkStatus.malformed,
      );
      expect(r.pendingCount, 0);
    });

    test('senderPrefixFromKey needs two bytes', () {
      expect(senderPrefixFromKey(null), isNull);
      expect(senderPrefixFromKey(<int>[0x12]), isNull);
      expect(senderPrefixFromKey(<int>[0x12, 0x34, 0x56]), 0x1234);
    });
  });

  group('protocol glue', () {
    test('CMD_SEND_CHANNEL_DATA flood frame matches the wire spec', () {
      final frame = buildSendChannelDataFrame(
        channelIndex: 0,
        dataType: dataTypeMeshTraxPhoto,
        payload: Uint8List.fromList(<int>[0xAA, 0xBB]),
      );
      expect(frame, <int>[0x3E, 0x00, 0xFF, 0x50, 0x01, 0xAA, 0xBB]);
    });

    test('a direct-path frame inserts the path bytes before the data type', () {
      final frame = buildSendChannelDataFrame(
        channelIndex: 2,
        dataType: dataTypeMeshTraxPhoto,
        payload: Uint8List.fromList(<int>[0x01]),
        pathLen: 0x02,
        path: Uint8List.fromList(<int>[0x11, 0x22]),
      );
      expect(frame, <int>[0x3E, 0x02, 0x02, 0x11, 0x22, 0x50, 0x01, 0x01]);
    });

    test('RESP_CODE_CHANNEL_DATA_RECV parses, snr is signed', () {
      final frame = Uint8List.fromList(<int>[
        0x1B,
        0xF8,
        0,
        0,
        3,
        0xFF,
        0x50,
        0x01,
        2,
        0x42,
        0x43,
      ]);
      final parsed = parseChannelDataFrame(frame)!;
      expect(parsed.snrRaw, -8);
      expect(parsed.snrDb, -2.0);
      expect(parsed.channelIndex, 3);
      expect(parsed.arrivedByFlood, isFalse);
      expect(parsed.hopCount, isNull);
      expect(parsed.dataType, dataTypeMeshTraxPhoto);
      expect(parsed.payload, <int>[0x42, 0x43]);
    });

    test('a flooded frame exposes hop count and hash width', () {
      final frame = Uint8List.fromList(<int>[
        0x1B,
        0x04,
        0,
        0,
        0,
        0x43,
        0x1C,
        0xAE,
        0,
      ]);
      final parsed = parseChannelDataFrame(frame)!;
      expect(parsed.arrivedByFlood, isTrue);
      expect(parsed.hopCount, 3);
      expect(parsed.pathHashWidth, 2);
      expect(parsed.payload, isEmpty);
    });

    test('truncated or foreign frames parse as null', () {
      expect(parseChannelDataFrame(Uint8List(4)), isNull);
      expect(
        parseChannelDataFrame(
          Uint8List.fromList(<int>[0x1B, 0, 0, 0, 0, 0xFF, 0x1C, 0xAE, 5, 1]),
        ),
        isNull,
      );
      expect(
        parseChannelDataFrame(
          Uint8List.fromList(<int>[0x10, 0, 0, 0, 0, 0xFF, 0x1C, 0xAE, 0]),
        ),
        isNull,
      );
    });

    test(
      'transport sends chunks strictly sequentially and reassembles',
      () async {
        final sent = <Uint8List>[];
        var inFlight = 0;
        var maxInFlight = 0;
        final received = <ImageReassemblyResult>[];
        final rxWithCallback = ImageReassembler(
          selfPrefix: senderB,
          onImage: received.add,
        );

        final tx = ImageChunkTransport(
          senderPrefix: senderA,
          reassembler: rxWithCallback,
          idAllocator: ImageIdAllocator(seed: 60),
          send: (frame) async {
            // CMD_SEND_CHANNEL_DATA, channel 1, flood (path length 0xFF, no
            // path bytes), MeshTrax's data type, then the chunk.
            expect(frame.sublist(0, 5), <int>[0x3E, 1, 0xFF, 0x50, 0x01]);
            inFlight++;
            maxInFlight = maxInFlight > inFlight ? maxInFlight : inFlight;
            await Future<void>.delayed(const Duration(milliseconds: 1));
            sent.add(frame.sublist(5));
            inFlight--;
          },
        );

        final payload = payloadOf(450, seed: 9);
        final set = await tx.sendImage(
          payload: payload,
          metadata: ft8Meta,
          channelIndex: 1,
        );
        expect(set.imgId, 60);
        expect(sent.length, 4);
        expect(maxInFlight, 1);

        // Loop the blobs back through the receive path as real frames, sent
        // with MeshTrax's photo type.
        for (final blob in sent) {
          final frame = BytesBuilder()
            ..add(<int>[0x1B, 0x10, 0, 0, 1, 0xFF, 0x50, 0x01, blob.length])
            ..add(blob);
          tx.handleFrame(frame.toBytes());
        }
        expect(received.length, 1);
        expect(received.single.data, payload);
        expect(received.single.key.channelIndex, 1);
      },
    );

    test('handleFrame ignores another app\'s photo data type', () {
      final rx = ImageReassembler(selfPrefix: senderB);
      final tx = ImageChunkTransport(
        senderPrefix: senderA,
        reassembler: rx,
        send: (_) async {},
      );
      final set = buildImageChunks(
        payload: payloadOf(120),
        metadata: ft8Meta,
        senderPrefix: senderA,
        imgId: 5,
      );
      ImageReassemblyResult? received;
      for (final blob in set.blobs) {
        final outcome = tx.handleFrame(
          (BytesBuilder()
                ..add(<int>[0x1B, 0x10, 0, 0, 0, 0xFF, 0x1C, 0xAE, blob.length])
                ..add(blob))
              .toBytes(),
        );
        expect(outcome, isNull);
        if (outcome != null && outcome.isComplete) received = outcome.result;
      }
      expect(received, isNull);
      expect(rx.pendingCount, 0);
    });

    test('handleFrame ignores other data types and other frames', () {
      final rx = ImageReassembler();
      final tx = ImageChunkTransport(
        senderPrefix: senderA,
        reassembler: rx,
        send: (_) async {},
      );
      expect(
        tx.handleFrame(
          Uint8List.fromList(<int>[0x1B, 0, 0, 0, 0, 0xFF, 0x01, 0x00, 0]),
        ),
        isNull,
      );
      // The testing type photos used before 2026-11-19.
      expect(
        tx.handleFrame(
          Uint8List.fromList(<int>[0x1B, 0, 0, 0, 0, 0xFF, 0x1C, 0xFF, 0]),
        ),
        isNull,
      );
      expect(tx.handleFrame(Uint8List.fromList(<int>[0x00])), isNull);
      expect(rx.pendingCount, 0);
    });

    test('a photo floods by default, like a channel message', () async {
      final frames = <Uint8List>[];
      final tx = ImageChunkTransport(
        senderPrefix: senderA,
        reassembler: ImageReassembler(),
        send: (frame) async => frames.add(frame),
      );
      await tx.sendImage(payload: payloadOf(120), metadata: ft8Meta);
      expect(frames, isNotEmpty);
      for (final f in frames) {
        expect(f.sublist(0, 5), <int>[0x3E, 0, 0xFF, 0x50, 0x01]);
      }
    });

    test('zeroHop sends every packet with an empty path', () async {
      final frames = <Uint8List>[];
      final tx = ImageChunkTransport(
        senderPrefix: senderA,
        reassembler: ImageReassembler(),
        send: (frame) async => frames.add(frame),
      );
      await tx.sendImage(
        payload: payloadOf(120),
        metadata: ft8Meta,
        channelIndex: 2,
        zeroHop: true,
      );
      expect(frames, isNotEmpty);
      for (final f in frames) {
        expect(f.sublist(0, 5), <int>[0x3E, 2, 0x00, 0x50, 0x01]);
      }
    });

    test('waits the gap between packets, not before the first or after the '
        'last', () async {
      const gap = Duration(milliseconds: 120);
      final sw = Stopwatch()..start();
      final at = <int>[];
      final tx = ImageChunkTransport(
        senderPrefix: senderA,
        reassembler: ImageReassembler(),
        send: (_) async => at.add(sw.elapsedMilliseconds),
      );
      await tx.sendImage(payload: payloadOf(300), metadata: ft8Meta, gap: gap);
      final done = sw.elapsedMilliseconds;
      expect(at.length, 3);
      expect(at.first, lessThan(gap.inMilliseconds));
      for (var i = 1; i < at.length; i++) {
        expect(at[i] - at[i - 1], greaterThanOrEqualTo(gap.inMilliseconds - 5));
      }
      expect(done - at.last, lessThan(gap.inMilliseconds));
    });

    test('photoPacketGap is the airtime plus half a second', () {
      expect(
        photoPacketGap(const Duration(milliseconds: 650)),
        const Duration(milliseconds: 1150),
      );
    });

    group('photoPacketGapFlood', () {
      const airtime = Duration(milliseconds: 650);
      const slow = Duration(seconds: 2);

      test('until the last packet has cleared two hops of repeaters', () {
        // 650 ms on air, then two hops of up to 1625 ms wait and 650 ms on
        // air, then half a second.
        expect(
          photoPacketGapFlood(airtime, packets: 6),
          const Duration(milliseconds: 5700),
        );
      });

      test('capped so the photo goes out within the receiver\'s minute', () {
        final gap = photoPacketGapFlood(slow, packets: 6);
        expect(gap, const Duration(seconds: 9));
        expect(gap * 5, lessThanOrEqualTo(kImageReassemblyTtl * 0.75));
      });

      test('never shorter than the zero-hop gap', () {
        expect(photoPacketGapFlood(slow, packets: 40), photoPacketGap(slow));
        expect(
          photoPacketGapFlood(airtime, packets: 1),
          photoPacketGap(airtime),
        );
      });
    });

    test('concurrent sendImage calls do not interleave on the wire', () async {
      final order = <String>[];
      final tx = ImageChunkTransport(
        senderPrefix: senderA,
        reassembler: ImageReassembler(),
        idAllocator: ImageIdAllocator(seed: 100),
        send: (frame) async {
          await Future<void>.delayed(const Duration(milliseconds: 1));
          final blob = frame.sublist(5);
          order.add('${blob[2]}:${(blob[3] >> 4) & 0x0F}');
        },
      );
      final a = tx.sendImage(payload: payloadOf(300), metadata: ft8Meta);
      final b = tx.sendImage(payload: payloadOf(300), metadata: ft8Meta);
      await Future.wait(<Future<ImageChunkSet>>[a, b]);
      expect(order, <String>[
        '100:0',
        '100:1',
        '100:2',
        '101:0',
        '101:1',
        '101:2',
      ]);
    });
  });

  group('regressions confirmed by adversarial review', () {
    // PROBE A: an image completes; a DIFFERENT image reusing the same img_id
    // arrives within the TTL. The recently-completed shortcut used to report
    // every chunk of it as `duplicate`, so onImage never fired, onFailed never
    // fired, and the image was lost with no diagnostic. ImageIdAllocator seeds
    // from Random().nextInt(256), so a restart really can re-roll a live id.
    test('a new image reusing a just-completed img_id is not swallowed', () {
      final delivered = <ImageReassemblyResult>[];
      final failed = <ImageReassemblyFailure>[];
      final r = ImageReassembler(onImage: delivered.add, onFailed: failed.add);

      final first = buildImageChunks(
        payload: payloadOf(200, seed: 1),
        metadata: ft8Meta,
        senderPrefix: senderA,
        imgId: 42,
      );
      feed(r, first.blobs);
      expect(delivered, hasLength(1), reason: 'first image should complete');

      // Same sender, same img_id, different content and a different length.
      final second = buildImageChunks(
        payload: payloadOf(300, seed: 99),
        metadata: ft8Meta,
        senderPrefix: senderA,
        imgId: 42,
      );
      feed(r, second.blobs);

      expect(delivered, hasLength(2), reason: 'second image must not be lost');
      expect(delivered.last.data, equals(payloadOf(300, seed: 99)));
      expect(failed, isEmpty);
    });

    test('a genuine re-send of a delivered chunk is still a duplicate', () {
      final delivered = <ImageReassemblyResult>[];
      final r = ImageReassembler(onImage: delivered.add);
      final set = buildImageChunks(
        payload: payloadOf(200, seed: 1),
        metadata: ft8Meta,
        senderPrefix: senderA,
        imgId: 42,
      );
      feed(r, set.blobs);
      expect(delivered, hasLength(1));

      // Replay every blob verbatim: none may open a new stream.
      for (final blob in set.blobs) {
        final outcome = r.addChunk(blob, channelIndex: 0);
        expect(outcome.status, ImageChunkStatus.duplicate);
      }
      expect(delivered, hasLength(1));
      expect(r.pendingCount, 0);
    });

    // PROBE B/C: a flipped bit in the parity length byte used to yield a
    // silently TRUNCATED image reported as `completed`. Only the last data
    // chunk may be short.
    test(
      'corrupt parity length is rejected rather than silently truncating',
      () {
        for (final payloadLen in [300, 400]) {
          final set = buildImageChunks(
            payload: payloadOf(payloadLen, seed: 3),
            metadata: ft8Meta,
            senderPrefix: senderA,
            imgId: 7,
          );
          final data = set.blobs.sublist(0, set.dataChunkCount);
          final parity = Uint8List.fromList(set.blobs.last);
          // Corrupt the len_xor byte (first body byte, just after the header).
          parity[kImageChunkHeaderBytes] ^= 0x02;

          final delivered = <ImageReassemblyResult>[];
          final r = ImageReassembler(onImage: delivered.add);
          // Drop a NON-FINAL chunk (index 1 of >=3, else index 0) and supply
          // the corrupted parity.
          final dropIndex = data.length >= 3 ? 1 : 0;
          final kept = <Uint8List>[
            for (var i = 0; i < data.length; i++)
              if (i != dropIndex) data[i],
            parity,
          ];
          feed(r, kept);
          expect(
            delivered,
            isEmpty,
            reason: 'payload $payloadLen: truncated recovery must not complete',
          );
        }
      },
    );

    test('parity still recovers a genuinely lost non-final chunk', () {
      final payload = payloadOf(400, seed: 5);
      final set = buildImageChunks(
        payload: payload,
        metadata: ft8Meta,
        senderPrefix: senderA,
        imgId: 8,
      );
      final data = set.blobs.sublist(0, set.dataChunkCount);
      expect(data.length, greaterThanOrEqualTo(3));

      final delivered = <ImageReassemblyResult>[];
      final r = ImageReassembler(onImage: delivered.add);
      feed(r, <Uint8List>[
        for (var i = 0; i < data.length; i++)
          if (i != 1) data[i],
        set.blobs.last,
      ]);
      expect(delivered, hasLength(1));
      expect(delivered.single.data, equals(payload));
      expect(delivered.single.recoveredWithParity, isTrue);
    });
  });

  group('oversized data body', () {
    test('a 159-byte data body is rejected and parity cannot overrun', () {
      final failed = <ImageReassemblyFailure>[];
      final r = ImageReassembler(onFailed: failed.add);
      // Header: sender 0x1234, img 5, idx 0 of 2; body one byte past the cap.
      final oversized = Uint8List.fromList(<int>[
        0x12,
        0x34,
        5,
        (0 << 4) | 2,
        ...List<int>.filled(kImageChunkBodyBytes + 1, 0xAA),
      ]);
      expect(oversized.length, kImageChunkBlobBytes);
      expect(r.addChunk(oversized).status, ImageChunkStatus.malformed);
      expect(r.pendingCount, 0);

      // A parity chunk for the same stream must not throw.
      final parity = Uint8List.fromList(<int>[
        0x12,
        0x34,
        5,
        (2 << 4) | 2,
        ...List<int>.filled(kImageChunkBodyBytes + 1, 0x55),
      ]);
      expect(() => r.addChunk(parity), returnsNormally);
    });
  });

  group('clear()', () {
    test('reports in-progress streams as failed (disconnected)', () {
      final failed = <ImageReassemblyFailure>[];
      final r = ImageReassembler(onFailed: failed.add);
      final set = buildImageChunks(
        payload: payloadOf(400, seed: 3),
        metadata: ft8Meta,
        senderPrefix: senderA,
        imgId: 8,
      );
      r.addChunk(set.blobs[0]);
      expect(r.pendingCount, 1);
      r.clear();
      expect(r.pendingCount, 0);
      expect(failed, hasLength(1));
      expect(failed.single.reason, ImageReassemblyFailureReason.disconnected);
      expect(failed.single.isCorrupt, isFalse);
      expect(r.evictExpired(now: DateTime(2100)), isEmpty);
    });
  });

  group('completed-image map is capped', () {
    /// A lone parity chunk of a `total == 1` image completes that image by
    /// itself — one packet, one remembered entry. That is the amplification the
    /// cap exists to bound.
    List<Uint8List> loneParity(int imgId) => buildImageChunks(
      payload: payloadOf(20, seed: imgId),
      metadata: ft8Meta,
      senderPrefix: senderA,
      imgId: imgId,
    ).blobs;

    test('one packet per img_id can complete an image (the attack)', () {
      final r = ImageReassembler();
      final done = r.addChunk(loneParity(1)[1]);
      expect(done.status, ImageChunkStatus.completed);
      expect(r.completedCount, 1);
      expect(r.pendingCount, 0);
    });

    test(
      'the map never exceeds maxCompletedStreams and evicts oldest first',
      () {
        final start = DateTime(2026, 3, 3);
        final r = ImageReassembler(maxCompletedStreams: 3);
        for (var i = 0; i < 20; i++) {
          r.addChunk(
            loneParity(100 + i)[1],
            now: start.add(Duration(seconds: i)),
          );
          expect(r.completedCount, lessThanOrEqualTo(3));
        }
        expect(r.completedCount, 3);
        expect(r.completedKeys.map((k) => k.imgId).toList()..sort(), <int>[
          117,
          118,
          119,
        ]);
      },
    );

    test('default cap matches the pending cap', () {
      final start = DateTime(2026, 3, 4);
      final r = ImageReassembler();
      expect(r.maxCompletedStreams, 8);
      expect(r.maxConcurrentStreams, 8);
      for (var i = 0; i < 30; i++) {
        r.addChunk(loneParity(i)[1], now: start.add(Duration(seconds: i)));
      }
      expect(r.completedCount, 8);
    });

    test('capping does not break straggler suppression for recent images', () {
      final start = DateTime(2026, 3, 5);
      final r = ImageReassembler(maxCompletedStreams: 2);
      final set = buildImageChunks(
        payload: payloadOf(300),
        metadata: ft8Meta,
        senderPrefix: senderA,
        imgId: 200,
      );
      feed(r, set.blobs.sublist(0, 2), now: start);
      // Trailing parity of the newest image is still recognised as a duplicate.
      expect(
        r.addChunk(set.blobs[2], now: start).status,
        ImageChunkStatus.duplicate,
      );
      expect(r.pendingCount, 0);
    });

    test('clear() empties the completed map too', () {
      final r = ImageReassembler();
      r.addChunk(loneParity(9)[1]);
      expect(r.completedCount, 1);
      r.clear();
      expect(r.completedCount, 0);
    });
  });

  group('rate point wire codes', () {
    test('ft8 goes on the wire as code 2; the other codes are refused', () {
      expect(imageRateWireCode(ImageCodecRatePoint.ft8), kImageRateWireFt8);
      expect(kImageRateWireFt8, 2);
      expect(
        const ImageStreamMetadata(rate: ImageCodecRatePoint.ft8).encode() &
            0x03,
        2,
      );
      // Codes 0 and 1 are refused: this build has no model for them.
      expect(imageRatePointFromWireCode(0), isNull);
      expect(imageRatePointFromWireCode(1), isNull);
    });

    test('every wire code round-trips and unknown codes are null', () {
      for (final rate in ImageCodecRatePoint.values) {
        expect(imageRatePointFromWireCode(imageRateWireCode(rate)), rate);
      }
      final known = ImageCodecRatePoint.values.map(imageRateWireCode).toSet();
      expect(known, hasLength(ImageCodecRatePoint.values.length));
      for (var code = 0; code < 16; code++) {
        if (known.contains(code)) continue;
        expect(imageRatePointFromWireCode(code), isNull, reason: 'code $code');
      }
    });

    test('an unknown rate code fails cleanly instead of decoding wrong', () {
      final payload = payloadOf(300);
      final set = buildImageChunks(
        payload: payload,
        metadata: ft8Meta,
        senderPrefix: senderA,
        imgId: 80,
      );
      // Overwrite the 2-bit rate field with 0: this build has no model for
      // it, so it must fail rather than feed the ft8 model the wrong kind of
      // bitstream.
      final bad = Uint8List.fromList(set.blobs[0]);
      bad[kImageChunkHeaderBytes] = bad[kImageChunkHeaderBytes] & 0xFC;

      final delivered = <ImageReassemblyResult>[];
      final failures = <ImageReassemblyFailure>[];
      final r = ImageReassembler(
        onImage: delivered.add,
        onFailed: failures.add,
      );
      expect(r.addChunk(bad).status, ImageChunkStatus.accepted);
      final done = r.addChunk(set.blobs[1]);
      expect(done.status, ImageChunkStatus.unsupportedFormat);
      expect(done.result, isNull);
      expect(delivered, isEmpty);
      expect(failures, hasLength(1));
      expect(
        failures.single.reason,
        ImageReassemblyFailureReason.unsupportedFormat,
      );
      expect(failures.single.isCorrupt, isTrue);
      expect(r.pendingCount, 0);
    });

    test('a reserved rate code fails the same way through reassembly', () {
      // Resolution is a closed 2-bit field now, so it cannot carry an unknown
      // value; the reserved RATE codes are what a future format must use to be
      // rejected rather than misread. This asserts the rejection survives the
      // whole reassembly path, not just ImageStreamMetadata.decode.
      final set = buildImageChunks(
        payload: payloadOf(300),
        metadata: ft8Meta,
        senderPrefix: senderA,
        imgId: 81,
      );
      final bad = Uint8List.fromList(set.blobs[0]);
      bad[kImageChunkHeaderBytes] =
          (bad[kImageChunkHeaderBytes] & 0xFC) | 0x03; // reserved rate code 3
      final r = ImageReassembler();
      r.addChunk(bad);
      expect(
        r.addChunk(set.blobs[1]).status,
        ImageChunkStatus.unsupportedFormat,
      );
    });
  });

  group('the sender\'s tag', () {
    test('the tag bit round-trips with rate and resolution intact', () {
      for (final tagged in [false, true]) {
        final m = ImageStreamMetadata(
          rate: ImageCodecRatePoint.ft8,
          hasTag: tagged,
        );
        final back = ImageStreamMetadata.decode(m.encode());
        expect(back, m);
        expect(back!.squareSize, 512);
      }
    });

    test('travels ahead of the bitstream as exact text', () {
      final bitstream = payloadOf(300);
      final payload = photoPayloadWithTag(bitstream, ' Spring flowing ');
      expect(payload[0], 'Spring flowing'.length);
      final parts = photoPayloadParts(payload, hasTag: true)!;
      expect(parts.tag, 'Spring flowing');
      expect(parts.bitstream, bitstream);
    });

    test('a blank tag adds nothing; no tag leaves the payload alone', () {
      final bitstream = payloadOf(50);
      expect(photoPayloadWithTag(bitstream, '  '), same(bitstream));
      expect(photoPayloadWithTag(bitstream, null), same(bitstream));
      final parts = photoPayloadParts(bitstream, hasTag: false)!;
      expect(parts.tag, isNull);
      expect(parts.bitstream, bitstream);
    });

    test('takes UTF-8 up to the byte limit, and refuses more', () {
      final emoji = '🏕️' * 10; // 70 bytes
      expect(
        photoPayloadParts(
          photoPayloadWithTag(payloadOf(10), '⛰️ Camp'),
          hasTag: true,
        )!.tag,
        '⛰️ Camp',
      );
      expect(
        () => photoPayloadWithTag(payloadOf(10), emoji),
        throwsArgumentError,
      );
    });

    test('a damaged tag length means a damaged photo', () {
      expect(photoPayloadParts(Uint8List(0), hasTag: true), isNull);
      expect(
        photoPayloadParts(Uint8List.fromList([9, 1, 2]), hasTag: true),
        isNull,
      );
      expect(
        photoPayloadParts(Uint8List.fromList([200, 1, 2]), hasTag: true),
        isNull,
      );
    });

    test('a tagged photo arrives whole with its tag', () {
      final bitstream = payloadOf(500);
      final set = buildImageChunks(
        payload: photoPayloadWithTag(bitstream, 'Road washed out'),
        metadata: const ImageStreamMetadata(
          rate: ImageCodecRatePoint.ft8,
          hasTag: true,
        ),
        senderPrefix: senderA,
        imgId: 3,
      );
      ImageReassemblyResult? got;
      final r = ImageReassembler(selfPrefix: senderB);
      for (final b in set.blobs) {
        final o = r.addChunk(b);
        if (o.isComplete) got = o.result;
      }
      expect(got!.metadata!.hasTag, isTrue);
      final parts = photoPayloadParts(got.data, hasTag: true)!;
      expect(parts.tag, 'Road washed out');
      expect(parts.bitstream, bitstream);
    });
  });
}
