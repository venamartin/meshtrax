import 'dart:typed_data';

import 'package:test/test.dart';

import 'package:traxpix/src/photo_chunks.dart';
import 'package:traxpix/src/rate_point.dart';

Uint8List payloadOf(int length, {int seed = 7}) => Uint8List.fromList(
  List<int>.generate(length, (i) => (i * 37 + seed * 11) & 0xFF),
);

const ImageStreamMetadata ft8Meta = ImageStreamMetadata(
  rate: ImageCodecRatePoint.ft8,
);

const int senderA = 0x1234;

ImageChunkSet photo(int length, {int imgId = 11, bool parity = true}) =>
    buildImageChunks(
      payload: payloadOf(length),
      metadata: ft8Meta,
      senderPrefix: senderA,
      imgId: imgId,
      parity: parity,
    );

/// Adds [blobs] to one [ImagePackets] in the given order, and returns it
/// with what each add made of its packet.
(ImagePackets, List<ImagePacketAdded>) collect(List<Uint8List> blobs) {
  ImagePackets? packets;
  final added = <ImagePacketAdded>[];
  for (final blob in blobs) {
    final header = parseImageChunkHeader(blob)!;
    packets ??= ImagePackets(total: header.total);
    added.add(
      packets.add(header, Uint8List.sublistView(blob, header.bodyOffset)),
    );
  }
  return (packets!, added);
}

/// The photo [blobs] make, given in this order.
ImageRebuilt? rebuild(List<Uint8List> blobs) => collect(blobs).$1.rebuild();

