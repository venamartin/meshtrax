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

    test('the row heard by that code before, never the keyed one beside it',
        () {
      final keyed = entry(publicKey: farKey, prefix: [0xA2, 0x77]);
      final heard = entry(prefix: [0xA2, 0x77]);
      expect(
        DirectRepeater.findTracked([keyed, heard], hashPrefix: [0xA2, 0x77]),
        same(heard),
      );
    });

    test('refreshes neither of two keyed rows sharing the code', () {
      expect(
        DirectRepeater.findTracked(
          [
            entry(publicKey: farKey, prefix: [0xA2, 0x77]),
            entry(publicKey: nearKey, prefix: [0xA2, 0x77]),
          ],
          hashPrefix: [0xA2, 0x77],
        ),
        isNull,
      );
    });

    // Field case 2026-10-26: one repeater, heard as A3 and as A377 (paths of
    // either width), filled the list with copies of both.
    test('a short and a long code each refresh their own row', () {
      final short = entry(prefix: [0xA3]);
      final long = entry(prefix: [0xA3, 0x77]);
      expect(DirectRepeater.findTracked([short, long], hashPrefix: [0xA3]),
          same(short));
      expect(
          DirectRepeater.findTracked([short, long], hashPrefix: [0xA3, 0x77]),
          same(long));
      expect(DirectRepeater.findTracked([long], hashPrefix: [0xA3]), isNull,
          reason: 'a code of another width starts its own row');
    });

    test('a key adopts the row heard by its code, not a shorter one', () {
      final short = entry(prefix: [0xA2]);
      final long = entry(prefix: [0xA2, 0x77]);
      expect(
        DirectRepeater.findTracked(
          [short, long],
          fullKey: nearKey,
          hashPrefix: [0xA2, 0x77],
        ),
        same(long),
      );
    });

    // A repeater's own zero-hop advert comes with path_len 0, so a 1-byte
    // code, even on a 2-byte mesh; a Discover answer comes at the radio's
    // width. Either way its key still names the row heard on longer paths.
    test('a key heard at one byte adopts the longer row it starts with', () {
      final short = entry(prefix: [0xA2]);
      final long = entry(prefix: [0xA2, 0x77]);
      expect(
        DirectRepeater.findTracked([long], fullKey: nearKey, hashPrefix: [0xA2]),
        same(long),
      );
      expect(
        DirectRepeater.findTracked(
          [short, long],
          fullKey: nearKey,
          hashPrefix: [0xA2],
        ),
        same(long),
        reason: 'the most specific code; A2 alone could be anyone',
      );
      expect(
        DirectRepeater.findTracked(
          [entry(prefix: [0xA2, 0x78])],
          fullKey: nearKey,
          hashPrefix: [0xA2],
        ),
        isNull,
        reason: 'a code the key does not start with',
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

  test('a code is the same bytes at the same width; a key only starts with it',
      () {
    final oneByte = entry(prefix: [0xA2]);
    expect(oneByte.hasCode([0xA2]), isTrue);
    expect(oneByte.hasCode([0xA2, 0x77]), isFalse);
    expect(oneByte.hasCode([0xA3]), isFalse);

    final keyed = entry(publicKey: nearKey, prefix: [0xA2]);
    expect(keyed.keyStartsWith([0xA2, 0x77]), isTrue);
    expect(keyed.keyStartsWith([0xA2, 0x78]), isFalse);
    expect(oneByte.keyStartsWith([0xA2]), isFalse, reason: 'no key');
  });
}
