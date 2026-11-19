import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/helpers/hashtag_case_formatter.dart';

// A hashtag channel's key comes from its name as written, so the box shows
// the name in lowercase as it is typed, and keeps what was typed so "Keep
// capitals" can put the capitals back (owner, 2026-11-18).
void main() {
  /// Types [text] at the cursor one character at a time, as a keyboard does.
  TextEditingValue type(
    HashtagCaseFormatter f,
    TextEditingValue value,
    String text,
  ) {
    for (final c in text.split('')) {
      final at = value.selection.isValid
          ? value.selection.end
          : value.text.length;
      value = f.formatEditUpdate(
        value,
        TextEditingValue(
          text: value.text.substring(0, at) + c + value.text.substring(at),
          selection: TextSelection.collapsed(offset: at + 1),
        ),
      );
    }
    return value;
  }

  TextEditingValue backspace(HashtagCaseFormatter f, TextEditingValue value) {
    final at = value.selection.end;
    return f.formatEditUpdate(
      value,
      TextEditingValue(
        text: value.text.substring(0, at - 1) + value.text.substring(at),
        selection: TextSelection.collapsed(offset: at - 1),
      ),
    );
  }

  TextEditingValue cursorAt(TextEditingValue value, int offset) =>
      value.copyWith(selection: TextSelection.collapsed(offset: offset));

  test('shows lowercase and remembers the capitals typed', () {
    var calls = 0;
    final f = HashtagCaseFormatter()..onCapital = () => calls++;
    final shown = type(f, TextEditingValue.empty, '#BayArea');
    expect(shown.text, '#bayarea');
    expect(f.typed, '#BayArea');
    expect(f.sawCapital, isTrue);
    expect(calls, 1, reason: 'once, at the first capital');
  });

  test('no capital typed: no switch to show', () {
    final f = HashtagCaseFormatter();
    expect(type(f, TextEditingValue.empty, '#bayarea').text, '#bayarea');
    expect(f.sawCapital, isFalse);
  });

  test('with Keep capitals on, the text stays as typed', () {
    final f = HashtagCaseFormatter()..keepCapitals = true;
    expect(type(f, TextEditingValue.empty, '#BayArea').text, '#BayArea');
    expect(f.typed, '#BayArea');
  });

  test('an edit between repeated letters keeps each capital in place', () {
    final f = HashtagCaseFormatter();
    var shown = type(f, TextEditingValue.empty, '#aA');
    expect(shown.text, '#aa');
    shown = type(f, cursorAt(shown, 2), 'a');
    expect(shown.text, '#aaa');
    expect(f.typed, '#aaA');
    shown = backspace(f, cursorAt(shown, 2));
    expect(shown.text, '#aa');
    expect(f.typed, '#aA');
  });

  test('a paste over the whole text', () {
    final f = HashtagCaseFormatter();
    final shown = type(f, TextEditingValue.empty, '#old');
    final pasted = f.formatEditUpdate(
      shown.copyWith(
        selection: const TextSelection(baseOffset: 0, extentOffset: 4),
      ),
      const TextEditingValue(
        text: '#MeshTrax',
        selection: TextSelection.collapsed(offset: 9),
      ),
    );
    expect(pasted.text, '#meshtrax');
    expect(f.typed, '#MeshTrax');
  });

  test('a word the keyboard is still composing is lowercased once done', () {
    final f = HashtagCaseFormatter();
    final composing = f.formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(
        text: 'Bay',
        selection: TextSelection.collapsed(offset: 3),
        composing: TextRange(start: 0, end: 3),
      ),
    );
    expect(composing.text, 'Bay');
    expect(f.sawCapital, isTrue, reason: 'the switch shows straight away');
    final done = f.formatEditUpdate(
      composing,
      const TextEditingValue(
        text: 'Bay',
        selection: TextSelection.collapsed(offset: 3),
      ),
    );
    expect(done.text, 'bay');
    expect(f.typed, 'Bay');
  });

  test('other alphabets are lowercased too', () {
    final f = HashtagCaseFormatter();
    expect(type(f, TextEditingValue.empty, '#Москва').text, '#москва');
    expect(f.typed, '#Москва');
  });
}