void main() {
  group('constants', () {
    test('every blob fits the binding transport limit', () {
      expect(kImageChunkBlobBytes, 157);
      expect(kImageChunkHeaderBytes, 5);
      expect(kImageChunkBodyBytes, 151);
      expect(kImageChunkFirstCapacity, 150);
      expect(kImageChunkCapacity, 151);
      expect(kImageMaxPayloadBytes, 150 + 14 * 151);
    });

    test('a full photo packet fits the raw log with a 3-repeater path', () {
      // The radio copies heard packets to the app only up to 173 bytes; a
      // path of 3 repeaters with 2-byte IDs adds 6.
      expect(kPhotoPacketAirBytes, 165);
      expect(kPhotoPacketAirBytes + 3 * 2, lessThanOrEqualTo(173));
    });

    test('ft8 sizes land on the expected packet counts', () {
      // Packet 0 carries 150 image bytes, every later packet 151.
      expect(imageDataChunkCount(150), 1);
      expect(imageDataChunkCount(151), 2);
      expect(imageDataChunkCount(ImageCodecRateStats.ft8.minBytes), 2);
      expect(imageDataChunkCount(ImageCodecRateStats.ft8.meanBytes), 3);
      expect(imageDataChunkCount(ImageCodecRateStats.ft8.maxBytes), 6);
    });

    test('photos go as 0172', () {
      expect(dataTypeMeshTraxPhoto, 0x0172);
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

    test('an unknown rate or format version is refused, not guessed at', () {
      // The byte is extras(1) | version(3) | resolution(2) | rate(2). Only
      // ft8 (2) decodes; rate codes 0, 1 and 3 are refused.
      expect(ImageStreamMetadata.decode(0x00), isNull);
      expect(ImageStreamMetadata.decode(0x01), isNull);
      expect(ImageStreamMetadata.decode(0x03), isNull);
      final legal = ImageStreamMetadata.decode(0x82);
      expect(legal, isNotNull);
      expect(legal!.rate, ImageCodecRatePoint.ft8);
      expect(legal.hasExtras, isTrue);
      // Any other version is a format this build doesn't know.
      expect(ImageStreamMetadata.decode(0x12), isNull);
      expect(ImageStreamMetadata.decode(0xF2), isNull);
    });
  });

  group('a photo into packets', () {
    test('one, two and three packet payloads produce the right blob shapes',
        () {
      final cases = <int, int>{
        1: 1,
        kImageChunkFirstCapacity: 1,
        kImageChunkFirstCapacity + 1: 2,
        kImageChunkFirstCapacity + kImageChunkCapacity: 2,
        kImageChunkFirstCapacity + kImageChunkCapacity + 1: 3,
      };
      cases.forEach((length, expectedChunks) {
        final set = photo(length, imgId: 3);
        expect(set.dataChunkCount, expectedChunks, reason: 'len $length');
        expect(set.blobs.length, expectedChunks + 1); // + repair
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
        expect(blob[4], 0, reason: 'the retry byte: a first send, no flags');
      }
      expect(parseImageChunkHeader(set.blobs.last)!.isParity, isTrue);
      // Packet 0's body opens with the metadata byte.
      expect(set.blobs[0][kImageChunkHeaderBytes], ft8Meta.encode());
    });

    test('rejects a payload larger than the framing can address', () {
      expect(() => photo(kImageMaxPayloadBytes + 1), throwsArgumentError);
    });
  });

  group('a packet sent again', () {
    test('counts its sends before in the retry byte, its flags kept', () {
      final blob = photo(300).blobs[1];
      final again = photoPacketAgain(blob, 2);
      expect(again[kImageRetryByteOffset], 2);
      expect(parseImageChunkHeader(again)!.retry, 2);
      expect(blob[kImageRetryByteOffset], 0, reason: 'the first is untouched');
      final flagged = Uint8List.fromList(blob)..[kImageRetryByteOffset] = 0x50;
      expect(photoPacketAgain(flagged, 3)[kImageRetryByteOffset], 0x53);
    });

    test('is the same packet to a receiver, and nothing else is', () {
      final set = photo(300);
      final blob = set.blobs[0];
      expect(samePhotoPacket(photoPacketAgain(blob, 1), blob), isTrue);
      expect(samePhotoPacket(photoPacketAgain(blob, 1), photoPacketAgain(blob, 3)),
          isTrue);
      expect(samePhotoPacket(set.blobs[1], blob), isFalse);
      final changed = Uint8List.fromList(blob)..[blob.length - 1] ^= 1;
      expect(samePhotoPacket(changed, blob), isFalse);
      final flagged = Uint8List.fromList(blob)..[kImageRetryByteOffset] = 0x10;
      expect(samePhotoPacket(flagged, blob), isFalse, reason: 'flags differ');
    });

    test('goes into the photo as the packet it repeats', () {
      final set = photo(440);
      final (packets, added) = collect([
        set.blobs[0],
        photoPacketAgain(set.blobs[0], 1),
        photoPacketAgain(set.blobs[1], 2),
        set.blobs[2],
      ]);
      expect(added, [
        ImagePacketAdded.accepted,
        ImagePacketAdded.duplicate,
        ImagePacketAdded.accepted,
        ImagePacketAdded.accepted,
      ]);
      expect(packets.rebuild()!.data, payloadOf(440));
    });
  });

  group('reading a packet\'s header', () {
    test('malformed blobs read as null', () {
      expect(parseImageChunkHeader(Uint8List(4)), isNull, reason: 'short');
      expect(parseImageChunkHeader(Uint8List(kImageChunkBlobBytes + 1)),
          isNull, reason: 'long');
      final zeroTotal = Uint8List.fromList(photo(100).blobs[0])..[3] = 0x00;
      expect(parseImageChunkHeader(zeroTotal), isNull);
      final pastTotal = Uint8List.fromList(photo(100).blobs[0])..[3] = 0x31;
      expect(parseImageChunkHeader(pastTotal), isNull);
    });

    test('senderPrefixFromKey needs two bytes', () {
      expect(senderPrefixFromKey(null), isNull);
      expect(senderPrefixFromKey([0x12]), isNull);
      expect(senderPrefixFromKey([0x12, 0x34, 0x56]), 0x1234);
    });
  });

  group('packets into a photo', () {
    for (final length in <int>[100, 300, 440]) {
      test('$length bytes round-trip in order', () {
        final set = photo(length);
        final photoBack = rebuild(set.blobs.sublist(0, set.dataChunkCount));
        expect(photoBack!.data, payloadOf(length));
        expect(photoBack.metadata, ft8Meta);
        expect(photoBack.recoveredWithParity, isFalse);
        expect(photoBack.chunkCount, set.dataChunkCount);
      });
    }

    test('out-of-order arrival still rebuilds', () {
      final set = photo(450);
      expect(
        rebuild([set.blobs[2], set.blobs[0], set.blobs[1]])!.data,
        payloadOf(450),
      );
    });

    test('a copy is a duplicate, other bytes under its number conflict', () {
      final set = photo(450);
      final other = buildImageChunks(
        payload: payloadOf(450, seed: 9),
        metadata: ft8Meta,
        senderPrefix: senderA,
        imgId: 11,
      );
      final (packets, added) = collect([
        set.blobs[0],
        set.blobs[0],
        set.blobs[3],
        set.blobs[3],
        other.blobs[0],
      ]);
      expect(added, [
        ImagePacketAdded.accepted,
        ImagePacketAdded.duplicate,
        ImagePacketAdded.accepted,
        ImagePacketAdded.duplicate,
        ImagePacketAdded.conflicting,
      ]);
      expect(packets.received, 1);
    });

    test('nothing while packets are missing', () {
      final set = photo(450);
      expect(rebuild([set.blobs[0], set.blobs[2]]), isNull);
    });

    test('a photo of unknown format rebuilds with no metadata', () {
      final set = photo(100);
      final odd = Uint8List.fromList(set.blobs[0])
        ..[kImageChunkHeaderBytes] = 0x12; // version 1
      final photoBack = rebuild([odd]);
      expect(photoBack, isNotNull);
      expect(photoBack!.metadata, isNull);
    });
  });

  group('the repair packet', () {
    test('recovers any single lost data packet', () {
      for (final length in <int>[300, 440]) {
        final set = photo(length);
        for (var lost = 0; lost < set.dataChunkCount; lost++) {
          final blobs = [...set.blobs]..removeAt(lost);
          final photoBack = rebuild(blobs);
          expect(photoBack, isNotNull, reason: 'len $length lost $lost');
          expect(photoBack!.data, payloadOf(length));
          expect(photoBack.recoveredWithParity, isTrue);
        }
      }
    });

    test('recovers the short final packet: its length is in the repair '
        'packet', () {
      final set = photo(kImageChunkFirstCapacity + 40);
      final photoBack = rebuild([set.blobs[0], set.blobs[2]]);
      expect(photoBack!.data, payloadOf(kImageChunkFirstCapacity + 40));
    });

    test('a photo of one packet comes back from the repair packet alone', () {
      final set = photo(60);
      expect(rebuild([set.blobs[1]])!.data, payloadOf(60));
    });

    test('losing two packets fails and never yields a wrong photo', () {
      final set = photo(440);
      expect(rebuild([set.blobs[0], set.blobs[3]]), isNull);
    });

    test('an empty payload rebuilds, and from the repair packet alone', () {
      final set = photo(0);
      expect(set.dataChunkCount, 1);
      expect(rebuild([set.blobs[0]])!.data, isEmpty);
      expect(rebuild([set.blobs[1]])!.data, isEmpty);
    });

    test('the largest payload rebuilds, and recovers a single loss', () {
      final set = photo(kImageMaxPayloadBytes);
      expect(set.dataChunkCount, kImageMaxDataChunks);
      final blobs = [...set.blobs]..removeAt(7);
      expect(rebuild(blobs)!.data, payloadOf(kImageMaxPayloadBytes));
    });

    test('a corrupt length byte fails instead of a truncated photo', () {
      final set = photo(440);
      final parity = Uint8List.fromList(set.blobs[3]);
      parity[kImageChunkHeaderBytes] ^= 0x02;
      expect(rebuild([set.blobs[0], set.blobs[2], parity]), isNull);
    });
  });

  group('a late copy of a photo already rebuilt', () {
    test('repeats one of its packets, even the repair packet it never had',
        () {
      final set = photo(450);
      final (packets, _) = collect(set.blobs.sublist(0, 3));
      expect(packets.rebuild(), isNotNull);
      Uint8List body(Uint8List blob) =>
          Uint8List.sublistView(blob, kImageChunkHeaderBytes);
      for (final blob in set.blobs) {
        expect(packets.repeats(parseImageChunkHeader(blob)!, body(blob)),
            isTrue);
      }
      final again = photoPacketAgain(set.blobs[1], 1);
      expect(packets.repeats(parseImageChunkHeader(again)!, body(again)),
          isTrue);
      final other = photo(450, imgId: 11).blobs[1];
      final changed = Uint8List.fromList(other)..[20] ^= 0xFF;
      expect(packets.repeats(parseImageChunkHeader(changed)!, body(changed)),
          isFalse);
    });
  });

  group('rate point wire codes', () {
    test('ft8 goes on the wire as code 2; the other codes are refused', () {
      expect(imageRateWireCode(ImageCodecRatePoint.ft8), kImageRateWireFt8);
      expect(kImageRateWireFt8, 2);
      for (final code in [0, 1, 3]) {
        expect(imageRatePointFromWireCode(code), isNull);
      }
    });

    test('every wire code round-trips and unknown codes are null', () {
      for (final rate in ImageCodecRatePoint.values) {
        expect(imageRatePointFromWireCode(imageRateWireCode(rate)), rate);
      }
      expect(imageRatePointFromWireCode(7), isNull);
    });
  });

  group('ids', () {
    test('wrap around 255 to 0', () {
      final ids = ImageIdAllocator(seed: 255);
      expect(ids.next(), 255);
      expect(ids.next(), 0);
    });
  });

  group('asking for lost packets', () {
    test('the packets a photo lacks are one bit each', () {
      final blobs = photo(600, parity: false).blobs;
      expect(blobs, hasLength(4));
      final (packets, _) = collect([blobs[0], blobs[2]]);
      expect(missingPacketBits(packets), 0x0A);
    });

    test('a request names the photo, its data packets and the ones lacked',
        () {
      final body = photoPacketsRequest(imgId: 0x3a, total: 4, missing: 0x06);
      expect(body, [0x3a, 4, 0x06, 0x00]);
      expect(readPhotoPacketsRequest(body), (
        imgId: 0x3a,
        total: 4,
        missing: 0x06,
      ));
    });

    test('bytes past the 4 it knows are left for later kinds of the body',
        () {
      final body = Uint8List.fromList([0x3a, 4, 0x06, 0x00, 0xEE, 0xFF]);
      expect(readPhotoPacketsRequest(body)?.missing, 0x06);
    });

    test('a short body or an impossible count is no request', () {
      expect(readPhotoPacketsRequest(Uint8List.fromList([0x3a, 4, 0])), null);
      expect(
        readPhotoPacketsRequest(Uint8List.fromList([0x3a, 0, 0, 1])),
        null,
      );
      expect(
        readPhotoPacketsRequest(Uint8List.fromList([0x3a, 16, 0, 1])),
        null,
      );
    });

    test('bits past the repair packet are dropped', () {
      final body = Uint8List.fromList([0x3a, 4, 0xFF, 0xFF]);
      expect(readPhotoPacketsRequest(body)?.missing, 0x1F);
    });
  });
}
