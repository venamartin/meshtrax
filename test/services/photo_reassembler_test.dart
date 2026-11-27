import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/services/photo_reassembler.dart';
import 'package:traxpix/traxpix.dart';

// Received photo packets, collected into whole photos by sender, photo and
// channel for the receive window; traxpix makes the photo from them.

Uint8List payloadOf(int length, {int seed = 7}) => Uint8List.fromList(
  List<int>.generate(length, (i) => (i * 37 + seed * 11) & 0xFF),
);

const ImageStreamMetadata ft8Meta = ImageStreamMetadata(
  rate: ImageCodecRatePoint.ft8,
);

const int senderA = 0x1234;
const int senderB = 0xBEEF;

ImageChunkSet photoOf(
  int length, {
  int imgId = 11,
  int seed = 7,
  int sender = senderA,
  bool parity = true,
}) => buildImageChunks(
  payload: payloadOf(length, seed: seed),
  metadata: ft8Meta,
  senderPrefix: sender,
  imgId: imgId,
  parity: parity,
);

/// Feeds [blobs] to [r] in the given order and returns the photo, if one
/// completed.
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
  group('whole photos', () {
    test('a photo completes, once, and its repair packet after it is a '
        'duplicate', () {
      final set = photoOf(300);
      final results = <ImageReassemblyResult>[];
      final r = ImageReassembler(selfPrefix: senderB, onImage: results.add);
      feed(r, set.blobs);
      expect(results, hasLength(1));
      expect(results.single.data, payloadOf(300));
      expect(results.single.metadata, ft8Meta);
      expect(r.pendingCount, 0, reason: 'trailing repair must not linger');
    });

    test('duplicates are ignored and the repair packet rebuilds one lost',
        () {
      final set = photoOf(300); // 2 data packets
      final r = ImageReassembler();
      expect(r.addChunk(set.blobs[0]).status, ImageChunkStatus.accepted);
      expect(r.addChunk(set.blobs[0]).status, ImageChunkStatus.duplicate);
      final done = r.addChunk(set.blobs[2]);
      expect(done.status, ImageChunkStatus.completed);
      expect(done.result!.data, payloadOf(300));
      expect(done.result!.recoveredWithParity, isTrue);
    });

    test('two senders interleaved on one channel do not mix', () {
      final setA = photoOf(300, imgId: 5, seed: 1);
      final setB = photoOf(300, imgId: 5, seed: 2, sender: senderB);
      final got = <int, Uint8List>{};
      final r = ImageReassembler(
        onImage: (res) => got[res.key.senderPrefix] = res.data,
      );
      feed(r, [setA.blobs[0], setB.blobs[1], setA.blobs[1], setB.blobs[0]]);
      expect(got[senderA], payloadOf(300, seed: 1));
      expect(got[senderB], payloadOf(300, seed: 2));
    });

    test('the same img_id on different channels stays separate', () {
      final set = photoOf(300, imgId: 8);
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
      final oldSet = photoOf(300, imgId: 9, seed: 1);
      final newSet = photoOf(300, imgId: 9, seed: 2);
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

      // Without the clear, these would complete with the old packet 0.
      final data = newSet.blobs.sublist(0, newSet.dataChunkCount);
      expect(feed(r, data.sublist(1), channelIndex: 3), isNull);
      expect(feed(r, [data[0]], channelIndex: 3)!.data, payloadOf(300, seed: 2));
    });
  });

  group('a packet sent again', () {
    test('fills the one that was lost', () {
      final set = photoOf(440, parity: false); // 3 data packets
      final r = ImageReassembler();
      r.addChunk(set.blobs[0]);
      r.addChunk(set.blobs[2]);
      final done = r.addChunk(photoPacketAgain(set.blobs[1], 1));
      expect(done.status, ImageChunkStatus.completed);
      expect(done.result!.data, payloadOf(440));
    });

    test('after the photo is whole is a late copy, not a new photo', () {
      final set = photoOf(300);
      final failures = <ImageReassemblyFailure>[];
      final r = ImageReassembler(onFailed: failures.add);
      feed(r, set.blobs.sublist(0, 2));
      for (final again in [
        photoPacketAgain(set.blobs[0], 1),
        photoPacketAgain(set.blobs[1], 2),
        photoPacketAgain(set.blobs[2], 1),
      ]) {
        expect(r.addChunk(again).status, ImageChunkStatus.duplicate);
      }
      expect(r.pendingCount, 0);
      expect(r.evictExpired(now: DateTime.now().add(photoReceiveWindow)),
          isEmpty);
      expect(failures, isEmpty);
    });
  });

  group('the window', () {
    test('is 20 minutes: a photo whose packets come 15 minutes apart still '
        'completes', () {
      expect(photoReceiveWindow, const Duration(minutes: 20));
      final set = photoOf(300, parity: false);
      final start = DateTime(2026, 5, 6);
      final r = ImageReassembler();
      expect(r.ttl, photoReceiveWindow);
      r.addChunk(set.blobs[0], now: start);
      final last = r.addChunk(
        set.blobs[1],
        now: start.add(const Duration(minutes: 15)),
      );
      expect(last.result, isNotNull);
    });

    test('a stalled photo expires and is reported as failed', () {
      final set = photoOf(440);
      final failures = <ImageReassemblyFailure>[];
      final start = DateTime(2026, 1, 1, 12);
      final r = ImageReassembler(
        ttl: const Duration(seconds: 60),
        onFailed: failures.add,
      );
      r.addChunk(set.blobs[0], now: start);
      r.addChunk(set.blobs[1], now: start.add(const Duration(seconds: 30)));
      expect(
        r.evictExpired(now: start.add(const Duration(seconds: 59))),
        isEmpty,
      );
      final expired = r.evictExpired(
        now: start.add(const Duration(minutes: 2)),
      );
      expect(expired.single.total, 3);
      expect(expired.single.receivedDataChunks, 2);
      expect(expired.single.hadParity, isFalse);
      expect(expired.single.missingChunks, 1);
      expect(failures, hasLength(1));
      expect(r.pendingCount, 0);
    });

    test('addChunk sweeps expired photos', () {
      final failures = <ImageReassemblyFailure>[];
      final start = DateTime(2026, 1, 1);
      final r = ImageReassembler(onFailed: failures.add);
      r.addChunk(photoOf(440, imgId: 30).blobs[0], now: start);
      r.addChunk(
        photoOf(300, imgId: 31, sender: senderB).blobs[0],
        now: start.add(photoReceiveWindow + const Duration(minutes: 1)),
      );
      expect(failures.single.key.imgId, 30);
      expect(r.pendingCount, 1);
    });

    test('a packet after its photo expired doesn\'t bring the old data back',
        () {
      final set = photoOf(300, imgId: 40);
      final start = DateTime(2026, 5, 5);
      final r = ImageReassembler();
      r.addChunk(set.blobs[0], now: start);
      final late = r.addChunk(
        set.blobs[1],
        now: start.add(photoReceiveWindow + const Duration(minutes: 1)),
      );
      expect(late.status, ImageChunkStatus.accepted);
      expect(late.result, isNull);
    });

    test('too many photos at once drops the oldest', () {
      final start = DateTime(2026, 2, 2);
      final failures = <ImageReassemblyFailure>[];
      final r = ImageReassembler(
        maxConcurrentStreams: 2,
        onFailed: failures.add,
      );
      for (var i = 0; i < 3; i++) {
        r.addChunk(
          photoOf(300, imgId: 50 + i).blobs[0],
          now: start.add(Duration(seconds: i)),
        );
      }
      expect(r.pendingCount, 2);
      expect(failures.single.key.imgId, 50);
      expect(failures.single.reason, ImageReassemblyFailureReason.overflow);
    });
  });

  group('odd packets', () {
    test('a wrapped img_id reusing a key starts the photo again', () {
      final first = photoOf(440, imgId: 77, seed: 1);
      final second = photoOf(300, imgId: 77, seed: 2);
      final r = ImageReassembler();
      expect(r.addChunk(first.blobs[0]).status, ImageChunkStatus.accepted);
      expect(
        r.addChunk(second.blobs[0]).status,
        ImageChunkStatus.conflicting,
      );
      final done = r.addChunk(second.blobs[1]);
      expect(done.status, ImageChunkStatus.completed);
      expect(done.result!.data, payloadOf(300, seed: 2));
    });

    test('packets bearing our own prefix are ours, not received', () {
      final r = ImageReassembler(selfPrefix: senderA);
      expect(r.addChunk(photoOf(300).blobs[0]).status,
          ImageChunkStatus.fromSelf);
      expect(r.pendingCount, 0);
    });

    test('malformed blobs are rejected, not stored', () {
      final r = ImageReassembler();
      expect(
        r.addChunk(Uint8List.fromList([1, 2, 3])).status,
        ImageChunkStatus.malformed,
      );
      expect(
        r.addChunk(Uint8List.fromList([0, 1, 2, 0x00, 0, 9])).status,
        ImageChunkStatus.malformed,
        reason: 'total 0',
      );
      expect(
        r.addChunk(Uint8List.fromList([0, 1, 2, 0x32, 0, 9])).status,
        ImageChunkStatus.malformed,
        reason: 'index past total',
      );
      expect(
        r.addChunk(Uint8List(kImageChunkBlobBytes + 1)).status,
        ImageChunkStatus.malformed,
      );
      expect(r.pendingCount, 0);
    });

    test('a data body past the cap is rejected and the repair packet can\'t '
        'overrun', () {
      final r = ImageReassembler();
      final oversized = Uint8List.fromList([
        0x12, 0x34, 5, (0 << 4) | 2, 0, //
        ...List<int>.filled(kImageChunkBodyBytes + 1, 0xAA),
      ]);
      expect(oversized.length, kImageChunkBlobBytes);
      expect(r.addChunk(oversized).status, ImageChunkStatus.malformed);
      final parity = Uint8List.fromList([
        0x12, 0x34, 5, (2 << 4) | 2, 0, //
        ...List<int>.filled(kImageChunkBodyBytes + 1, 0x55),
      ]);
      expect(() => r.addChunk(parity), returnsNormally);
    });

    test('a reserved rate code says so once every packet came', () {
      final set = photoOf(300, imgId: 81);
      final bad = Uint8List.fromList(set.blobs[0]);
      bad[kImageChunkHeaderBytes] = (bad[kImageChunkHeaderBytes] & 0xFC) | 0x03;
      final failures = <ImageReassemblyFailure>[];
      final r = ImageReassembler(onFailed: failures.add);
      r.addChunk(bad);
      expect(
        r.addChunk(set.blobs[1]).status,
        ImageChunkStatus.unsupportedFormat,
      );
      expect(failures.single.isCorrupt, isTrue);
    });
  });

  group('photos received before', () {
    test('a new photo reusing a just-finished img_id is not swallowed', () {
      final delivered = <ImageReassemblyResult>[];
      final failed = <ImageReassemblyFailure>[];
      final r = ImageReassembler(onImage: delivered.add, onFailed: failed.add);
      feed(r, photoOf(200, imgId: 42, seed: 1).blobs);
      feed(r, photoOf(300, imgId: 42, seed: 99).blobs);
      expect(delivered, hasLength(2));
      expect(delivered.last.data, payloadOf(300, seed: 99));
      expect(failed, isEmpty);
    });

    test('a verbatim re-send of a delivered photo is all duplicates', () {
      final delivered = <ImageReassemblyResult>[];
      final r = ImageReassembler(onImage: delivered.add);
      final set = photoOf(200, imgId: 42, seed: 1);
      feed(r, set.blobs);
      for (final blob in set.blobs) {
        expect(r.addChunk(blob).status, ImageChunkStatus.duplicate);
      }
      expect(delivered, hasLength(1));
      expect(r.pendingCount, 0);
    });

    test('are capped, oldest forgotten first', () {
      /// A lone repair packet of a 1-packet photo completes it by itself.
      Uint8List loneParity(int imgId) => photoOf(20, imgId: imgId).blobs[1];
      final start = DateTime(2026, 3, 3);
      final r = ImageReassembler(maxCompletedStreams: 3);
      for (var i = 0; i < 20; i++) {
        r.addChunk(loneParity(100 + i), now: start.add(Duration(seconds: i)));
        expect(r.completedCount, lessThanOrEqualTo(3));
      }
      expect(r.completedKeys.map((k) => k.imgId).toList()..sort(),
          [117, 118, 119]);
      expect(ImageReassembler().maxCompletedStreams, 8);
    });

    test('clear() reports photos being received and forgets the finished',
        () {
      final failed = <ImageReassemblyFailure>[];
      final r = ImageReassembler(onFailed: failed.add);
      feed(r, photoOf(20, imgId: 9).blobs);
      r.addChunk(photoOf(440, imgId: 8).blobs[0]);
      expect(r.completedCount, 1);
      r.clear();
      expect(r.pendingCount, 0);
      expect(r.completedCount, 0);
      expect(failed.single.reason, ImageReassemblyFailureReason.disconnected);
    });
  });

  group('how far a photo came', () {
    test('it keeps the fewest repeaters any copy came through', () {
      final set = photoOf(440, imgId: 40);
      final r = ImageReassembler();
      r.addChunk(set.blobs[0], hops: 2);
      // The same packet again, heard from the sender's own radio.
      r.addChunk(set.blobs[0], hops: 0);
      r.addChunk(set.blobs[1], hops: 1);
      expect(r.addChunk(set.blobs[2], hops: 3).result!.fewestHops, 0);
    });

    test('unknown when no copy said', () {
      expect(feed(ImageReassembler(), photoOf(440, imgId: 42).blobs)!
          .fewestHops, isNull);
    });

    test('an incomplete photo says it too', () {
      final failures = <ImageReassemblyFailure>[];
      final start = DateTime(2026, 1, 1, 12);
      final r = ImageReassembler(onFailed: failures.add);
      r.addChunk(photoOf(440, imgId: 43).blobs[0], hops: 1, now: start);
      r.evictExpired(
        now: start.add(photoReceiveWindow + const Duration(minutes: 1)),
      );
      expect(failures.single.fewestHops, 1);
    });
  });
}
