import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/utils/emoji_utils.dart';

// The `valid_regexps` lint reports the emoji-only pattern in emoji_utils.dart
// as invalid, and CI runs `flutter analyze --fatal-infos`, so the false
// positive would fail every build; the file suppresses it with
// `// ignore: valid_regexps`. This test is the evidence for that
// suppression: Dart builds a lazy top-level RegExp on first use, and an
// invalid pattern throws FormatException right there.
void main() {
  group('isEmojiOnly', () {
    test('builds its pattern without throwing (the lint is wrong)', () {
      expect(() => isEmojiOnly('👍'), returnsNormally);
    });

    test('emoji-only text, spaces allowed', () {
      for (final text in ['👍', '🎉🎉', '👍 ❤️', '🚀', ' 😀 ']) {
        expect(isEmojiOnly(text), isTrue, reason: text);
      }
    });

    test('a zero-width-joiner family is one emoji', () {
      expect(isEmojiOnly('👨‍👩‍👧'), isTrue);
    });

    test('up to five are large; six are ordinary text', () {
      expect(isEmojiOnly('😀😀😀😀'), isTrue);
      expect(isEmojiOnly('😀 😀 😀 😀 😀'), isTrue);
      expect(isEmojiOnly('😀😀😀😀😀😀'), isFalse);
      expect(jumboEmojiMax, 5);
    });

    test('letters, digits, # and * make it text', () {
      for (final text in ['hi', 'ok 👍', '123', '', '*****', '####', '**']) {
        expect(isEmojiOnly(text), isFalse, reason: '"$text"');
      }
    });
  });
}
