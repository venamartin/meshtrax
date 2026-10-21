import 'package:flutter_test/flutter_test.dart';
import 'package:linkify/linkify.dart';
import 'package:meshtrax/helpers/linkifiers.dart';
import 'package:meshtrax/helpers/markdown_helper.dart';
import 'package:meshtrax/models/app_settings.dart';

void main() {
  List<MdRun> parse(String text) => MarkdownHelper.parse(text);
  String shown(List<MdRun> runs) => runs.map((r) => r.text).join();
  MdRun run(List<MdRun> runs, String text) =>
      runs.firstWhere((r) => r.text == text);

  group('inline markers', () {
    test('bold, italic both ways, underline, strike', () {
      final runs = parse('**b** *i* _j_ __u__ ~~s~~');
      expect(shown(runs), 'b i j u s');
      expect(run(runs, 'b').bold, isTrue);
      expect(run(runs, 'i').italic, isTrue);
      expect(run(runs, 'j').italic, isTrue);
      expect(run(runs, 'u').underline, isTrue);
      expect(run(runs, 'u').italic, isFalse);
      expect(run(runs, 's').strike, isTrue);
    });

    test('triple stars are bold italic', () {
      final x = run(parse('***x***'), 'x');
      expect(x.bold && x.italic, isTrue);
    });

    test('markers nest', () {
      final runs = parse('**a *b* c**');
      expect(shown(runs), 'a b c');
      expect(run(runs, 'a ').bold, isTrue);
      expect(run(runs, 'b').bold && run(runs, 'b').italic, isTrue);
      expect(run(runs, ' c').bold, isTrue);
    });

    test('italic closing inside bold shares the stars', () {
      final runs = parse('**bold *italic***');
      expect(shown(runs), 'bold italic');
      expect(run(runs, 'italic').bold && run(runs, 'italic').italic, isTrue);
    });

    test('underline around bold', () {
      final x = run(parse('__**x**__'), 'x');
      expect(x.underline && x.bold, isTrue);
    });

    test('emphasis does not cross a line break', () {
      expect(shown(parse('**a\nb**')), '**a\nb**');
    });
  });

  group('text that must stay as typed', () {
    test('code is never formatted inside', () {
      final runs = parse('`**x**`');
      expect(runs.single.text, '**x**');
      expect(runs.single.code, isTrue);
      expect(runs.single.bold, isFalse);
    });

    test('code block drops a known language tag only', () {
      expect(parse('```dart\nvoid main() {}\n```').single.text, 'void main() {}');
      expect(parse('```hello\nworld```').single.text, 'hello\nworld');
    });

    test('backslash escapes a marker', () {
      final runs = parse(r'\*not italic\*');
      expect(shown(runs), '*not italic*');
      expect(runs.any((r) => r.italic), isFalse);
    });

    test('underscores inside words stay literal', () {
      for (final text in ['snake_case_name', 'g:abc_def_ghi']) {
        final runs = parse(text);
        expect(shown(runs), text);
        expect(runs.any((r) => r.italic), isFalse);
      }
    });

    test('single tildes stay literal', () {
      for (final text in ['a ~not struck~ b', 'battery lasts ~9 days, range ~2 km']) {
        final runs = parse(text);
        expect(shown(runs), text);
        expect(runs.any((r) => r.strike), isFalse);
      }
    });

    test('spaced-out stars are arithmetic, not italic', () {
      expect(parse('5 * 3 * 2').any((r) => r.italic), isFalse);
    });

    test('a mention keeps markdown characters in the name', () {
      final m = run(parse('@[*Star_Man*] hi'), '@[*Star_Man*]');
      expect(m.link, isA<MentionElement>());
      expect(m.italic, isFalse);
    });

    test('a mention inside bold is bold', () {
      final m = run(parse('**@[Bob] look**'), '@[Bob]');
      expect(m.link, isA<MentionElement>());
      expect(m.bold, isTrue);
    });

    test('underscores in a URL stay part of it', () {
      final runs = parse('see https://example.com/a_b_c now');
      expect(run(runs, 'https://example.com/a_b_c').link, isA<UrlElement>());
      expect(runs.any((r) => r.italic), isFalse);
    });

    test('coordinates are still tappable', () {
      expect(
        parse('meet at 47.070123, 15.440123').any((r) => r.link is CoordinateElement),
        isTrue,
      );
    });

    test('an object-replacement character in the text is dropped', () {
      expect(shown(parse('a￼b **c**')), 'ab c');
    });
  });

  group('headers', () {
    test('#, ##, ### and -# need a space', () {
      expect(run(parse('# Title'), 'Title').header, 1);
      expect(run(parse('## Title'), 'Title').header, 2);
      expect(run(parse('### Title'), 'Title').header, 3);
      expect(run(parse('-# small'), 'small').header, 4);
    });

    test('#mesh stays a hashtag and #### is not a header', () {
      expect(run(parse('#mesh rocks'), '#mesh').link, isA<HashtagElement>());
      expect(parse('#### x').every((r) => r.header == 0), isTrue);
      expect(shown(parse('#### x')), '#### x');
    });

    test('only the header line is sized', () {
      final runs = parse('line\n# Big');
      expect(run(runs, 'line').header, 0);
      expect(run(runs, 'Big').header, 1);
    });
  });

  group('links', () {
    test('[text](url) shows the text and opens the url', () {
      final site = run(parse('go [site](https://example.com) now'), 'site');
      expect(site.link, isA<MaskedLinkElement>());
      expect(site.link!.url, 'https://example.com');
    });

    test('link text that looks like an address stays literal', () {
      final runs = parse('[example.com](https://evil.test)');
      expect(runs.any((r) => r.link is MaskedLinkElement), isFalse);
      expect(shown(runs), startsWith('[example.com]('));
      expect(
        runs.any((r) => r.link is UrlElement && r.link!.url.startsWith('https://evil.test')),
        isTrue,
      );
    });

    test('only http and https links are masked', () {
      final runs = parse('[x](javascript:alert(1))');
      expect(runs.any((r) => r.link is MaskedLinkElement), isFalse);
      expect(shown(runs), '[x](javascript:alert(1))');
    });
  });

  group('spoilers', () {
    test('each spoiler gets its own group', () {
      final runs = parse('||a|| and ||b||');
      expect(run(runs, 'a').spoiler, isNotNull);
      expect(run(runs, 'b').spoiler, isNotNull);
      expect(run(runs, 'a').spoiler, isNot(run(runs, 'b').spoiler));
      expect(run(runs, ' and ').spoiler, isNull);
    });

    test('formatting inside a spoiler shares its group', () {
      final runs = parse('||a **b**||');
      expect(run(runs, 'a ').spoiler, run(runs, 'b').spoiler);
      expect(run(runs, 'b').bold, isTrue);
    });

    test('spaces inside the bars are allowed', () {
      expect(run(parse('|| hidden ||'), ' hidden ').spoiler, isNotNull);
    });
  });

  group('toPlainText', () {
    test('strips markers and masks spoilers', () {
      expect(MarkdownHelper.toPlainText('the answer is ||42||'), 'the answer is ▮▮▮');
      expect(MarkdownHelper.toPlainText('**b** [site](https://x.org)'), 'b site');
      expect(MarkdownHelper.toPlainText('# Title'), 'Title');
    });

    test('formatting off returns the raw text', () {
      expect(
        MarkdownHelper.toPlainText('||42||', formatting: false),
        '||42||',
      );
    });
  });

  test('formatting off keeps markers but still finds links', () {
    final runs = MarkdownHelper.parse('**b** https://x.org', formatting: false);
    expect(shown(runs), '**b** https://x.org');
    expect(runs.any((r) => r.bold), isFalse);
    expect(runs.any((r) => r.link is UrlElement), isTrue);
  });

  test('runs of unmatched markers parse quickly', () {
    final watch = Stopwatch()..start();
    for (final text in ['*' * 300, '*a' * 150, '_' * 300, '**a*' * 75, '|' * 300]) {
      MarkdownHelper.parse(text);
    }
    expect(watch.elapsed, lessThan(const Duration(seconds: 2)));
  });

  group('showTextFormatting setting', () {
    test('defaults to on', () {
      expect(AppSettings().showTextFormatting, isTrue);
      expect(AppSettings.fromJson(const {}).showTextFormatting, isTrue);
    });

    test('round-trips through json and copyWith', () {
      final off = AppSettings().copyWith(showTextFormatting: false);
      expect(AppSettings.fromJson(off.toJson()).showTextFormatting, isFalse);
    });
  });
}
