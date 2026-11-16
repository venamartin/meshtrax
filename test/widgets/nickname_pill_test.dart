import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/widgets/nickname_pill.dart';

// A pill beside a handle looked odd at any length (owner, 2026-11-16): it
// holds what a nickname may, and a longer full name is cut short.
void main() {
  test('a nickname fits whole', () {
    expect(NicknamePill.fit('Annie'), 'Annie');
    expect(NicknamePill.fit('Twelve chars'), 'Twelve chars');
  });

  test('a longer name keeps eleven characters and an ellipsis', () {
    expect(NicknamePill.fit('Christopher Alexander'), 'Christopher…');
  });

  test('an emoji counts as one character, never cut in two', () {
    expect(NicknamePill.fit('🇺🇸🇺🇸🇺🇸🇺🇸🇺🇸🇺🇸🇺🇸'), '🇺🇸🇺🇸🇺🇸🇺🇸🇺🇸🇺🇸🇺🇸');
    expect(
      NicknamePill.fit('👨‍👩‍👧 family of radios'),
      '👨‍👩‍👧 family of…',
    );
  });
}
