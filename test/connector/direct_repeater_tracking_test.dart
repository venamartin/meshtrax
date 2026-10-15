import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';

Uint8List key(List<int> prefix, {int fill = 0x11}) {
  final bytes = Uint8List(pubKeySize)..fillRange(0, pubKeySize, fill);
  bytes.setRange(0, prefix.length, prefix);
  return bytes;
}

DirectRepeater entry({Uint8List? publicKey, required List<int> prefix}) {
  return DirectRepeater(
    pubkeyPrefix: Uint8List.fromList(prefix),
    publicKey: publicKey,
    snr: 5,
  );
}

void main() {
  final nearKey = key([0xA2, 0x77], fill: 0x0C);
  final farKey = key([0xA2, 0x77], fill: 0xF0);

  group('a node heard by its full key', () {
    test('matches only the entry holding that key', () {
      final far = entry(publicKey: farKey, prefix: [0xA2]);
      final near = entry(publicKey: nearKey, prefix: [0xA2]);

      expect(
        DirectRepeater.findTracked([far, near], fullKey: nearKey, hashPrefix: [0xA2]),
        same(near),
      );
    });

    test('does not adopt an entry already claimed by another key', () {
      // Both share the hash. Refreshing the far one would put the near
      // repeater's SNR on the far repeater's row and hide the real neighbour.
      final far = entry(publicKey: farKey, prefix: [0xA2]);

      expect(
        DirectRepeater.findTracked([far], fullKey: nearKey, hashPrefix: [0xA2]),
        isNull,
      );
    });

    test('adopts a single entry we had only heard by hash', () {
      final unidentified = entry(prefix: [0xA2]);

      expect(
        DirectRepeater.findTracked(
          [unidentified],
          fullKey: nearKey,
          hashPrefix: [0xA2],
        ),
        same(unidentified),
      );
    });

    test('adopts neither when two hash-only entries share the hash', () {
      expect(
        DirectRepeater.findTracked(
          [entry(prefix: [0xA2]), entry(prefix: [0xA2])],
          fullKey: nearKey,
          hashPrefix: [0xA2],
        ),
        isNull,
      );
    });
  });

  group('a node heard by hash alone', () {
    test('refreshes the one entry that answers to it, keyed or not', () {
      final keyed = entry(publicKey: farKey, prefix: [0xA2, 0x77]);
      final other = entry(publicKey: key([0x5B]), prefix: [0x5B, 0x01]);

      expect(
        DirectRepeater.findTracked([keyed, other], hashPrefix: [0xA2, 0x77]),
        same(keyed),
      );
    });

    test('a 1-byte hash never refreshes a keyed entry', () {
      // One byte names a quarter of the band: the level would be another
      // repeater's, shown next to this one's own Discover answer.
      final keyed = entry(publicKey: farKey, prefix: [0xA2, 0x77]);
      expect(DirectRepeater.findTracked([keyed], hashPrefix: [0xA2]), isNull);
      final hashOnly = entry(prefix: [0xA2]);
      expect(DirectRepeater.findTracked([keyed, hashOnly], hashPrefix: [0xA2]),
          same(hashOnly));
    });

    test('refreshes nothing when the hash is shared', () {
      expect(
        DirectRepeater.findTracked(
          [
            entry(publicKey: farKey, prefix: [0xA2, 0x77]),
            entry(prefix: [0xA2, 0x77]),
          ],
          hashPrefix: [0xA2, 0x77],
        ),
        isNull,
      );
    });

    test('starts a new entry when nothing answers', () {
      expect(
        DirectRepeater.findTracked(
          [entry(publicKey: farKey, prefix: [0xA2])],
          hashPrefix: [0x5B],
        ),
        isNull,
      );
    });
  });

  test('an empty list never matches', () {
    expect(
      DirectRepeater.findTracked([], fullKey: nearKey, hashPrefix: [0xA2]),
      isNull,
    );
  });

  test('matchesHash compares only the bytes both sides carry', () {
    final oneByte = entry(prefix: [0xA2]);
    expect(oneByte.matchesHash(nearKey), isTrue);
    expect(oneByte.matchesHash(key([0xA3])), isFalse);

    final twoByte = entry(prefix: [0xA2, 0x77]);
    expect(twoByte.matchesHash(nearKey), isTrue);
    expect(twoByte.matchesHash(key([0xA2, 0x78])), isFalse);
  });
}
