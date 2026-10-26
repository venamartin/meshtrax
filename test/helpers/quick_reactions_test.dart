import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/helpers/quick_reactions.dart';

void main() {
  test('with nothing sent yet, the twelve defaults', () {
    expect(QuickReactions.of(const []), QuickReactions.defaults);
    expect(QuickReactions.defaults, hasLength(12));
  });

  test('recent reactions come first, defaults fill the rest once each', () {
    final quick = QuickReactions.of(const ['🦊', '🔥']);
    expect(quick.take(2), ['🦊', '🔥']);
    expect(quick, hasLength(12));
    expect(quick.where((e) => e == '🔥'), hasLength(1));
  });

  test('remembering moves an emoji to the front and keeps twelve', () {
    var recent = <String>[];
    for (final e in ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm']) {
      recent = QuickReactions.remember(recent, e);
    }
    expect(recent, hasLength(12));
    expect(recent.first, 'm');
    expect(recent, isNot(contains('a')));
    recent = QuickReactions.remember(recent, 'f');
    expect(recent.first, 'f');
    expect(recent.where((e) => e == 'f'), hasLength(1));
  });
}
