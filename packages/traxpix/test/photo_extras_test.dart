import 'dart:convert';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:traxpix/src/photo_chunks.dart';
import 'package:traxpix/src/photo_extras.dart';
import 'package:traxpix/src/rate_point.dart';

Uint8List bits(int length) =>
    Uint8List.fromList([for (var i = 0; i < length; i++) (i * 31 + 7) & 0xFF]);

Uint8List bytes(List<int> b) => Uint8List.fromList(b);

void main() {
  group('the photo byte', () {
    test('the extras bit round-trips with rate and resolution intact', () {
      for (final extras in [false, true]) {
        final m = ImageStreamMetadata(
          rate: ImageCodecRatePoint.ft8,
          hasExtras: extras,
        );
        final back = ImageStreamMetadata.decode(m.encode());
        expect(back, m);
        expect(back!.squareSize, 512);
      }
    });
  });

  group('the payload', () {
    test('no extras: the payload is the bitstream, not a byte more', () {
      final bitstream = bits(50);
      expect(photoPayload(bitstream, const PhotoExtras()), same(bitstream));
      expect(
        photoPayload(bitstream, const PhotoExtras(tag: '  ')),
        same(bitstream),
      );
      expect(const PhotoExtras(tag: ' ').isEmpty, isTrue);
      final parts = photoPayloadParts(bitstream, hasExtras: false)!;
      expect(parts.extras.tag, isNull);
      expect(parts.extras.position, isNull);
      expect(parts.bitstream, bitstream);
    });

    test('a tag is item 1: its number, its length, its text', () {
      final bitstream = bits(300);
      final payload = photoPayload(
        bitstream,
        const PhotoExtras(tag: ' Spring flowing '),
      );
      expect(payload.sublist(0, 2), [kPhotoItemTag, 'Spring flowing'.length]);
      expect(utf8.decode(payload.sublist(2, 16)), 'Spring flowing');
      final parts = photoPayloadParts(payload, hasExtras: true)!;
      expect(parts.extras.tag, 'Spring flowing');
      expect(parts.bitstream, bitstream);
      expect(parts.needsNewerApp, isFalse);
    });

    test('a tag and a position: the first item says another follows', () {
      final bitstream = bits(200);
      final position = PhotoPosition.at(57.64911, 10.40744, bytes: 5);
      final payload = photoPayload(
        bitstream,
        PhotoExtras(tag: 'Camp', position: position),
      );
      expect(payload.sublist(0, 6), [0x81, 4, ...utf8.encode('Camp')]);
      expect(payload.sublist(6, 8), [kPhotoItemPosition, 5]);
      expect(payload.length, bitstream.length + 2 + 4 + 2 + 5);
      final parts = photoPayloadParts(payload, hasExtras: true)!;
      expect(parts.extras.tag, 'Camp');
      expect(parts.extras.position!.encode(), position.encode());
      expect(parts.bitstream, bitstream);
    });

    test('Subject only is item 3 with no data: two bytes', () {
      final bitstream = bits(200);
      final payload = photoPayload(
        bitstream,
        const PhotoExtras(subjectOnly: true),
      );
      expect(payload.sublist(0, 2), [kPhotoItemSubjectOnly, 0]);
      expect(payload.length, bitstream.length + 2);
      final parts = photoPayloadParts(payload, hasExtras: true)!;
      expect(parts.extras.subjectOnly, isTrue);
      expect(parts.extras.tag, isNull);
      expect(parts.bitstream, bitstream);
      expect(const PhotoExtras(subjectOnly: true).isEmpty, isFalse);
      expect(
        photoPayloadParts(bitstream, hasExtras: false)!.extras.subjectOnly,
        isFalse,
      );
    });

    test('takes UTF-8 up to the byte limit, and refuses more', () {
      final camp = photoPayload(bits(10), const PhotoExtras(tag: '⛰️ Camp'));
      expect(photoPayloadParts(camp, hasExtras: true)!.extras.tag, '⛰️ Camp');
      expect(
        () => photoPayload(bits(10), PhotoExtras(tag: '🏕️' * 10)), // 70 bytes
        throwsArgumentError,
      );
    });

    test('skips an item it does not know and still finds the picture', () {
      final bitstream = bits(40);
      final payload = bytes([
        0x80 | 42, 3, 9, 9, 9, // a later release's item, another follows
        kPhotoItemTag, 4, ...utf8.encode('Camp'),
        ...bitstream,
      ]);
      final parts = photoPayloadParts(payload, hasExtras: true)!;
      expect(parts.extras.tag, 'Camp');
      expect(parts.bitstream, bitstream);
      expect(parts.needsNewerApp, isFalse);
    });

    test('an unknown item marked must-understand needs a newer app', () {
      final parts = photoPayloadParts(
        bytes([0x40 | 42, 0, ...bits(20)]),
        hasExtras: true,
      )!;
      expect(parts.needsNewerApp, isTrue);
    });

    test('must-understand on an item it knows is fine', () {
      final parts = photoPayloadParts(
        bytes([0x40 | kPhotoItemTag, 4, ...utf8.encode('Camp'), ...bits(20)]),
        hasExtras: true,
      )!;
      expect(parts.extras.tag, 'Camp');
      expect(parts.needsNewerApp, isFalse);
    });

    test('a position of a size it does not know is skipped', () {
      final bitstream = bits(30);
      final parts = photoPayloadParts(
        bytes([kPhotoItemPosition, 7, 1, 2, 3, 4, 5, 6, 7, ...bitstream]),
        hasExtras: true,
      )!;
      expect(parts.extras.position, isNull);
      expect(parts.bitstream, bitstream);
    });

    test('an item that runs past the end is a damaged photo', () {
      for (final damaged in [
        <int>[],
        [kPhotoItemTag],
        [kPhotoItemTag, 9, 1, 2],
        [0x80 | kPhotoItemTag, 0], // another follows, but nothing does
      ]) {
        expect(photoPayloadParts(bytes(damaged), hasExtras: true), isNull);
      }
    });

    test('a photo with extras arrives whole with them', () {
      final bitstream = bits(500);
      final set = buildImageChunks(
        payload: photoPayload(
          bitstream,
          PhotoExtras(
            tag: 'Road washed out',
            position: PhotoPosition.at(-33.8688, 151.2093, bytes: 6),
          ),
        ),
        metadata: const ImageStreamMetadata(
          rate: ImageCodecRatePoint.ft8,
          hasExtras: true,
        ),
        senderPrefix: 0x1234,
        imgId: 3,
      );
      final packets = ImagePackets(total: set.dataChunkCount);
      for (final b in set.blobs) {
        final header = parseImageChunkHeader(b)!;
        packets.add(header, Uint8List.sublistView(b, header.bodyOffset));
      }
      final got = packets.rebuild();
      expect(got!.metadata!.hasExtras, isTrue);
      final parts = photoPayloadParts(got.data, hasExtras: true)!;
      expect(parts.extras.tag, 'Road washed out');
      expect(parts.extras.position!.lat, closeTo(-33.8688, 1e-5));
      expect(parts.extras.position!.lon, closeTo(151.2093, 1e-5));
      expect(parts.bitstream, bitstream);
    });
  });

  group('PhotoPosition', () {
    // From an independent geohash implementation: 5 bytes are exactly the
    // bits of the 8-character geohash.
    final fiveBytes = {
      (57.64911, 10.40744): [0xd1, 0x2b, 0x7d, 0x79, 0x96], // u4pruydq
      (-33.8688, 151.2093): [0xb8, 0xdf, 0xd1, 0x38, 0xe7], // r3gx2f77
      (-12.0464, -77.0428): [0x34, 0xd6, 0x5b, 0x7c, 0xa0], // 6mc5qz50
      (61.2181, -149.9003): [0x53, 0x37, 0x29, 0x2a, 0x7b], // bdvkkbmv
    };

    test('packs the geohash bits', () {
      fiveBytes.forEach((p, want) {
        expect(PhotoPosition.at(p.$1, p.$2, bytes: 5).encode(), want);
      });
      expect(PhotoPosition.at(57.64911, 10.40744, bytes: 3).encode(), [
        0xd1,
        0x2b,
        0x7d,
      ]);
      expect(PhotoPosition.at(57.64911, 10.40744, bytes: 6).encode(), [
        0xd1,
        0x2b,
        0x7d,
        0x79,
        0x96,
        0xb6,
      ]);
    });

    test('comes back as the middle of its cell, within half a cell', () {
      for (final size in kPhotoPositionSizes) {
        fiveBytes.forEach((p, _) {
          final sent = PhotoPosition.at(p.$1, p.$2, bytes: size);
          final got = PhotoPosition.decode(sent.encode())!;
          expect(got.bytes, size);
          expect(got.encode(), sent.encode());
          expect((got.lat - p.$1).abs(), lessThanOrEqualTo(got.latSpan / 2));
          expect((got.lon - p.$2).abs(), lessThanOrEqualTo(got.lonSpan / 2));
        });
      }
    });

    test('each byte halves the cell four more times', () {
      final spans = [
        for (final size in kPhotoPositionSizes)
          PhotoPosition.at(0, 0, bytes: size).latSpan,
      ];
      for (var i = 1; i < spans.length; i++) {
        expect(spans[i - 1] / spans[i], 16);
      }
      // 3 bytes: about 10 x 5 km at the equator (1 degree is about 111 km).
      final coarse = PhotoPosition.at(0, 0, bytes: 3);
      expect(coarse.lonSpan * 111, closeTo(9.8, 0.1));
      expect(coarse.latSpan * 111, closeTo(4.9, 0.1));
    });

    test('the poles and the date line stay on the globe', () {
      for (final (lat, lon) in [(90.0, 180.0), (-90.0, -180.0)]) {
        final p = PhotoPosition.at(lat, lon, bytes: 4);
        expect(p.lat.abs(), lessThan(90));
        expect(p.lon.abs(), lessThan(180));
      }
    });

    test('refuses a size it does not offer, or a point off the globe', () {
      expect(() => PhotoPosition.at(0, 0, bytes: 2), throwsArgumentError);
      expect(() => PhotoPosition.at(0, 0, bytes: 7), throwsArgumentError);
      expect(() => PhotoPosition.at(91, 0, bytes: 5), throwsArgumentError);
      expect(
        () => PhotoPosition.at(0, double.nan, bytes: 5),
        throwsArgumentError,
      );
      expect(PhotoPosition.decode([1, 2]), isNull);
    });
  });
}
