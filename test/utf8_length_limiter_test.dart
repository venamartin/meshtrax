import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/helpers/utf8_length_limiter.dart';

void main() {
  const limiter = Utf8LengthLimitingTextInputFormatter(10);

  TextEditingValue value(
    String text, {
    int? cursor,
    TextRange composing = TextRange.empty,
  }) {
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: cursor ?? text.length),
      composing: composing,
    );
  }

  group('Utf8LengthLimitingTextInputFormatter', () {
    test('passes text under the limit through untouched', () {
      final v = value('hello', composing: const TextRange(start: 0, end: 5));
      expect(limiter.formatEditUpdate(value('hell'), v), same(v));
    });

    test('truncates over-limit text', () {
      final out = limiter.formatEditUpdate(
        value('0123456789'),
        value('0123456789AB'),
      );
      expect(out.text, '0123456789');
    });

    test('does NOT truncate while the IME is composing', () {
      // Rewriting the text under an active composing region desyncs Android
      // IMEs — the visible bug: the word being typed flashes highlighted and
      // the cursor jumps. The limit is enforced when composition ends; send
      // paths re-check the byte budget themselves.
      final composing = value(
        '0123456789ABC',
        composing: const TextRange(start: 10, end: 13),
      );
      expect(
        limiter.formatEditUpdate(value('0123456789'), composing),
        same(composing),
      );
    });

    test('truncates once composition ends', () {
      final out = limiter.formatEditUpdate(
        value('0123456789ABC', composing: const TextRange(start: 10, end: 13)),
        value('0123456789ABC'),
      );
      expect(out.text, '0123456789');
      expect(out.composing, TextRange.empty);
    });

    test('keeps the cursor at the edit point when truncating', () {
      // Editing the MIDDLE of an at-limit draft must not teleport the
      // cursor to the end of the field.
      final out = limiter.formatEditUpdate(
        value('0123456789', cursor: 5),
        value('0123X456789', cursor: 5),
      );
      expect(out.text, '0123X45678');
      expect(out.selection, const TextSelection.collapsed(offset: 5));
    });

    test('counts UTF-8 bytes, not characters', () {
      final out = limiter.formatEditUpdate(
        value(''),
        value('👍👍👍'), // 4 bytes each
      );
      expect(out.text, '👍👍');
    });
  });
}
