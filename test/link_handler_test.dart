import 'package:flutter_test/flutter_test.dart';
import 'package:linkify/linkify.dart';
import 'package:meshtrax/helpers/link_handler.dart';

void main() {
  List<LinkifyElement> parse(String text) =>
      const StrikethroughLinkifier().parse(
        [TextElement(text)],
        const LinkifyOptions(),
      );

  group('StrikethroughLinkifier — GFM ~~text~~ only', () {
    test('double tildes strike through', () {
      final elements = parse('a ~~struck~~ b');
      expect(elements.whereType<StrikethroughElement>(), hasLength(1));
      expect(
        elements.whereType<StrikethroughElement>().single.innerText,
        'struck',
      );
    });

    test('single tildes stay literal', () {
      final elements = parse('a ~not struck~ b');
      expect(elements.whereType<StrikethroughElement>(), isEmpty);
      expect(elements.single.text, 'a ~not struck~ b');
    });

    test('a lone approximation tilde stays literal', () {
      final elements = parse('battery lasts ~9 days, range ~2 km');
      expect(elements.whereType<StrikethroughElement>(), isEmpty);
    });

    test('multiple runs each strike', () {
      final elements = parse('~~one~~ and ~~two~~');
      expect(
        elements.whereType<StrikethroughElement>().map((e) => e.innerText),
        ['one', 'two'],
      );
    });
  });
}
