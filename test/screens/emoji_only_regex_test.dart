// This file exists to exercise the very pattern the lint misreads.
// ignore_for_file: valid_regexps

import 'package:flutter_test/flutter_test.dart';

// The `valid_regexps` lint reports this pattern as invalid, and CI runs
// `flutter analyze --fatal-infos`, so the false positive fails every build.
// Both chat screens suppress it with `// ignore: valid_regexps`; this test is
// the evidence for that suppression.
//
// Dart's regex engine accepts Unicode property escapes when `unicode: true`,
// and an invalid pattern throws FormatException on CONSTRUCTION — so simply
// building it here would fail loudly if the analyzer were right. The matching
// assertions then confirm it behaves as the screens expect.
//
// Keep this pattern identical to the one in channel_chat_screen.dart and
// chat_screen.dart. If it changes there, change it here.
void main() {
  group('emoji-only detection pattern', () {
    late RegExp emojiRegex;
    late RegExp hasLetter;

    setUp(() {
      emojiRegex = RegExp(
        r'^[\p{Emoji}‍️︎⃣\s]+$',
        unicode: true,
      );
      hasLetter = RegExp(r'[\p{L}a-zA-Z0-9]', unicode: true);
    });

    test('constructs without throwing — the lint is a false positive', () {
      expect(
        () => RegExp(
          r'^[\p{Emoji}‍️︎⃣\s]+$',
          unicode: true,
        ),
        returnsNormally,
      );
    });

    test('matches emoji-only text', () {
      for (final text in ['👍', '🎉🎉', '👍 ❤️', '🚀']) {
        expect(emojiRegex.hasMatch(text), isTrue, reason: 'should match $text');
      }
    });

    test('a zero-width-joiner sequence stays one match', () {
      expect(emojiRegex.hasMatch('👨‍👩‍👧'), isTrue);
    });

    test('text with letters is rejected by the letter guard', () {
      for (final text in ['hi', 'ok 👍', '123']) {
        expect(
          hasLetter.hasMatch(text),
          isTrue,
          reason: 'should detect a letter or digit in "$text"',
        );
      }
      expect(hasLetter.hasMatch('👍🎉'), isFalse);
    });
  });
}
