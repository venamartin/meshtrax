import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';

void main() {
  group('isChannelEchoObservable', () {
    // Pinned to the 2026-09-22 on-air sweep (sender "GWQ∆🚀", 10-byte
    // name, 2-byte path hashes): 140-char sends echoed (repeated raw
    // 171), 144-char sends never did (repeated raw 187).
    const name = 'GWQ∆🚀';

    String text(int len) => 'a' * len;

    test('sweep pin: 140 chars observable, 144 not (2-byte path hashes)',
        () {
      expect(isChannelEchoObservable(name, text(140), 2), isTrue);
      expect(isChannelEchoObservable(name, text(144), 2), isFalse);
    });

    test('boundary sits on the AES block edge (plaintext 160 vs 161)', () {
      // 5 + 12-byte prefix + 143 = 160 → last 10-block payload (163 B).
      expect(isChannelEchoObservable(name, text(143), 2), isTrue);
      expect(isChannelEchoObservable(name, text(144), 2), isFalse);
    });

    test('short messages are always observable', () {
      expect(isChannelEchoObservable(name, 'H', 2), isTrue);
      expect(isChannelEchoObservable(name, text(60), 1), isTrue);
    });

    test('1-byte path hashes share the block-quantized threshold', () {
      expect(isChannelEchoObservable(name, text(143), 1), isTrue);
      expect(isChannelEchoObservable(name, text(144), 1), isFalse);
    });

    test('unknown sender name assumes the worst-case prefix', () {
      // Null name uses the 31-byte cap + 2 → threshold drops accordingly:
      // 5 + 33 + 122 = 160 observable, 123 tips the block.
      expect(isChannelEchoObservable(null, text(122), 2), isTrue);
      expect(isChannelEchoObservable(null, text(123), 2), isFalse);
    });
  });
}
